module View.Physical exposing (layout)

import Data.Chassis as Chassis exposing (Chassis)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.Oob as Oob exposing (HasOob, Oob)
import Data.Pdu as Pdu exposing (Pdu)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (AppLayout(..), State)
import Html exposing (..)
import Html.Attributes exposing (..)
import Msg exposing (Msg(..))
import Tagged.Dict as TaggedDict
import View.Logical
import View.Utils
import View.ViewCache as ViewCache exposing (ViewCache)


layout : ViewCache -> State -> Html Msg
layout viewCache state =
    div [ class "cluster" ]
        (List.concat
            [ [ assetTitle <| state.clusterName ]
            , List.map
                (switchView viewCache state)
                (State.switchesByName state)
            , List.map
                (pduView viewCache state)
                (State.pdusByName state)
            , List.map
                (chassisView viewCache state)
                (State.chassisByName state)
            ]
        )


switchView : ViewCache -> State -> NetworkSwitch -> Html Msg
switchView viewCache state switch =
    div
        [ class "network-switch"
        , View.Utils.idAttribute "data-network-switch-id" switch
        , title ("Network switch: " ++ switch.name)
        ]
        [ View.Utils.assetHitBox <| State.NetworkSwitchId switch.id
        , assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
        , networkConnectorsView viewCache state [] switch
        ]


pduView : ViewCache -> State -> Pdu -> Html Msg
pduView viewCache state pdu =
    div
        [ class "pdu"
        , title ("PDU: " ++ pdu.name)
        ]
        [ View.Utils.assetHitBox <| State.PduId pdu.id
        , assetTitle <| (PhysicalAsset.fullModel pdu ++ " PDU")
        , networkConnectorsView viewCache state [] pdu
        ]


chassisView : ViewCache -> State -> Chassis -> Html Msg
chassisView viewCache state chassis =
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
                    (List.map (serverView viewCache state)
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


serverView : ViewCache -> State -> Server -> Html Msg
serverView viewCache state server =
    div
        [ class "server"
        , title <| "Server: " ++ server.name
        ]
        [ View.Utils.assetHitBox <| State.ServerId server.id
        , assetTitle <| (PhysicalAsset.fullModel server ++ " server")
        , networkConnectorsView
            viewCache
            state
            (State.serverNetworkAdaptersByName state server)
            server
        , div [ class "nodes" ]
            (List.map
                (View.Logical.nodeView viewCache)
                (State.serverNodesByName state server)
            )
        ]


networkConnectorsView :
    ViewCache
    -> State
    -> List NetworkAdapter
    -> HasOob a
    -> Html Msg
networkConnectorsView viewCache state adapters { oobId } =
    let
        adapters_ =
            List.map (networkAdapterView viewCache) adapters

        oob =
            case TaggedDict.get oobId state.oobs of
                Just oob ->
                    oobView oob

                Nothing ->
                    text ""
    in
    div [ class "network-connectors" ]
        (List.concat [ adapters_, [ oob ] ])


networkAdapterView : ViewCache -> NetworkAdapter -> Html Msg
networkAdapterView viewCache adapter =
    div
        [ class "network-adapter"
        , View.Utils.idAttribute "data-network-adapter-id" adapter
        , title <|
            String.join " "
                [ "Network adapter:", PhysicalAsset.fullModel adapter, adapter.name ]
        , style [ ( "height", toString viewCache.adapterHeight ++ "px" ) ]
        ]
        [ View.Utils.assetHitBox <| State.NetworkAdapterId adapter.id
        , text "N"
        ]


oobView : Oob -> Html Msg
oobView oob =
    div
        [ View.Utils.idAttribute "data-oob-id" oob
        , class "oob"
        ]
        [ View.Utils.assetHitBox <| State.OobId oob.id
        , text "OOB"
        ]


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ View.Utils.assetHitBox <| State.PsuId psu.id
        , text (PhysicalAsset.fullModel psu ++ " PSU")
        ]


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]
