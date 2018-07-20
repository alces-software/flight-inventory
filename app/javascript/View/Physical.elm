module View.Physical exposing (layout)

import Data.Chassis as Chassis exposing (Chassis)
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkSwitch exposing (NetworkSwitch)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (AppLayout(..), State)
import Geometry.Networks
import Html exposing (..)
import Html.Attributes exposing (..)
import Msg exposing (Msg(..))
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
                (switchView viewCache)
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


switchView : ViewCache -> NetworkSwitch -> Html Msg
switchView viewCache switch =
    div
        [ class "network-switch"
        , View.Utils.idAttribute "data-network-switch-id" switch
        , title ("Network switch: " ++ switch.name)
        , style [ ( "height", toString viewCache.switchHeight ++ "px" ) ]
        ]
        [ View.Utils.assetHitBox <| State.NetworkSwitchId switch.id
        , assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
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
        (List.concat
            [ [ View.Utils.assetHitBox <| State.ServerId server.id
              , assetTitle <| (PhysicalAsset.fullModel server ++ " server")
              ]
            , [ div [ class "network-adapters" ]
                    (List.map
                        (networkAdapterView viewCache)
                        (State.serverNetworkAdaptersByName state server)
                    )
              ]
            , [ div [ class "nodes" ]
                    (List.map
                        View.Logical.nodeView
                        (State.serverNodesByName state server)
                    )
              ]
            ]
        )


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


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ View.Utils.assetHitBox <| State.PsuId psu.id
        , text (PhysicalAsset.fullModel psu ++ " PSU")
        ]


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]
