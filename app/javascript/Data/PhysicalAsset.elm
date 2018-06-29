module Data.PhysicalAsset exposing (..)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias PhysicalAsset idTag a =
    Asset idTag
        { a
            | manufacturer : String
            , model : String
        }


decoder : (Asset.Id idTag -> String -> String -> String -> a) -> D.Decoder a
decoder constructor =
    Asset.decoder constructor
        |> P.requiredAt [ "data", "manufacturer" ] D.string
        |> P.requiredAt [ "data", "model" ] D.string


create : Asset.Id idTag -> String -> String -> String -> PhysicalAsset idTag {}
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


fullModel : PhysicalAsset idTag a -> String
fullModel { manufacturer, model } =
    String.join " " [ manufacturer, model ]
