module View.Physical exposing (layout)

import Data.Asset exposing (Asset)
import Data.Chassis as Chassis exposing (Chassis)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (AppLayout(..), State)
import Geometry.Networks
import Html exposing (..)
import Html.Attributes exposing (..)
import Msg exposing (Msg(..))
import Tagged
import Tagged.Dict as TaggedDict exposing (TaggedDict)
import View.Logical
import View.Utils


layout : State -> Html Msg
layout =
    rackView


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
        [ View.Utils.assetHitBox <| State.NetworkSwitchId switch.id
        , assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
        ]


chassisView : Int -> State -> Chassis -> Html Msg
chassisView adapterHeight state chassis =
    div
        [ class "chassis"
        , title ("Chassis: " ++ chassis.name)
        ]
        (List.concat
            [ [ View.Utils.assetHitBox <| State.ChassisId chassis.id
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
            [ [ View.Utils.assetHitBox <| State.ServerId server.id
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
        [ View.Utils.assetHitBox <| State.NetworkAdapterId adapter.id
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
            View.Logical.groupedElements
                group
                [ View.Logical.nodeView node ]

        Nothing ->
            -- XXX Handle this better!
            Debug.crash ("Node has no group: " ++ node.name)


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ View.Utils.assetHitBox <| State.PsuId psu.id
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
