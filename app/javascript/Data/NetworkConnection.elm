module Data.NetworkConnection exposing (..)

import Data.Asset as Asset
import Data.Network as Network
import Data.NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkConnection =
    { networkId : Network.Id
    , networkAdapterPortId : NetworkAdapterPort.Id
    , networkSwitchId : NetworkSwitch.Id

    -- XXX It should be the case that presence of `nodeId` <=> presence of
    -- `interface`, so maybe should tweak data model to represent this.
    , nodeId : Maybe Node.Id
    , interface : Maybe String
    }


{-| Type alias to make working with NetworkConnections simpler.

    Includes NetworkAdapter for NetworkAdapterPort, since is also useful to
    have this available when working with a connection; does not include
    Network itself as we currently always find the connections given a
    particular Network.

-}
type alias Denormalized =
    { networkAdapterPort : NetworkAdapterPort
    , networkAdapter : NetworkAdapter
    , networkSwitch : NetworkSwitch
    , node : Maybe Node
    , interface : Maybe String
    }


decoder : D.Decoder NetworkConnection
decoder =
    P.decode NetworkConnection
        |> P.required "network_id" Asset.idDecoder
        |> P.required "network_adapter_port_id" Asset.idDecoder
        |> P.required "network_switch_id" Asset.idDecoder
        |> P.required "node_id" (D.nullable Asset.idDecoder)
        |> P.required "interface" (D.nullable D.string)
