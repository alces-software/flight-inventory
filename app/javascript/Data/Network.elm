module Data.Network exposing (Id, IdTag, Network, decoder)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Network =
    Asset IdTag
        { cableColour : String
        }


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Network
decoder =
    Asset.decoder create
        |> P.required "cable_colour" D.string


create : Id -> String -> D.Value -> String -> Network
create id name data cableColour =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    , cableColour = cableColour
    }
