module Data.Asset exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Asset a =
    { a
        | id : Int
        , name : String
    }


decoder constructor =
    P.decode constructor
        |> P.required "id" D.int
        |> P.required "name" D.string


create id name =
    { id = id
    , name = name
    }
