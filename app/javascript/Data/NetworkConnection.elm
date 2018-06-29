module Data.NetworkConnection exposing (..)

import Data.Asset as Asset
import Data.Network as Network
import Data.NetworkAdapterPort as NetworkAdapterPort
import Data.NetworkSwitch as NetworkSwitch
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkConnection =
    { networkId : Network.Id
    , networkAdapterPortId : NetworkAdapterPort.Id
    , networkSwitchId : NetworkSwitch.Id
    }


decoder : D.Decoder NetworkConnection
decoder =
    P.decode NetworkConnection
        |> P.required "network_id" Asset.idDecoder
        |> P.required "network_adapter_port_id" Asset.idDecoder
        |> P.required "network_switch_id" Asset.idDecoder
