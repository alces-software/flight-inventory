module Geometry.Point exposing (..)

import List.Extra


type alias Point =
    { x : Float, y : Float }


{-| Return highest Point (Point with lowest Y coordinate) from a list of
points.
-}
top : List Point -> Maybe Point
top points =
    List.Extra.minimumBy .y points


{-| Return lowest Point (Point with highest Y coordinate) from a list of
points.
-}
bottom : List Point -> Maybe Point
bottom points =
    List.Extra.maximumBy .y points
