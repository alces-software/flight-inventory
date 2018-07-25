module Data.Server exposing (Id, IdTag, Server, decoder)

import Data.Asset as Asset
import Data.Chassis as Chassis
import Data.Oob as Oob exposing (HasOob)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Server =
    HasOob (PhysicalAsset IdTag { chassisId : Chassis.Id })


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Server
decoder =
    PhysicalAsset.decoder create
        |> P.required "chassis_id" Asset.idDecoder
        |> P.required "oob_id" Asset.idDecoder


create : Id -> String -> D.Value -> String -> String -> Chassis.Id -> Oob.Id -> Server
create id name data manufacturer model chassisId oobId =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    , manufacturer = manufacturer
    , model = model
    , chassisId = chassisId
    , oobId = oobId
    }
