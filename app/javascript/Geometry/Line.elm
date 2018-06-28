module Geometry.Line exposing (..)

import Geometry.Point as Point exposing (Point)


type alias Line =
    { start : Point
    , end : Point
    , width : Int
    }
