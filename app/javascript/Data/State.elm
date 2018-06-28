module Data.State exposing (State, decoder)

import Data.Chassis as Chassis exposing (Chassis)
import Data.Group as Group exposing (Group)
import Data.Network as Network exposing (Network)
import Data.NetworkAdapter as NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkConnection as NetworkConnection exposing (NetworkConnection)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias State =
    { chassis : Dict Int Chassis
    , servers : Dict Int Server
    , psus : Dict Int Psu
    , networkAdapters : Dict Int NetworkAdapter
    , networkAdapterPorts : Dict Int NetworkAdapterPort
    , networkConnections : Dict Int NetworkConnection
    , networks : Dict Int Network
    , networkSwitches : Dict Int NetworkSwitch
    , nodes : Dict Int Node
    , groups : Dict Int Group
    }


decoder : D.Decoder State
decoder =
    P.decode State
        |> P.required "chassis" (assetDictDecoder Chassis.decoder)
        |> P.required "servers" (assetDictDecoder Server.decoder)
        |> P.required "psus" (assetDictDecoder Psu.decoder)
        |> P.required "networkAdapters" (assetDictDecoder NetworkAdapter.decoder)
        |> P.required "networkAdapterPorts" (assetDictDecoder NetworkAdapterPort.decoder)
        |> P.required "networkConnections" (assetDictDecoder NetworkConnection.decoder)
        |> P.required "networks" (assetDictDecoder Network.decoder)
        |> P.required "networkSwitches" (assetDictDecoder NetworkSwitch.decoder)
        |> P.required "nodes" (assetDictDecoder Node.decoder)
        |> P.required "groups" (assetDictDecoder Group.decoder)


assetDictDecoder : D.Decoder asset -> D.Decoder (Dict Int asset)
assetDictDecoder assetDecoder =
    D.list
        (D.map2 (,)
            (D.field "id" D.int)
            assetDecoder
        )
        |> D.map Dict.fromList
