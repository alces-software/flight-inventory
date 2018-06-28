module Data.State
    exposing
        ( State
        , adapterHeight
        , adapterPortPosition
        , decoder
        )

import Data.Chassis as Chassis exposing (Chassis)
import Data.Group as Group exposing (Group)
import Data.Network as Network exposing (Network)
import Data.NetworkAdapter as NetworkAdapter exposing (NetworkAdapter)
import Data.NetworkAdapterPort as NetworkAdapterPort exposing (NetworkAdapterPort)
import Data.NetworkConnection as NetworkConnection exposing (NetworkConnection)
import Data.NetworkSwitch as NetworkSwitch exposing (NetworkSwitch)
import Data.Node as Node exposing (Node)
import Data.Psu as Psu exposing (Psu)
import Data.Server as Server exposing (Server)
import Dict exposing (Dict)
import Geometry.Point exposing (Point)
import Json.Decode as D
import Json.Decode.Pipeline as P
import List.Extra
import Maybe.Extra


type alias State =
    { chassis : Dict Int Chassis
    , servers : Dict Int Server
    , psus : Dict Int Psu
    , networkAdapters : Dict Int NetworkAdapter
    , networkAdapterPorts : Dict Int NetworkAdapterPort
    , networkConnections : Dict Int NetworkConnection
    , networks : Dict Int Network
    , networkSwitches : Dict Int NetworkSwitch
    , nodes : Dict Int Node
    , groups : Dict Int Group
    }


decoder : D.Decoder State
decoder =
    P.decode State
        |> P.required "chassis" (assetDictDecoder Chassis.decoder)
        |> P.required "servers" (assetDictDecoder Server.decoder)
        |> P.required "psus" (assetDictDecoder Psu.decoder)
        |> P.required "networkAdapters" (assetDictDecoder NetworkAdapter.decoder)
        |> P.required "networkAdapterPorts" (assetDictDecoder NetworkAdapterPort.decoder)
        |> P.required "networkConnections" (assetDictDecoder NetworkConnection.decoder)
        |> P.required "networks" (assetDictDecoder Network.decoder)
        |> P.required "networkSwitches" (assetDictDecoder NetworkSwitch.decoder)
        |> P.required "nodes" (assetDictDecoder Node.decoder)
        |> P.required "groups" (assetDictDecoder Group.decoder)


assetDictDecoder : D.Decoder asset -> D.Decoder (Dict Int asset)
assetDictDecoder assetDecoder =
    D.list
        (D.map2 (,)
            (D.field "id" D.int)
            assetDecoder
        )
        |> D.map Dict.fromList


adapterHeight : State -> Int
adapterHeight state =
    let
        maxAdapterConnections =
            Dict.values state.networkAdapters
                |> List.map numberConnectionsForAdapter
                |> List.maximum
                |> Maybe.withDefault 0

        numberConnectionsForAdapter =
            portsForAdapter state
                >> List.map (connectionForPort state)
                >> Maybe.Extra.values
                >> List.length

        pixelsPerConnection =
            20
    in
    maxAdapterConnections * pixelsPerConnection


adapterPortPosition : State -> NetworkAdapterPort -> Maybe Point
adapterPortPosition state adapterPort =
    let
        adapter =
            Dict.get adapterPort.networkAdapterId state.networkAdapters

        interfaceOrderedPorts =
            Maybe.map
                (portsForAdapter state >> List.sortBy .interface)
                adapter

        interfaceOrderedConnections =
            Maybe.map
                (List.map (connectionForPort state) >> Maybe.Extra.values)
                interfaceOrderedPorts

        portConnection =
            connectionForPort state adapterPort

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


portsForAdapter : State -> NetworkAdapter -> List NetworkAdapterPort
portsForAdapter state adapter =
    Dict.values state.networkAdapterPorts
        |> List.filter (\p -> p.networkAdapterId == adapter.id)


connectionForPort : State -> NetworkAdapterPort -> Maybe NetworkConnection
connectionForPort state port_ =
    Dict.values state.networkConnections
        |> List.Extra.find (\c -> c.networkAdapterPortId == port_.id)
