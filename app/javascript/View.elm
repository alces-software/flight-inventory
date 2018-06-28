module View exposing (viewState)

import Data.Chassis as Chassis exposing (Chassis)
import Data.Network as Network exposing (Network)
import Data.NetworkAdapter as NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Data.State as State exposing (State)
import Dict exposing (Dict)
import Geometry.BoundingRect as BoundingRect
    exposing
        ( BoundingRect
        , HasBoundingRect
        )
import Geometry.Line as Line exposing (Line)
import Geometry.Point as Point exposing (Point)
import Hashbow
import Html exposing (..)
import Html.Attributes exposing (..)
import List.Extra
import Maybe.Extra
import Msg exposing (Msg(..))
import Svg exposing (Svg, line, svg, text_)
import Svg.Attributes
    exposing
        ( stroke
        , strokeLinecap
        , strokeWidth
        , x
        , x1
        , x2
        , y
        , y1
        , y2
        )


viewState : State -> Html Msg
viewState state =
    div []
        [ htmlLayer state
        , svgLayer state
        ]


htmlLayer : State -> Html Msg
htmlLayer state =
    let
        switches =
            Dict.values state.networkSwitches

        chassis =
            Dict.values state.chassis
    in
    -- XXX Fake rack for now
    div [ class "rack" ]
        (List.concat
            [ [ assetTitle "Rack" ]
            , List.map switchView switches
            , List.map (chassisView state) chassis
            ]
        )


switchView : NetworkSwitch -> Html Msg
switchView switch =
    div
        [ class "network-switch"
        , attribute "data-network-switch-id" (toString switch.id)
        , title ("Network switch: " ++ switch.name)
        ]
        [ assetTitle <| (PhysicalAsset.fullModel switch ++ " switch")
        ]


chassisView : State -> Chassis -> Html Msg
chassisView state chassis =
    let
        chassisServers =
            Dict.values <|
                Dict.filter
                    (\serverId server -> server.chassisId == chassis.id)
                    state.servers

        chassisPsus =
            Dict.values <|
                Dict.filter
                    (\psuId psu -> psu.chassisId == chassis.id)
                    state.psus
    in
    div [ class "chassis", title ("Chassis: " ++ chassis.name) ]
        (List.concat
            [ [ assetTitle <| (PhysicalAsset.fullModel chassis ++ " chassis") ]
            , [ div
                    [ class "servers" ]
                    (List.map (serverView state) chassisServers)
              ]
            , [ div [ class "psus" ]
                    (List.map psuView chassisPsus)
              ]
            ]
        )


serverView : State -> Server -> Html Msg
serverView state server =
    let
        serverNetworkAdapters =
            Dict.values <|
                Dict.filter
                    (\adapterId adapter -> adapter.serverId == server.id)
                    state.networkAdapters

        serverNodes =
            Dict.values <|
                Dict.filter
                    (\nodeId node -> node.serverId == server.id)
                    state.nodes
    in
    div [ class "server", title ("Server: " ++ server.name) ]
        (List.concat
            [ [ assetTitle <| (PhysicalAsset.fullModel server ++ " server") ]
            , [ div [ class "network-adapters" ]
                    (List.map networkAdapterView serverNetworkAdapters)
              ]
            , [ div [ class "nodes" ]
                    (List.map (nodeView state) serverNodes)
              ]
            ]
        )


networkAdapterView : NetworkAdapter -> Html Msg
networkAdapterView adapter =
    div
        [ class "network-adapter"
        , attribute "data-network-adapter-id" (toString adapter.id)
        , title <|
            String.join " "
                [ "Network adapter:", PhysicalAsset.fullModel adapter, adapter.name ]
        ]
        [ text "N" ]


nodeView : State -> Node -> Html Msg
nodeView state node =
    let
        nodeGroup =
            Dict.get node.groupId state.groups
    in
    case nodeGroup of
        Just group ->
            let
                groupColour =
                    Hashbow.hashbow group.name
            in
            div
                [ class "group"
                , style [ ( "border-color", groupColour ) ]
                , title ("Group: " ++ group.name)
                ]
                [ strong
                    [ class "group-name"
                    , style [ ( "color", groupColour ) ]
                    ]
                    [ text group.name ]
                , div
                    [ class "node", title "Node" ]
                    [ text node.name ]
                ]

        Nothing ->
            -- XXX Handle this better!
            Debug.crash ("Node has no group: " ++ node.name)


psuView : Psu -> Html Msg
psuView psu =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ text (PhysicalAsset.fullModel psu ++ " PSU") ]


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]


svgLayer : State -> Html msg
svgLayer state =
    -- XXX Consider using https://github.com/elm-community/typed-svg instead.
    svg
        [ Svg.Attributes.class "svg-layer" ]
        (Dict.values state.networks
            |> List.map (drawNetwork state)
            |> List.concat
        )


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
                        (Dict.get p.networkAdapterId state.networkAdapters)
                )
                ports
                |> Maybe.Extra.values

        linkedAssets : List a -> (a -> Int) -> (State -> Dict Int b) -> List b
        linkedAssets assets toLinkedAssetId toLinkedAssets =
            List.map toLinkedAssetId assets
                |> List.Extra.unique
                |> List.map (toLinkedAssets state |> flip Dict.get)
                |> Maybe.Extra.values

        xAxis =
            -- XXX do better
            600
    in
    drawNetworkAlongAxis xAxis network switches adaptersWithPorts


drawNetworkAlongAxis :
    Float
    -> Network
    -> List NetworkSwitch
    -> List ( NetworkAdapter, NetworkAdapterPort )
    -> List (Svg msg)
drawNetworkAlongAxis xAxis network switches adaptersWithPorts =
    let
        switchLines =
            List.map (lineForAsset trunkLineWidth) switches
                |> Maybe.Extra.values

        adapterLines =
            List.map (\( _, _, l ) -> l) adaptersPortsAndLines

        adaptersPortsAndLines : List ( NetworkAdapter, NetworkAdapterPort, Line )
        adaptersPortsAndLines =
            List.map
                (\( a, p ) ->
                    Maybe.map
                        (\l -> ( a, p, l ))
                        (lineForAsset regularLineWidth a)
                )
                adaptersWithPorts
                |> Maybe.Extra.values

        lineForAsset : Int -> HasBoundingRect a -> Maybe Line
        lineForAsset width assetWithRect =
            let
                start =
                    startPointForAsset assetWithRect
            in
            Maybe.map
                (\s -> Line s (endPointFromStart s) width)
                start

        startPointForAsset : HasBoundingRect a -> Maybe Point
        startPointForAsset =
            .boundingRect >> Maybe.map BoundingRect.leftMiddlePoint

        endPointFromStart =
            \start -> { x = xAxis, y = start.y }

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
                            { x = l.start.x - 80
                            , y = l.start.y - 5
                            }
                    in
                    drawLabel labelPosition p.interface ""

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
                            [ Svg.text label ]
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
