module View exposing (viewState)

import Data.Asset exposing (Asset)
import Data.Chassis as Chassis exposing (Chassis)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (State)
import Geometry.Networks
import Hashbow
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import JsonTree
import Msg exposing (Msg(..))
import Tagged
import Tagged.Dict as TaggedDict exposing (TaggedDict)
import View.SvgLayer as SvgLayer


viewState : State -> Html Msg
viewState state =
    div []
        [ SvgLayer.view state
        , htmlLayer state
        ]


htmlLayer : State -> Html Msg
htmlLayer state =
    div [ class "html-layer" ]
        [ selectedAssetInspector state
        , clusterDiagram state
        ]


selectedAssetInspector : State -> Html Msg
selectedAssetInspector state =
    let
        treeViewElements =
            case State.selectedAssetData state of
                Just data ->
                    [ case JsonTree.parseValue data of
                        Ok jsonNode ->
                            JsonTree.view jsonNode
                                jsonTreeConfig
                                state.dataJsonTreeState

                        Err message ->
                            -- XXX Handle this better?
                            span [] [ text <| "Error: " ++ message ]
                    ]

                Nothing ->
                    []
    in
    div [ class "selected-asset-inspector" ]
        treeViewElements


jsonTreeConfig : JsonTree.Config Msg
jsonTreeConfig =
    { onSelect = Nothing
    , toMsg = SetDataJsonTreeState
    }


clusterDiagram : State -> Html Msg
clusterDiagram state =
    div [ class "cluster-diagram" ] [ rackView state ]


rackView : State -> Html Msg
rackView state =
    let
        adapterHeight =
            -- Calculate the height we should display NetworkAdapters at here
            -- and thread this through, rather than at point of use, as the
            -- calculation for what this should be is somewhat time consuming
            -- and gives the same value for every adapter; this is fine if we
            -- do it once here but is wasteful and noticeably slows things down
            -- if we do it for every adapter.
            Geometry.Networks.adapterHeight state

        switchHeight =
            -- Do similar to `adapterHeight` here as well, although probably
            -- less important here since most likely far fewer switches.
            Geometry.Networks.switchHeight state
    in
    -- XXX Fake rack for now
    div [ class "rack" ]
        (List.concat
            [ [ assetTitle "Rack" ]
            , List.map
                (switchView switchHeight)
                (State.switchesByName state)
            , List.map
                (chassisView adapterHeight state)
                (State.chassisByName state)
            ]
        )


switchView : Int -> NetworkSwitch -> Html Msg
switchView switchHeight switch =
    div
        [ class "network-switch"
        , idAttribute "data-network-switch-id" switch
        , title ("Network switch: " ++ switch.name)
        , style [ ( "height", toString switchHeight ++ "px" ) ]
        ]
        [ assetHitBox <| State.NetworkSwitchId switch.id
        , assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
        ]


chassisView : Int -> State -> Chassis -> Html Msg
chassisView adapterHeight state chassis =
    div
        [ class "chassis"
        , title ("Chassis: " ++ chassis.name)
        ]
        (List.concat
            [ [ assetHitBox <| State.ChassisId chassis.id
              , assetTitle <| (PhysicalAsset.fullModel chassis ++ " chassis")
              ]
            , [ div
                    [ class "servers" ]
                    (List.map (serverView adapterHeight state)
                        (State.chassisServersByName state chassis)
                    )
              ]
            , [ div [ class "psus" ]
                    (List.map
                        psuView
                        (State.chassisPsusByName state chassis)
                    )
              ]
            ]
        )


serverView : Int -> State -> Server -> Html Msg
serverView adapterHeight state server =
    div
        [ class "server"
        , title <| "Server: " ++ server.name
        ]
        (List.concat
            [ [ assetHitBox <| State.ServerId server.id
              , assetTitle <| (PhysicalAsset.fullModel server ++ " server")
              ]
            , [ div [ class "network-adapters" ]
                    (List.map
                        (networkAdapterView adapterHeight)
                        (State.serverNetworkAdaptersByName state server)
                    )
              ]
            , [ div [ class "nodes" ]
                    (List.map
                        (nodeView state)
                        (State.serverNodesByName state server)
                    )
              ]
            ]
        )


networkAdapterView : Int -> NetworkAdapter -> Html Msg
networkAdapterView adapterHeight adapter =
    div
        [ class "network-adapter"
        , idAttribute "data-network-adapter-id" adapter
        , title <|
            String.join " "
                [ "Network adapter:", PhysicalAsset.fullModel adapter, adapter.name ]
        , style [ ( "height", toString adapterHeight ++ "px" ) ]
        ]
        [ assetHitBox <| State.NetworkAdapterId adapter.id
        , text "N"
        ]


nodeView : State -> Node -> Html Msg
nodeView state node =
    let
        nodeGroup =
            TaggedDict.get node.groupId state.groups
    in
    case nodeGroup of
        Just group ->
            let
                groupColour =
                    Hashbow.hashbow group.name
            in
            div
                [ class "group"
                , style [ ( "border-color", groupColour ) ]
                , title ("Group: " ++ group.name)
                ]
                [ strong
                    [ class "group-name"
                    , style [ ( "color", groupColour ) ]
                    ]
                    [ text group.name ]
                , div
                    [ class "node", title "Node" ]
                    [ assetHitBox <| State.NodeId node.id
                    , text node.name
                    ]
                ]

        Nothing ->
            -- XXX Handle this better!
            Debug.crash ("Node has no group: " ++ node.name)


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ assetHitBox <| State.PsuId psu.id
        , text (PhysicalAsset.fullModel psu ++ " PSU")
        ]


idAttribute : String -> Asset idTag a -> Html.Attribute msg
idAttribute dataAttr { id } =
    Tagged.untag id
        |> toString
        |> attribute dataAttr


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]


assetHitBox : State.SelectableAssetId -> Html Msg
assetHitBox assetId =
    -- Each selectable asset displayed in the Cluster diagram has a hit box, an
    -- absolutely positioned div exactly covering the asset element's area. The
    -- `onClick` handler and corresponding styling is added to this rather than
    -- the asset element itself, as this avoids both the propagated click event
    -- also triggering parent asset `onClick` handlers, and the styling also
    -- being applied to the child asset elements.
    div
        [ class "asset-hit-box"
        , onClick <| SelectAsset assetId
        ]
        []
