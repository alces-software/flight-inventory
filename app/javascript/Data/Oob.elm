module Data.Oob exposing (Id, IdTag, Oob, decoder)

import Data.Asset as Asset
import Data.Network as Network
import Geometry.BoundingRect exposing (HasBoundingRect)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Oob =
    HasBoundingRect
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
    P.decode create
        |> P.required "id" Asset.idDecoder
        |> P.required "data" D.value
        |> P.required "network_id" Asset.idDecoder


create : Id -> D.Value -> Network.Id -> Oob
create id data networkId =
    { id = id
    , data = data
    , networkId = networkId
    , boundingRect = Nothing
    }
