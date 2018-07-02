module Data.Server exposing (Id, IdTag, Server, decoder)

import Data.Asset as Asset
import Data.Chassis as Chassis
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Server =
    PhysicalAsset IdTag
        { chassisId : Chassis.Id
        }


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Server
decoder =
    PhysicalAsset.decoder create
        |> P.required "chassis_id" Asset.idDecoder


create : Id -> String -> D.Value -> String -> String -> Chassis.Id -> Server
create id name data manufacturer model chassisId =
    { id = id
    , name = name
    , data = data
    , manufacturer = manufacturer
    , model = model
    , chassisId = chassisId
    }
