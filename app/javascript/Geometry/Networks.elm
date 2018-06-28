module Geometry.Networks
    exposing
        ( adapterHeight
        , adapterPortPosition
        , switchHeight
        , xAxisForNetwork
        )

import Data.Network as Network exposing (Network)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.State as State exposing (State)
import Dict
import Geometry.Point exposing (Point)
import List.Extra
import Maybe.Extra


adapterHeight : State -> Int
adapterHeight state =
    let
        maxAdapterConnections =
            Dict.values state.networkAdapters
                |> List.map numberConnectionsForAdapter
                |> List.maximum
                |> Maybe.withDefault 0

        numberConnectionsForAdapter =
            State.portsForAdapter state
                >> List.map (State.connectionForPort state)
                >> Maybe.Extra.values
                >> List.length
    in
    maxAdapterConnections * pixelsPerConnection


switchHeight : State -> Int
switchHeight state =
    -- XXX DRY up with above?
    let
        maxNetworkConnections =
            Dict.values state.networkSwitches
                |> List.map numberConnectionsForSwitch
                |> List.maximum
                |> Maybe.withDefault 0

        numberConnectionsForSwitch =
            State.networksConnectedToSwitch state
                >> List.length
    in
    maxNetworkConnections * pixelsPerConnection


pixelsPerConnection : Int
pixelsPerConnection =
    20


adapterPortPosition : State -> NetworkAdapterPort -> Maybe Point
adapterPortPosition state adapterPort =
    let
        adapter =
            Dict.get adapterPort.networkAdapterId state.networkAdapters

        interfaceOrderedPorts =
            Maybe.map
                (State.portsForAdapter state >> List.sortBy .interface)
                adapter

        interfaceOrderedConnections =
            Maybe.map
                (List.map (State.connectionForPort state) >> Maybe.Extra.values)
                interfaceOrderedPorts

        portConnection =
            State.connectionForPort state adapterPort

        adapterRect =
            Maybe.map .boundingRect adapter
                |> Maybe.Extra.join
    in
    case ( adapterRect, interfaceOrderedConnections, portConnection ) of
        ( Just rect, Just connections, Just connection ) ->
            let
                connectionIndex =
                    List.Extra.elemIndex connection connections
            in
            case connectionIndex of
                Just index ->
                    let
                        portProportion =
                            -- Want connections to be displayed evenly spaced
                            -- along adapter's left hand side (and in
                            -- alphanumeric order by their interface name), so
                            -- find the proportion along the adapter's height
                            -- we should display this connection.
                            (toFloat index + 1)
                                / (toFloat (List.length connections) + 1)

                        portY =
                            rect.top + (portProportion * rect.height)
                    in
                    Just <| Point rect.left portY

                Nothing ->
                    Nothing

        _ ->
            Nothing


xAxisForNetwork : State -> Network -> Maybe Float
xAxisForNetwork state network =
    let
        firstSwitchX =
            Dict.values state.networkSwitches
                |> List.head
                |> Maybe.map .boundingRect
                |> Maybe.Extra.join
                |> Maybe.map .left

        networkSpacing =
            100

        networkIndex =
            State.networksByName state
                |> List.reverse
                |> List.Extra.elemIndex network
    in
    case ( firstSwitchX, networkIndex ) of
        ( Just switchX, Just index ) ->
            let
                xAxisOffset =
                    -- Add 2 to index so rightmost network axis is offset from
                    -- switches and adapters by twice usual offset; looks
                    -- slightly nicer with some space between rack edge and
                    -- network axes.
                    ((index + 2) * networkSpacing) |> toFloat
            in
            Just <| switchX - xAxisOffset

        _ ->
            Nothing
