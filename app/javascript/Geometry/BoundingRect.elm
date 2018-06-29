module Geometry.BoundingRect exposing (..)

import Geometry.Point exposing (Point)
import Json.Decode as D
import Json.Decode.Pipeline as P
import List.Extra


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


{-|

    Given some connection to be made, a list of all connections to be made, and
    a BoundingRect along the left hand side of which to make these connections,
    return the point at which this connection should be drawn from.

-}
connectionPoint : a -> List a -> BoundingRect -> Maybe Point
connectionPoint connection orderedConnections rect =
    let
        connectionIndex =
            List.Extra.elemIndex connection orderedConnections

        connectionPointFromConnectionIndex =
            \index ->
                let
                    proportion =
                        -- Want connections to be displayed evenly spaced along
                        -- rect's left hand side, so find the proportion along
                        -- the rect's height we should display this connection.
                        (toFloat index + 1)
                            / (toFloat (List.length orderedConnections) + 1)

                    connectionY =
                        rect.top + (proportion * rect.height)
                in
                Point rect.left connectionY
    in
    Maybe.map connectionPointFromConnectionIndex connectionIndex
