module Data.Asset exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P
import List.Extra
import Tagged exposing (Tagged)


type alias Asset idTag a =
    { a
        | id : Tagged idTag Int
        , name : String
    }


type alias Id idTag =
    Tagged idTag Int


decoder : (Id idTag -> String -> a) -> D.Decoder a
decoder constructor =
    P.decode constructor
        |> P.required "id" idDecoder
        |> P.required "name" D.string


create : Id idTag -> String -> Asset idTag {}
create id name =
    { id = id
    , name = name
    }


idDecoder : D.Decoder (Id idTag)
idDecoder =
    D.map Tagged.tag D.int


uniqueIds : List (Id idTag) -> List (Id idTag)
uniqueIds =
    List.map Tagged.untag
        >> List.Extra.unique
        >> List.map Tagged.tag
