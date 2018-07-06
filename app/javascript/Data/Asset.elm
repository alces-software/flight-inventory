module Data.Asset exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P
import List.Extra
import Tagged exposing (Tagged)


type alias Asset idTag a =
    { a
        | id : Tagged idTag Int
        , name : String
        , data : D.Value
    }


type alias Id idTag =
    Tagged idTag Int


decoder : (Id idTag -> String -> D.Value -> a) -> D.Decoder a
decoder constructor =
    P.decode constructor
        |> P.required "id" idDecoder
        |> P.required "name" D.string
        |> P.required "data" D.value


create : Id idTag -> String -> D.Value -> Asset idTag {}
create id name data =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    }


idDecoder : D.Decoder (Id idTag)
idDecoder =
    D.map Tagged.tag D.int


uniqueIds : List (Id idTag) -> List (Id idTag)
uniqueIds =
    List.map Tagged.untag
        >> List.Extra.unique
        >> List.map Tagged.tag
