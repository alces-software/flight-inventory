module Data.PhysicalAsset exposing (..)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias PhysicalAsset a =
    Asset
        { a
            | manufacturer : String
            , model : String
        }


decoder constructor =
    Asset.decoder constructor
        |> P.requiredAt [ "data", "manufacturer" ] D.string
        |> P.requiredAt [ "data", "model" ] D.string


create id name manufacturer model =
    -- Note: Have to define own constructor function here, and in similar
    -- places below, as extensible records do not currently define their own
    -- constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    }


fullModel : PhysicalAsset a -> String
fullModel { manufacturer, model } =
    String.join " " [ manufacturer, model ]
