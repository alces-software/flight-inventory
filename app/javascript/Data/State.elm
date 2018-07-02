module Data.State
    exposing
        ( SelectableAssetId(..)
        , State
        , chassisByName
        , chassisPsusByName
        , chassisServersByName
        , connectionForPort
        , decoder
        , networksByName
        , networksConnectedToSwitch
        , portsForAdapter
        , selectedAssetData
        , serverNetworkAdaptersByName
        , serverNodesByName
        , switchesByName
        )

import Data.Asset as Asset exposing (Asset)
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
import Json.Decode as D
import Json.Decode.Pipeline as P
import JsonTree
import List.Extra
import Maybe.Extra
import Tagged.Dict as TaggedDict exposing (TaggedDict)


type alias State =
    { chassis : TaggedDict Chassis.IdTag Int Chassis
    , servers : TaggedDict Server.IdTag Int Server
    , psus : TaggedDict Psu.IdTag Int Psu
    , networkAdapters : TaggedDict NetworkAdapter.IdTag Int NetworkAdapter
    , networkAdapterPorts : TaggedDict NetworkAdapterPort.IdTag Int NetworkAdapterPort

    -- XXX Use (Tagged) Set for NetworkConnections, don't care about IDs?
    , networkConnections : Dict Int NetworkConnection
    , networks : TaggedDict Network.IdTag Int Network
    , networkSwitches : TaggedDict NetworkSwitch.IdTag Int NetworkSwitch
    , nodes : TaggedDict Node.IdTag Int Node
    , groups : TaggedDict Group.IdTag Int Group
    , dataJsonTreeState : JsonTree.State
    , selectedAssetId : Maybe SelectableAssetId
    }


type SelectableAssetId
    = NetworkSwitchId NetworkSwitch.Id
    | ChassisId Chassis.Id
    | ServerId Server.Id
    | NetworkAdapterId NetworkAdapter.Id
    | PsuId Psu.Id
    | NodeId Node.Id


decoder : D.Decoder State
decoder =
    P.decode State
        |> P.required "chassis" (taggedAssetDictDecoder Chassis.decoder)
        |> P.required "servers" (taggedAssetDictDecoder Server.decoder)
        |> P.required "psus" (taggedAssetDictDecoder Psu.decoder)
        |> P.required "networkAdapters" (taggedAssetDictDecoder NetworkAdapter.decoder)
        |> P.required "networkAdapterPorts" (taggedAssetDictDecoder NetworkAdapterPort.decoder)
        |> P.required "networkConnections" (assetDictDecoder NetworkConnection.decoder)
        |> P.required "networks" (taggedAssetDictDecoder Network.decoder)
        |> P.required "networkSwitches" (taggedAssetDictDecoder NetworkSwitch.decoder)
        |> P.required "nodes" (taggedAssetDictDecoder Node.decoder)
        |> P.required "groups" (taggedAssetDictDecoder Group.decoder)
        |> P.hardcoded JsonTree.defaultState
        |> P.hardcoded Nothing


assetDictDecoder : D.Decoder asset -> D.Decoder (Dict Int asset)
assetDictDecoder assetDecoder =
    D.list
        (D.map2 (,)
            (D.field "id" D.int)
            assetDecoder
        )
        |> D.map Dict.fromList


taggedAssetDictDecoder : D.Decoder asset -> D.Decoder (TaggedDict idTag Int asset)
taggedAssetDictDecoder assetDecoder =
    D.list
        (D.map2 (,)
            (D.field "id" Asset.idDecoder)
            assetDecoder
        )
        |> D.map TaggedDict.fromList


portsForAdapter : State -> NetworkAdapter -> List NetworkAdapterPort
portsForAdapter state adapter =
    TaggedDict.values state.networkAdapterPorts
        |> List.filter (\p -> p.networkAdapterId == adapter.id)


connectionForPort : State -> NetworkAdapterPort -> Maybe NetworkConnection
connectionForPort state port_ =
    Dict.values state.networkConnections
        |> List.Extra.find (\c -> c.networkAdapterPortId == port_.id)


chassisByName : State -> List Chassis
chassisByName state =
    nameOrderedValues state.chassis


switchesByName : State -> List NetworkSwitch
switchesByName state =
    nameOrderedValues state.networkSwitches


networksByName : State -> List Network
networksByName state =
    nameOrderedValues state.networks


chassisServersByName : State -> Chassis -> List Server
chassisServersByName state chassis =
    TaggedDict.filter
        (\_ server -> server.chassisId == chassis.id)
        state.servers
        |> nameOrderedValues


chassisPsusByName : State -> Chassis -> List Psu
chassisPsusByName state chassis =
    TaggedDict.filter
        (\_ psu -> psu.chassisId == chassis.id)
        state.psus
        |> nameOrderedValues


serverNetworkAdaptersByName : State -> Server -> List NetworkAdapter
serverNetworkAdaptersByName state server =
    TaggedDict.filter
        (\_ adapter -> adapter.serverId == server.id)
        state.networkAdapters
        |> nameOrderedValues


serverNodesByName : State -> Server -> List Node
serverNodesByName state server =
    TaggedDict.filter
        (\_ node -> node.serverId == server.id)
        state.nodes
        |> nameOrderedValues


nameOrderedValues : TaggedDict idTag comparable (Asset idTag a) -> List (Asset idTag a)
nameOrderedValues dict =
    TaggedDict.values dict |> List.sortBy .name


networksConnectedToSwitch : State -> NetworkSwitch -> List Network
networksConnectedToSwitch state switch =
    Dict.values state.networkConnections
        |> List.filter (.networkSwitchId >> (==) switch.id)
        |> List.map .networkId
        |> Asset.uniqueIds
        |> List.map (flip TaggedDict.get state.networks)
        |> Maybe.Extra.values


selectedAssetData : State -> Maybe D.Value
selectedAssetData state =
    let
        dataFromId =
            \id ->
                case id of
                    NetworkSwitchId switchId ->
                        TaggedDict.get switchId state.networkSwitches
                            |> Maybe.map .data

                    ChassisId chassisId ->
                        TaggedDict.get chassisId state.chassis
                            |> Maybe.map .data

                    ServerId serverId ->
                        TaggedDict.get serverId state.servers
                            |> Maybe.map .data

                    NetworkAdapterId adapterId ->
                        TaggedDict.get adapterId state.networkAdapters
                            |> Maybe.map .data

                    PsuId psuId ->
                        TaggedDict.get psuId state.psus
                            |> Maybe.map .data

                    NodeId nodeId ->
                        TaggedDict.get nodeId state.nodes
                            |> Maybe.map .data
    in
    Maybe.map dataFromId state.selectedAssetId
        |> Maybe.Extra.join
