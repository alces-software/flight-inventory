module View.SvgLayer exposing (view)

import Data.Asset as Asset
import Data.Network as Network exposing (Network)
import Data.NetworkAdapter as NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.State as State exposing (AppLayout(..), State)
import Dict exposing (Dict)
import Geometry.Line as Line exposing (Line)
import Geometry.Networks
import Geometry.Point as Point exposing (Point)
import Html exposing (Html)
import List.Extra
import Maybe.Extra
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Tagged.Dict as TaggedDict exposing (TaggedDict)


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
        connections =
            Dict.values
                state.networkConnections
                |> List.filter (\con -> con.networkId == network.id)

        switches =
            linkedAssets connections .networkSwitchId .networkSwitches

        ports =
            linkedAssets connections .networkAdapterPortId .networkAdapterPorts

        adaptersWithPorts =
            List.map
                (\p ->
                    Maybe.map
                        (\adapter -> ( adapter, p ))
                        (TaggedDict.get p.networkAdapterId state.networkAdapters)
                )
                ports
                |> Maybe.Extra.values

        linkedAssets : List a -> (a -> Asset.Id idTag) -> (State -> TaggedDict idTag Int b) -> List b
        linkedAssets assets toLinkedAssetId toLinkedAssets =
            List.map toLinkedAssetId assets
                |> Asset.uniqueIds
                |> List.map (toLinkedAssets state |> flip TaggedDict.get)
                |> Maybe.Extra.values
    in
    case Geometry.Networks.axisForNetwork state network of
        Just axis ->
            drawNetworkAlongAxis state axis network switches adaptersWithPorts

        Nothing ->
            []


drawNetworkAlongAxis :
    State
    -> Float
    -> Network
    -> List NetworkSwitch
    -> List ( NetworkAdapter, NetworkAdapterPort )
    -> List (Svg msg)
drawNetworkAlongAxis state axis network switches adaptersWithPorts =
    let
        switchLines =
            List.map
                (Geometry.Networks.switchConnectionPosition state network
                    >> lineForAsset trunkLineWidth
                )
                switches
                |> Maybe.Extra.values

        adapterLines =
            List.map (\( _, _, l ) -> l) adaptersPortsAndLines

        adaptersPortsAndLines : List ( NetworkAdapter, NetworkAdapterPort, Line )
        adaptersPortsAndLines =
            List.map
                (\( a, p ) ->
                    Maybe.map
                        (\l -> ( a, p, l ))
                        (lineForAsset regularLineWidth
                            (Geometry.Networks.adapterPortPosition state p)
                        )
                )
                adaptersWithPorts
                |> Maybe.Extra.values

        lineForAsset : Int -> Maybe Point -> Maybe Line
        lineForAsset width start =
            Maybe.map
                (\s -> Line s (endPointFromStart s) width)
                start

        endPointFromStart =
            \start -> { x = axis, y = start.y }

        horizontalLines =
            List.concat [ switchLines, adapterLines ]

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

                adapterLabels =
                    List.map adapterLabel adaptersPortsAndLines

                adapterLabel : ( NetworkAdapter, NetworkAdapterPort, Line ) -> Svg msg
                adapterLabel ( a, p, l ) =
                    let
                        labelPosition =
                            { x = l.start.x - 70
                            , y = l.start.y - 5
                            }
                    in
                    drawLabel labelPosition p.interface "font-size: 12px;"

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
                , adapterLabels
                , [ networkLabel ]
                ]

        _ ->
            -- If we don't have a top and a bottom point then we can't have any
            -- points in the network at all, so nothing to draw.
            []
