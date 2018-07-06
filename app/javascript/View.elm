module View exposing (viewState)

import Data.Asset exposing (Asset)
import Data.Chassis as Chassis exposing (Chassis)
import Data.Group exposing (Group)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (AppLayout(..), State)
import Dict
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
            case
                ( State.selectedAssetData state
                , State.selectedAssetDescription state
                )
            of
                ( Just data, Just description ) ->
                    case JsonTree.parseValue data of
                        Ok jsonNode ->
                            dataJsonTreeElements
                                state.dataJsonTreeState
                                jsonNode
                                description

                        Err message ->
                            -- XXX Handle this better?
                            [ span []
                                [ text <| "Error: " ++ message ]
                            ]

                _ ->
                    [ div
                        [ class "no-selection" ]
                        [ text "Select an asset to inspect" ]
                    ]
    in
    div [ class "selected-asset-inspector" ]
        treeViewElements


dataJsonTreeElements : JsonTree.State -> JsonTree.Node -> String -> List (Html Msg)
dataJsonTreeElements treeState treeNode assetDescription =
    [ h3
        [ class "tree-title" ]
        [ text assetDescription ]
    , JsonTree.view treeNode jsonTreeConfig treeState
    ]


jsonTreeConfig : JsonTree.Config Msg
jsonTreeConfig =
    { onSelect = Nothing
    , toMsg = SetDataJsonTreeState
    }


clusterDiagram : State -> Html Msg
clusterDiagram state =
    let
        controls =
            div
                [ class "app-controls" ]
                (switchLayoutButtons state)

        diagram =
            case state.layout of
                Physical ->
                    rackView state

                LogicalInGroups ->
                    logicalGroupsLayout state

                LogicalInGenders ->
                    logicalGendersLayout state
    in
    div
        [ class "cluster-diagram" ]
        [ controls
        , diagram
        ]


switchLayoutButtons : State -> List (Html Msg)
switchLayoutButtons state =
    let
        allLayoutsAndText =
            [ ( Physical, "Physical layout" )
            , ( LogicalInGroups, "Logical layout in groups" )
            , ( LogicalInGenders, "Logical layout in genders" )
            ]

        layoutsAndTextWithoutCurrent =
            List.filter
                (\( layout, _ ) -> layout /= state.layout)
                allLayoutsAndText

        layoutButton =
            \( layout, text_ ) ->
                button
                    [ onClick <| SetAppLayout layout ]
                    [ text text_ ]
    in
    List.map layoutButton layoutsAndTextWithoutCurrent


logicalGroupsLayout : State -> Html Msg
logicalGroupsLayout state =
    let
        groups =
            TaggedDict.values state.groups
    in
    div []
        (List.map (groupView state) groups)


groupView : State -> Group -> Html Msg
groupView state group =
    let
        nodes =
            State.groupNodesByName state group
    in
    groupedElements group (List.map nodeView nodes)


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
                        (physicalNodeView state)
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


physicalNodeView : State -> Node -> Html Msg
physicalNodeView state node =
    let
        nodeGroup =
            TaggedDict.get node.groupId state.groups
    in
    case nodeGroup of
        Just group ->
            groupedElements group [ nodeView node ]

        Nothing ->
            -- XXX Handle this better!
            Debug.crash ("Node has no group: " ++ node.name)


nodeView : Node -> Html Msg
nodeView node =
    div
        [ class "node"
        , title "Node"

        -- Picked up by Flipping JS library for animations.
        , attribute "data-flip-key" node.name
        ]
        [ assetHitBox <| State.NodeId node.id
        , text node.name
        ]


groupedElements : Group -> List (Html Msg) -> Html Msg
groupedElements group children =
    let
        groupColour =
            Hashbow.hashbow group.name

        groupChildren =
            List.concat
                [ [ assetHitBox <| State.GroupId group.id
                  , strong
                        [ class "group-name"
                        , style [ ( "color", groupColour ) ]
                        ]
                        [ text group.name ]
                  ]
                , children
                ]
    in
    div
        [ class "group"
        , style [ ( "border-color", groupColour ) ]
        , title ("Group: " ++ group.name)
        ]
        groupChildren


logicalGendersLayout : State -> Html Msg
logicalGendersLayout state =
    let
        nodesByGender =
            TaggedDict.values state.nodes
                |> Node.nodesByGender
    in
    div []
        (Dict.map genderNodesView nodesByGender
            |> Dict.values
        )


genderNodesView : Node.GenderName -> List Node -> Html Msg
genderNodesView gender nodes =
    -- XXX DRY up with above.
    let
        genderColour =
            Hashbow.hashbow gender
    in
    div
        [ class "group"
        , style [ ( "border-color", genderColour ) ]
        , title ("Gender: " ++ gender)
        ]
        (strong
            [ class "group-name"
            , style [ ( "color", genderColour ) ]
            ]
            [ text gender ]
            :: List.map nodeView nodes
        )


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
