module Data.Network exposing (Id, IdTag, Network, colour, decoder)

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


colour : Network -> String
colour { cableColour } =
    -- Quick fix to allow clearly displaying Networks with the same cable
    -- colour as the background colour; might be better to keep the same colour
    -- and instead show a border around the whole network, but this is
    -- non-trivial to do in a way which looks good since each network diagram
    -- consists of arbitrary lines drawn over each other (also relevant:
    -- https://stackoverflow.com/a/8845581/2620402).
    if cableColour == "white" then
        "black"
    else
        cableColour
