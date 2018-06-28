module Geometry.BoundingRect exposing (..)

import Geometry.Point as Point exposing (Point)
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


leftMiddlePoint : BoundingRect -> Point
leftMiddlePoint rect =
    let
        x =
            rect.left

        y =
            rect.top + (rect.height / 2)
    in
    { x = x, y = y }
