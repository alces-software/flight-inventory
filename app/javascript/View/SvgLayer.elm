module View.SvgLayer exposing (view)

import Data.Asset as Asset
import Data.Network as Network exposing (Network)
import Data.NetworkConnection as NetworkConnection
import Data.State as State exposing (AppLayout(..), State)
import Geometry.Line as Line exposing (Line)
import Geometry.Networks
import Geometry.Point as Point exposing (Point)
import Html exposing (Html)
import List.Extra
import Maybe.Extra
import Svg exposing (..)
import Svg.Attributes exposing (..)


view : State -> Html msg
view state =
    -- XXX Consider using https://github.com/elm-community/typed-svg instead.
    let
        networkElements =
            case state.layout of
                Physical ->
                    drawNetworks state

                LogicalInGroups ->
                    []

                LogicalInGenders ->
                    []
    in
    svg
        [ class "svg-layer" ]
        networkElements


drawNetworks : State -> List (Svg msg)
drawNetworks state =
    -- Draw networks in name order, while network x-axis is determined in
    -- reverse name order, so networks will appear in alphabetical order from
    -- left to right, and with rightmost networks drawn over the lines of those
    -- to the left; this gives a layout which looks good, or at least
    -- consistent.
    State.networksByName state
        |> List.map (drawNetwork state)
        |> List.concat


drawNetwork : State -> Network -> List (Svg msg)
drawNetwork state network =
    let
        denormalizedConnections =
            State.denormalizedConnectionsForNetwork state network
    in
    case Geometry.Networks.axisForNetwork state network of
        Just axis ->
            drawNetworkAlongAxis state axis network denormalizedConnections

        Nothing ->
            []


drawNetworkAlongAxis :
    State
    -> Float
    -> Network
    -> List NetworkConnection.Denormalized
    -> List (Svg msg)
drawNetworkAlongAxis state axis network connections =
    let
        switchLines =
            List.map
                (Geometry.Networks.switchConnectionPosition state network
                    >> lineForAsset trunkLineWidth
                )
                switches
                |> Maybe.Extra.values

        switches =
            List.map .networkSwitch connections
                |> Asset.uniqueById

        adapterPortLines =
            List.map (\( _, l ) -> l) connectionsWithAdapterPortLines

        connectionsWithAdapterPortLines : List ( NetworkConnection.Denormalized, Line )
        connectionsWithAdapterPortLines =
            List.map
                (\connection ->
                    Maybe.map
                        (\line -> ( connection, line ))
                        (lineForAsset regularLineWidth
                            -- XXX Could change `adapterPortPosition` to not
                            -- independently find NetworkAdapter, since is
                            -- already available here in `connection`.
                            (Geometry.Networks.adapterPortPosition
                                state
                                connection.networkAdapterPort
                            )
                        )
                )
                connections
                |> Maybe.Extra.values

        lineForAsset : Int -> Maybe Point -> Maybe Line
        lineForAsset width start =
            Maybe.map
                (\s -> Line s (endPointFromStart s) width)
                start

        endPointFromStart =
            \start -> { x = axis, y = start.y }

        horizontalLines =
            List.concat [ switchLines, adapterPortLines ]

        endPoints =
            List.map .end horizontalLines

        maybeTopPoint =
            List.Extra.minimumBy .y endPoints

        maybeBottomPoint =
            List.Extra.maximumBy .y endPoints
                -- Offset the bottom point's Y coord slightly so it lines up
                -- neatly with the bottom-most horizontal line (without this it
                -- extends slightly beyond this, due to our use of
                -- `strokeLinecap "square"`).
                |> Maybe.map (\p -> Point p.x (p.y - bottomPointOffset))

        bottomPointOffset =
            regularLineWidth / 2

        trunkLineWidth =
            regularLineWidth * 2

        regularLineWidth =
            2
    in
    case ( maybeTopPoint, maybeBottomPoint ) of
        ( Just top, Just bottom ) ->
            let
                networkAxisLine =
                    { start = top
                    , end = bottom
                    , width = trunkLineWidth
                    }

                allLines =
                    networkAxisLine :: horizontalLines

                networkLabel =
                    drawLabel
                        (Point top.x (top.y - 20))
                        network.name
                        "font-size: 20px;"

                adapterPortLabels =
                    List.map adapterPortLabel connectionsWithAdapterPortLines

                adapterPortLabel : ( NetworkConnection.Denormalized, Line ) -> Svg msg
                adapterPortLabel ( connection, line ) =
                    let
                        labelPosition =
                            { x = line.start.x - 70
                            , y = line.start.y - 5
                            }
                    in
                    drawLabel
                        labelPosition
                        connection.networkAdapterPort.interface
                        "font-size: 12px;"

                drawLine =
                    \lineRecord ->
                        line
                            [ x1 <| toString lineRecord.start.x
                            , y1 <| toString lineRecord.start.y
                            , x2 <| toString lineRecord.end.x
                            , y2 <| toString lineRecord.end.y
                            , stroke network.cableColour
                            , strokeWidth <| toString lineRecord.width
                            , strokeLinecap "square"
                            ]
                            []

                drawLabel : Point -> String -> String -> Svg msg
                drawLabel =
                    \point label styles ->
                        text_
                            [ x <| toString point.x
                            , y <| toString point.y
                            , Svg.Attributes.style <|
                                "fill: "
                                    ++ network.cableColour
                                    ++ "; "
                                    ++ styles
                            ]
                            [ text label ]
            in
            List.concat
                [ List.map drawLine allLines
                , adapterPortLabels
                , [ networkLabel ]
                ]

        _ ->
            -- If we don't have a top and a bottom point then we can't have any
            -- points in the network at all, so nothing to draw.
            []
