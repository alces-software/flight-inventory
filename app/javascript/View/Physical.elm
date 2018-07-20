module View.Physical exposing (layout)

import Data.Chassis as Chassis exposing (Chassis)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.Oob as Oob exposing (Oob)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (AppLayout(..), State)
import Geometry.Networks
import Html exposing (..)
import Html.Attributes exposing (..)
import Msg exposing (Msg(..))
import Tagged.Dict as TaggedDict
import View.Logical
import View.Utils


layout : State -> Html Msg
layout state =
    let
        viewCache =
            initializeViewCache state
    in
    div [ class "cluster" ]
        (List.concat
            [ [ assetTitle <| state.clusterName ]
            , List.map
                (switchView viewCache state)
                (State.switchesByName state)
            , List.map
                (chassisView viewCache state)
                (State.chassisByName state)
            ]
        )


initializeViewCache : State -> ViewCache
initializeViewCache state =
    -- We calculate these values needed in many places once up-front and then
    -- thread this record through as needed, rather than repeating this many
    -- times at point of use, since doing that is somewhat time consuming and
    -- noticeably slows things down.
    { adapterHeight = Geometry.Networks.adapterHeight state
    , switchHeight = Geometry.Networks.switchHeight state
    }


type alias ViewCache =
    { adapterHeight : Int
    , switchHeight : Int
    }


switchView : ViewCache -> State -> NetworkSwitch -> Html Msg
switchView viewCache state switch =
    div
        [ class "network-switch"
        , View.Utils.idAttribute "data-network-switch-id" switch
        , title ("Network switch: " ++ switch.name)
        , style [ ( "height", toString viewCache.switchHeight ++ "px" ) ]
        ]
        [ View.Utils.assetHitBox <| State.NetworkSwitchId switch.id
        , assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
        , networkConnectorsView viewCache state [] switch
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
                View.Logical.nodeView
                (State.serverNodesByName state server)
            )
        ]


networkConnectorsView :
    ViewCache
    -> State
    -> List NetworkAdapter
    -> { a | oobId : Oob.Id }
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
    div [ class "oob" ]
        [ text "OOB" ]


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ View.Utils.assetHitBox <| State.PsuId psu.id
        , text (PhysicalAsset.fullModel psu ++ " PSU")
        ]


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]
