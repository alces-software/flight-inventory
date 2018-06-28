module Data.NetworkSwitch exposing (NetworkSwitch, decoder)

import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Geometry.BoundingRect as BoundingRect exposing (BoundingRect)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkSwitch =
    PhysicalAsset
        { boundingRect : Maybe BoundingRect
        }


decoder : D.Decoder NetworkSwitch
decoder =
    PhysicalAsset.decoder create


create : Int -> String -> String -> String -> NetworkSwitch
create id name manufacturer model =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , boundingRect = Nothing
    }
