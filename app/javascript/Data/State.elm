module Data.State
    exposing
        ( AppLayout(..)
        , SelectableAssetId(..)
        , State
        , chassisByName
        , chassisPsusByName
        , chassisServersByName
        , connectionForPort
        , decoder
        , denormalizedConnectionsForNetwork
        , groupNodesByName
        , networksByName
        , networksConnectedToNode
        , networksConnectedToSwitch
        , portsForAdapter
        , selectedAssetData
        , selectedAssetDescription
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
import Data.Oob as Oob exposing (Oob)
import Data.PhysicalAsset as PhysicalAsset
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
    { clusterName : String
    , chassis : TaggedDict Chassis.IdTag Int Chassis
    , servers : TaggedDict Server.IdTag Int Server
    , psus : TaggedDict Psu.IdTag Int Psu
    , networkAdapters : TaggedDict NetworkAdapter.IdTag Int NetworkAdapter
    , networkAdapterPorts : TaggedDict NetworkAdapterPort.IdTag Int NetworkAdapterPort

    -- XXX Use (Tagged) Set for NetworkConnections, don't care about IDs?
    , networkConnections : Dict Int NetworkConnection
    , networks : TaggedDict Network.IdTag Int Network
    , networkSwitches : TaggedDict NetworkSwitch.IdTag Int NetworkSwitch
    , oobs : TaggedDict Oob.IdTag Int Oob
    , nodes : TaggedDict Node.IdTag Int Node
    , groups : TaggedDict Group.IdTag Int Group
    , dataJsonTreeState : JsonTree.State
    , selectedAssetId : Maybe SelectableAssetId
    , layout : AppLayout
    }


type SelectableAssetId
    = NetworkSwitchId NetworkSwitch.Id
    | ChassisId Chassis.Id
    | ServerId Server.Id
    | NetworkAdapterId NetworkAdapter.Id
    | OobId Oob.Id
    | PsuId Psu.Id
    | GroupId Group.Id
    | NodeId Node.Id


type AppLayout
    = Physical
    | LogicalInGroups
    | LogicalInGenders


decoder : D.Decoder State
decoder =
    P.decode State
        |> P.required "nodes" clusterNameDecoder
        |> P.required "chassis" (taggedAssetDictDecoder Chassis.decoder)
        |> P.required "servers" (taggedAssetDictDecoder Server.decoder)
        |> P.required "psus" (taggedAssetDictDecoder Psu.decoder)
        |> P.required "networkAdapters" (taggedAssetDictDecoder NetworkAdapter.decoder)
        |> P.required "networkAdapterPorts" (taggedAssetDictDecoder NetworkAdapterPort.decoder)
        |> P.required "networkConnections" (assetDictDecoder NetworkConnection.decoder)
        |> P.required "networks" (taggedAssetDictDecoder Network.decoder)
        |> P.required "networkSwitches" (taggedAssetDictDecoder NetworkSwitch.decoder)
        |> P.required "oobs" (taggedAssetDictDecoder Oob.decoder)
        |> P.required "nodes" (taggedAssetDictDecoder Node.decoder)
        |> P.required "groups" (taggedAssetDictDecoder Group.decoder)
        |> P.hardcoded JsonTree.defaultState
        |> P.hardcoded Nothing
        |> P.hardcoded Physical


clusterNameDecoder : D.Decoder String
clusterNameDecoder =
    -- Get the answer to the `cluster_name` question for the first Node and
    -- save this as the Cluster name.
    -- XXX This is likely to be quite brittle: requires us to have at least 1
    -- Node (will probably always be the case though) and that this Node has an
    -- answer to this question. Would probably be more robust/Metalware-y to
    -- use the rendered value for `config.cluster_name` instead, since this is
    -- more likely to exist; ideally we would store and import `cluster_name`
    -- independently of a particular Node (maybe using `metal view
    -- domain.config.cluster_name`, this does not give correct value with
    -- current Cluster though).
    D.index 0
        (D.at
            [ "data", "answer", "cluster_name" ]
            D.string
        )


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


groupNodesByName : State -> Group -> List Node
groupNodesByName state group =
    TaggedDict.filter
        (\_ node -> node.groupId == group.id)
        state.nodes
        |> nameOrderedValues


nameOrderedValues : TaggedDict idTag comparable (Asset idTag a) -> List (Asset idTag a)
nameOrderedValues dict =
    TaggedDict.values dict |> List.sortBy .name


networksConnectedToSwitch : State -> NetworkSwitch -> List Network
networksConnectedToSwitch state switch =
    connectedNetworks state (.networkSwitchId >> (==) switch.id)


networksConnectedToNode : State -> Node -> List Network
networksConnectedToNode state node =
    let
        isNodeConnection =
            .nodeId
                >> Maybe.map ((==) node.id)
                >> Maybe.withDefault False
    in
    connectedNetworks state isNodeConnection


connectedNetworks : State -> (NetworkConnection -> Bool) -> List Network
connectedNetworks state isMatchingConnection =
    Dict.values state.networkConnections
        |> List.filter isMatchingConnection
        |> List.map .networkId
        |> Asset.uniqueIds
        |> List.map (flip TaggedDict.get state.networks)
        |> Maybe.Extra.values
        -- Sort networks by name so always drawn in consistent order.
        |> List.sortBy .name


selectedAssetData : State -> Maybe D.Value
selectedAssetData state =
    -- XXX You'd think there'd be a DRYer way to write this, and similar for
    -- below, but I can't seem to figure out how to do this.
    transformSelectedAsset state
        (\id ->
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

                OobId oobId ->
                    TaggedDict.get oobId state.oobs
                        |> Maybe.map .data

                PsuId psuId ->
                    TaggedDict.get psuId state.psus
                        |> Maybe.map .data

                GroupId groupId ->
                    TaggedDict.get groupId state.groups
                        |> Maybe.map .data

                NodeId nodeId ->
                    TaggedDict.get nodeId state.nodes
                        |> Maybe.map .data
        )


selectedAssetDescription : State -> Maybe String
selectedAssetDescription state =
    transformSelectedAsset state
        (\id ->
            case id of
                NetworkSwitchId switchId ->
                    let
                        switch =
                            TaggedDict.get switchId state.networkSwitches
                    in
                    Maybe.map
                        (PhysicalAsset.description "network switch")
                        switch

                ChassisId chassisId ->
                    let
                        chassis =
                            TaggedDict.get chassisId state.chassis
                    in
                    Maybe.map
                        (PhysicalAsset.description "chassis")
                        chassis

                ServerId serverId ->
                    let
                        server =
                            TaggedDict.get serverId state.servers
                    in
                    Maybe.map
                        (PhysicalAsset.description "server")
                        server

                NetworkAdapterId adapterId ->
                    let
                        adapter =
                            TaggedDict.get adapterId state.networkAdapters
                    in
                    Maybe.map
                        (PhysicalAsset.description "network adapter")
                        adapter

                OobId oobId ->
                    -- XXX Get the asset this is the OOB for and display this;
                    -- this is slightly complex as will need to go through
                    -- every group of assets which could have an OOB and see if
                    -- this is referenced by one of them. Alternatively, maybe
                    -- we should pass the asset ID rather than the OOB ID when
                    -- an OOB is selected, as it is much simpler to find the
                    -- OOB given an asset rather than the other way round -
                    -- maybe should change type to `type SelectableAssetId =
                    -- ... | OobId {a | oobId = Oob.Id}`? This would also make
                    -- things more robust to new assets with OOBs being added.
                    Just "OOB"

                PsuId psuId ->
                    let
                        psu =
                            TaggedDict.get psuId state.psus
                    in
                    Maybe.map
                        (PhysicalAsset.description "PSU")
                        psu

                GroupId groupId ->
                    let
                        group =
                            TaggedDict.get groupId state.groups
                    in
                    Maybe.map (\g -> "Group: " ++ g.name) group

                NodeId nodeId ->
                    let
                        node =
                            TaggedDict.get nodeId state.nodes
                    in
                    Maybe.map (\n -> "Node: " ++ n.name) node
        )


transformSelectedAsset : State -> (SelectableAssetId -> Maybe a) -> Maybe a
transformSelectedAsset state transform =
    Maybe.map transform state.selectedAssetId
        |> Maybe.Extra.join


denormalizedConnectionsForNetwork : State -> Network -> List NetworkConnection.Denormalized
denormalizedConnectionsForNetwork state network =
    Dict.values state.networkConnections
        |> List.filter (\nc -> nc.networkId == network.id)
        |> List.map (denormalizeNetworkConnection state)
        |> Maybe.Extra.values


denormalizeNetworkConnection : State -> NetworkConnection -> Maybe NetworkConnection.Denormalized
denormalizeNetworkConnection state connection =
    let
        adapterPort =
            TaggedDict.get
                connection.networkAdapterPortId
                state.networkAdapterPorts

        adapter =
            Maybe.map
                (.networkAdapterId
                    >> flip TaggedDict.get state.networkAdapters
                )
                adapterPort
                |> Maybe.Extra.join

        switch =
            TaggedDict.get
                connection.networkSwitchId
                state.networkSwitches

        node =
            Maybe.map (flip TaggedDict.get state.nodes)
                connection.nodeId
                |> Maybe.Extra.join
    in
    case ( adapterPort, adapter, switch ) of
        ( Just adapterPort_, Just adapter_, Just switch_ ) ->
            Just
                { networkAdapterPort = adapterPort_
                , networkAdapter = adapter_
                , networkSwitch = switch_
                , node = node
                }

        _ ->
            Nothing
