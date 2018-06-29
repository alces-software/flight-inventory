module Geometry.BoundingRect exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P


type alias BoundingRect =
    { top : Float
    , bottom : Float
    , left : Float
    , right : Float
    , width : Float
    , height : Float
    }


type alias HasBoundingRect a =
    { a | boundingRect : Maybe BoundingRect }


decoder : D.Decoder BoundingRect
decoder =
    P.decode BoundingRect
        |> P.required "top" D.float
        |> P.required "bottom" D.float
        |> P.required "left" D.float
        |> P.required "right" D.float
        |> P.required "width" D.float
        |> P.required "height" D.float
