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


create : Id -> String -> String -> Network
create id name cableColour =
    { id = id
    , name = name
    , cableColour = cableColour
    }
