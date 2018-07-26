module Data.NetworkAdapterPort exposing (Id, IdTag, NetworkAdapterPort, decoder)

import Data.Asset as Asset
import Data.NetworkAdapter as NetworkAdapter
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkAdapterPort =
    { id : Id
    , networkAdapterId : NetworkAdapter.Id
    , number : Int
    }


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder NetworkAdapterPort
decoder =
    P.decode NetworkAdapterPort
        |> P.required "id" Asset.idDecoder
        |> P.required "network_adapter_id" Asset.idDecoder
        |> P.required "number" D.int
