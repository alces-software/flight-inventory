module Data.NetworkConnection exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkConnection =
    { networkId : Int
    , networkAdapterPortId : Int
    , networkSwitchId : Int
    }


decoder : D.Decoder NetworkConnection
decoder =
    P.decode NetworkConnection
        |> P.required "network_id" D.int
        |> P.required "network_adapter_port_id" D.int
        |> P.required "network_switch_id" D.int
