module View exposing (viewState)

import Data.Chassis as Chassis exposing (Chassis)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (State)
import Dict exposing (Dict)
import Hashbow
import Html exposing (..)
import Html.Attributes exposing (..)
import Msg exposing (Msg(..))
import View.SvgLayer as SvgLayer


viewState : State -> Html Msg
viewState state =
    div []
        [ htmlLayer state
        , SvgLayer.view state
        ]


htmlLayer : State -> Html Msg
htmlLayer state =
    let
        switches =
            Dict.values state.networkSwitches

        chassis =
            Dict.values state.chassis
    in
    -- XXX Fake rack for now
    div [ class "rack" ]
        (List.concat
            [ [ assetTitle "Rack" ]
            , List.map switchView switches
            , List.map (chassisView state) chassis
            ]
        )


switchView : NetworkSwitch -> Html Msg
switchView switch =
    div
        [ class "network-switch"
        , attribute "data-network-switch-id" (toString switch.id)
        , title ("Network switch: " ++ switch.name)
        ]
        [ assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
        ]


chassisView : State -> Chassis -> Html Msg
chassisView state chassis =
    let
        chassisServers =
            Dict.values <|
                Dict.filter
                    (\serverId server -> server.chassisId == chassis.id)
                    state.servers

        chassisPsus =
            Dict.values <|
                Dict.filter
                    (\psuId psu -> psu.chassisId == chassis.id)
                    state.psus
    in
    div [ class "chassis", title ("Chassis: " ++ chassis.name) ]
        (List.concat
            [ [ assetTitle <| (PhysicalAsset.fullModel chassis ++ " chassis") ]
            , [ div
                    [ class "servers" ]
                    (List.map (serverView state) chassisServers)
              ]
            , [ div [ class "psus" ]
                    (List.map psuView chassisPsus)
              ]
            ]
        )


serverView : State -> Server -> Html Msg
serverView state server =
    let
        serverNetworkAdapters =
            Dict.values <|
                Dict.filter
                    (\adapterId adapter -> adapter.serverId == server.id)
                    state.networkAdapters

        serverNodes =
            Dict.values <|
                Dict.filter
                    (\nodeId node -> node.serverId == server.id)
                    state.nodes
    in
    div [ class "server", title ("Server: " ++ server.name) ]
        (List.concat
            [ [ assetTitle <| (PhysicalAsset.fullModel server ++ " server") ]
            , [ div [ class "network-adapters" ]
                    (List.map networkAdapterView serverNetworkAdapters)
              ]
            , [ div [ class "nodes" ]
                    (List.map (nodeView state) serverNodes)
              ]
            ]
        )


networkAdapterView : NetworkAdapter -> Html Msg
networkAdapterView adapter =
    div
        [ class "network-adapter"
        , attribute "data-network-adapter-id" (toString adapter.id)
        , title <|
            String.join " "
                [ "Network adapter:", PhysicalAsset.fullModel adapter, adapter.name ]
        ]
        [ text "N" ]


nodeView : State -> Node -> Html Msg
nodeView state node =
    let
        nodeGroup =
            Dict.get node.groupId state.groups
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
                    [ text node.name ]
                ]

        Nothing ->
            -- XXX Handle this better!
            Debug.crash ("Node has no group: " ++ node.name)


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ text (PhysicalAsset.fullModel psu ++ " PSU") ]


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]
