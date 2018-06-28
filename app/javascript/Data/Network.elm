module Data.Network exposing (Network, decoder)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Network =
    Asset
        { cableColour : String
        }


decoder : D.Decoder Network
decoder =
    Asset.decoder create
        |> P.required "cable_colour" D.string


create id name cableColour =
    { id = id
    , name = name
    , cableColour = cableColour
    }
