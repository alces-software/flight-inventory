module Data.Pdu exposing (Id, IdTag, Pdu, decoder)

import Data.Asset as Asset
import Data.Oob as Oob exposing (HasOob)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Pdu =
    HasOob (PhysicalAsset IdTag {})


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Pdu
decoder =
    PhysicalAsset.decoder create
        |> P.required "oob_id" Asset.idDecoder


create : Id -> String -> D.Value -> String -> String -> Oob.Id -> Pdu
create id name data manufacturer model oobId =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    , manufacturer = manufacturer
    , model = model
    , oobId = oobId
    }
