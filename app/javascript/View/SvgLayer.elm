module View.SvgLayer exposing (view)

import Data.Asset as Asset
import Data.Network as Network exposing (Network)
import Data.NetworkConnection as NetworkConnection
import Data.State as State exposing (AppLayout(..), State)
import Geometry.Line as Line exposing (Line)
import Geometry.Networks
import Geometry.Point as Point exposing (Point)
import Html exposing (Html)
import Maybe.Extra
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Tagged.Dict as TaggedDict


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

        externalNetworkElements =
            case Geometry.Networks.axisForNetwork state network of
                Just axis ->
                    drawExternalNetworkAlongAxis
                        state
                        axis
                        network
                        denormalizedConnections

                Nothing ->
                    []

        internalNetworkElements =
            drawInternalNetwork state network denormalizedConnections
    in
    List.concat [ externalNetworkElements, internalNetworkElements ]


drawExternalNetworkAlongAxis :
    State
    -> Float
    -> Network
    -> List NetworkConnection.Denormalized
    -> List (Svg msg)
drawExternalNetworkAlongAxis state axis network connections =
    let
        horizontalLines =
            List.concat
                [ externalNetworkSwitchLines state axis network connections
                , adapterPortLines
                , externalNetworkOobLines state axis network
                ]

        ( adapterPortLines, adapterPortLabels ) =
            externalNetworkAdapterPortLinesAndLabels state axis network connections

        endPoints =
            List.map .end horizontalLines
    in
    case ( Point.top endPoints, Point.bottom endPoints ) of
        ( Just top, Just bottom ) ->
            let
                networkAxisLine =
                    -- Slightly shift Y-coordinates of top and bottom of axis
                    -- line so these line up flush with top and bottom-most
                    -- lines drawn from axis.
                    { start = { x = top.x, y = top.y + axisLineOffset }
                    , end = { x = bottom.x, y = bottom.y - axisLineOffset }
                    , width = trunkLineWidth
                    }

                axisLineOffset =
                    toFloat standardLineWidth / 2

                allLines =
                    networkAxisLine :: horizontalLines

                networkLabel =
                    drawNetworkLabel
                        network
                        (Point top.x (top.y - 20))
                        network.name
                        "font-size: 20px;"
            in
            List.concat
                [ List.map (drawNetworkLine network) allLines
                , adapterPortLabels
                , [ networkLabel ]
                ]

        _ ->
            -- If we don't have a top and a bottom point then we can't have any
            -- points in the network at all, so nothing to draw.
            []


externalNetworkSwitchLines :
    State
    -> Float
    -> Network
    -> List NetworkConnection.Denormalized
    -> List Line
externalNetworkSwitchLines state axis network connections =
    let
        switches =
            List.map .networkSwitch connections
                |> Asset.uniqueById
    in
    List.map
        (Geometry.Networks.switchConnectionPosition state network
            >> externalNetworkConnectionLine axis trunkLineWidth
        )
        switches
        |> Maybe.Extra.values


externalNetworkOobLines : State -> Float -> Network -> List Line
externalNetworkOobLines state axis network =
    let
        lineForOob =
            Geometry.Networks.oobConnectionPosition
                >> externalNetworkConnectionLine axis standardLineWidth

        oobs =
            TaggedDict.values state.oobs
                |> List.filter (.networkId >> (==) network.id)
    in
    List.map lineForOob oobs
        |> Maybe.Extra.values


externalNetworkAdapterPortLinesAndLabels :
    State
    -> Float
    -> Network
    -> List NetworkConnection.Denormalized
    -> ( List Line, List (Svg msg) )
externalNetworkAdapterPortLinesAndLabels state axis network connections =
    let
        lineWithConnection =
            \connection ->
                Maybe.map
                    (\line -> ( line, connection ))
                    (lineForConnection connection)

        lineForConnection =
            \connection ->
                externalNetworkConnectionLine axis
                    standardLineWidth
                    -- XXX Could change `adapterPortPosition` to not
                    -- independently find NetworkAdapter, since is
                    -- already available here in `connection`.
                    (Geometry.Networks.adapterPortPosition
                        state
                        connection.networkAdapterPort
                    )

        lineWithLabel =
            \( line, connection ) ->
                let
                    label =
                        drawNetworkLabel
                            network
                            labelPosition
                            connection.networkAdapterPort.interface
                            "font-size: 12px;"

                    labelPosition =
                        { x = line.start.x - 70
                        , y = line.start.y - 5
                        }
                in
                ( line, label )

        linesAndLabelsFromLinesWithLabels :
            List ( Line, Svg msg )
            -> ( List Line, List (Svg msg) )
        linesAndLabelsFromLinesWithLabels linesWithLabels =
            ( List.map Tuple.first linesWithLabels
            , List.map Tuple.second linesWithLabels
            )
    in
    List.map lineWithConnection connections
        |> Maybe.Extra.values
        |> List.map lineWithLabel
        |> linesAndLabelsFromLinesWithLabels


externalNetworkConnectionLine : Float -> Int -> Maybe Point -> Maybe Line
externalNetworkConnectionLine axis width maybeStart =
    let
        endPointFromStart =
            \start -> { x = axis, y = start.y }
    in
    Maybe.map
        (\s -> Line s (endPointFromStart s) width)
        maybeStart


drawInternalNetwork :
    State
    -> Network
    -> List NetworkConnection.Denormalized
    -> List (Svg msg)
drawInternalNetwork state network connections =
    List.map (nodeConnectionLine state network) connections
        |> Maybe.Extra.values
        |> List.map (drawNetworkLine network)


nodeConnectionLine : State -> Network -> NetworkConnection.Denormalized -> Maybe Line
nodeConnectionLine state network connection =
    let
        portPoint =
            Geometry.Networks.adapterPortPosition
                state
                connection.networkAdapterPort

        nodePoint =
            Maybe.map
                (Geometry.Networks.nodeConnectionPosition state network)
                connection.node
                |> Maybe.Extra.join
    in
    case ( portPoint, nodePoint ) of
        ( Just portPoint_, Just nodePoint_ ) ->
            Just <| Line portPoint_ nodePoint_ standardLineWidth

        _ ->
            Nothing


drawNetworkLine : Network -> Line -> Svg msg
drawNetworkLine network line_ =
    line
        [ x1 <| toString line_.start.x
        , y1 <| toString line_.start.y
        , x2 <| toString line_.end.x
        , y2 <| toString line_.end.y
        , stroke <| Network.colour network
        , strokeWidth <| toString line_.width
        , strokeLinecap "square"
        ]
        []


drawNetworkLabel : Network -> Point -> String -> String -> Svg msg
drawNetworkLabel network point label styles =
    text_
        [ x <| toString point.x
        , y <| toString point.y
        , Svg.Attributes.style <|
            "fill: "
                ++ Network.colour network
                ++ "; "
                ++ styles
        ]
        [ text label ]


standardLineWidth : Int
standardLineWidth =
    2


trunkLineWidth : Int
trunkLineWidth =
    standardLineWidth * 2
