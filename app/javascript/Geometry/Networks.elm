module Geometry.Networks
    exposing
        ( adapterHeight
        , adapterPortPosition
        , axisForNetwork
        , nodeConnectionPosition
        , oobConnectionPosition
        , switchConnectionPosition
        , switchHeight
        )

import Data.Network as Network exposing (Network)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.Node exposing (Node)
import Data.Oob exposing (Oob)
import Data.State as State exposing (State)
import Geometry.BoundingRect as BoundingRect
import Geometry.Point exposing (Point)
import List.Extra
import Maybe.Extra
import Tagged.Dict as TaggedDict


adapterHeight : State -> Int
adapterHeight state =
    let
        connectionsForAdapter =
            State.portsForAdapter state
                >> List.map (State.connectionForPort state)
                >> Maybe.Extra.values
    in
    connectedRectHeight
        (TaggedDict.values state.networkAdapters)
        connectionsForAdapter


switchHeight : State -> Int
switchHeight state =
    connectedRectHeight
        (TaggedDict.values state.networkSwitches)
        (State.networksConnectedToSwitch state)


{-|

    Return the height each rectangle to have connections drawn from it should
    be, in order for all such rectangles to have the same height and the
    rectangle with most connections to have sufficient space to clearly and
    neatly draw all of these.

-}
connectedRectHeight : List connected -> (connected -> List connections) -> Int
connectedRectHeight allConnected connectionsFor =
    let
        maxConnections =
            List.map numberConnectionsFor allConnected
                |> List.maximum
                |> Maybe.withDefault 0

        numberConnectionsFor =
            connectionsFor >> List.length

        pixelsPerConnection =
            20
    in
    maxConnections * pixelsPerConnection


adapterPortPosition : State -> NetworkAdapterPort -> Maybe Point
adapterPortPosition state adapterPort =
    let
        adapter =
            TaggedDict.get adapterPort.networkAdapterId state.networkAdapters

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
        connectedNetworks =
            State.networksConnectedToSwitch state switch

        connectionPoint =
            BoundingRect.connectionPoint network connectedNetworks
    in
    Maybe.map connectionPoint switch.boundingRect
        |> Maybe.Extra.join


nodeConnectionPosition : State -> Network -> Node -> Maybe Point
nodeConnectionPosition state network node =
    let
        connectedNetworks =
            State.networksConnectedToNode state node

        connectionPoint =
            BoundingRect.connectionPoint network connectedNetworks
    in
    Maybe.map connectionPoint node.boundingRect
        |> Maybe.Extra.join


oobConnectionPosition : Oob -> Maybe Point
oobConnectionPosition oob =
    let
        connectionPoint =
            -- It should currently always be the case that every OOB will only
            -- have a single connection to a single Network; if this ever
            -- changes though we should change this to pass the Network we're
            -- connecting here, as well as all Networks connected to this OOB
            -- (similar to functions above), otherwise all Network
            -- connections for the OOB will be drawn on top of each other.
            BoundingRect.connectionPoint oob [ oob ]
    in
    Maybe.map connectionPoint oob.boundingRect
        |> Maybe.Extra.join


axisForNetwork : State -> Network -> Maybe Float
axisForNetwork state network =
    let
        firstSwitchX =
            TaggedDict.values state.networkSwitches
                |> List.head
                |> Maybe.map .boundingRect
                |> Maybe.Extra.join
                |> Maybe.map .left

        networkSpacing =
            50

        networkIndex =
            State.networksByName state
                |> List.reverse
                |> List.Extra.elemIndex network
    in
    case ( firstSwitchX, networkIndex ) of
        ( Just switchX, Just index ) ->
            let
                axisOffset =
                    -- Add 2 to index so rightmost network axis is offset from
                    -- switches and adapters by twice usual offset; looks
                    -- slightly nicer with some space between rack edge and
                    -- network axes.
                    ((index + 2) * networkSpacing) |> toFloat
            in
            Just <| switchX - axisOffset

        _ ->
            Nothing
