module Data.Server exposing (Server, decoder)

import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Server =
    PhysicalAsset
        { chassisId : Int
        }


decoder : D.Decoder Server
decoder =
    PhysicalAsset.decoder create
        |> P.required "chassis_id" D.int


create : Int -> String -> String -> String -> Int -> Server
create id name manufacturer model chassisId =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , chassisId = chassisId
    }
