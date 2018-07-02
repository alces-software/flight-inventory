module Data.Psu exposing (Id, IdTag, Psu, decoder)

import Data.Asset as Asset
import Data.Chassis as Chassis
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Psu =
    PhysicalAsset IdTag
        { chassisId : Chassis.Id
        }


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Psu
decoder =
    PhysicalAsset.decoder create
        |> P.required "chassis_id" Asset.idDecoder


create : Id -> String -> D.Value -> String -> String -> Chassis.Id -> Psu
create id name data manufacturer model chassisId =
    { id = id
    , name = name
    , data = data
    , manufacturer = manufacturer
    , model = model
    , chassisId = chassisId
    }
