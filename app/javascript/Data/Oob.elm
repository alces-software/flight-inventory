module Data.Oob exposing (Id, IdTag, Oob, decoder)

import Data.Asset as Asset
import Data.Network as Network
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Oob =
    { id : Id
    , data : D.Value
    , networkId : Network.Id
    }


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Oob
decoder =
    P.decode Oob
        |> P.required "id" Asset.idDecoder
        |> P.required "data" D.value
        |> P.required "network_id" Asset.idDecoder
