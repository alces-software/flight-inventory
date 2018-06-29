module Geometry.Networks
    exposing
        ( adapterHeight
        , adapterPortPosition
        , switchConnectionPosition
        , switchHeight
        , xAxisForNetwork
        )

import Data.Network as Network exposing (Network)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.State as State exposing (State)
import Dict
import Geometry.BoundingRect as BoundingRect
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
    case ( portConnection, interfaceOrderedConnections, adapterRect ) of
        ( Just connection, Just connections, Just rect ) ->
            BoundingRect.connectionPoint connection connections rect

        _ ->
            Nothing


switchConnectionPosition : State -> Network -> NetworkSwitch -> Maybe Point
switchConnectionPosition state network switch =
    let
        nameOrderedConnectedNetworks =
            State.networksConnectedToSwitch state switch
                |> List.sortBy .name

        connectionPoint =
            BoundingRect.connectionPoint network nameOrderedConnectedNetworks
    in
    Maybe.map connectionPoint switch.boundingRect
        |> Maybe.Extra.join


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
