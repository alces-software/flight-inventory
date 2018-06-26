port module Main exposing (..)

import Dict exposing (Dict)
import Hashbow
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
import Maybe.Extra


-- MODEL
-- XXX Use stricter types for IDs in all types, e.g. using
-- http://package.elm-lang.org/packages/joneshf/elm-tagged/latest.


type Model
    = Initialized State
    | Error String


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


type alias Asset a =
    { a
        | name : String
    }


type alias PhysicalAsset a =
    Asset
        { a
            | manufacturer : String
            , model : String
        }


physicalAsset name manufacturer model =
    -- Note: Have to define own constructor function here, and in similar
    -- places below, as extensible records do not currently define their own
    -- constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { name = name
    , manufacturer = manufacturer
    , model = model
    }


type alias Chassis =
    PhysicalAsset {}


chassis =
    physicalAsset


type alias Server =
    PhysicalAsset
        { chassisId : Int
        }


server name manufacturer model chassisId =
    { name = name
    , manufacturer = manufacturer
    , model = model
    , chassisId = chassisId
    }


type alias NetworkAdapter =
    PhysicalAsset
        { serverId : Int
        , boundingRect : Maybe BoundingRect
        }


networkAdapter name manufacturer model serverId =
    { name = name
    , manufacturer = manufacturer
    , model = model
    , serverId = serverId
    , boundingRect = Nothing
    }


type alias BoundingRect =
    { top : Float
    , bottom : Float
    , left : Float
    , right : Float
    }


boundingRectDecoder : D.Decoder BoundingRect
boundingRectDecoder =
    P.decode BoundingRect
        |> P.required "top" D.float
        |> P.required "bottom" D.float
        |> P.required "left" D.float
        |> P.required "right" D.float


type alias NetworkAdapterPort =
    { interface : String
    , networkAdapterId : Int
    }


type alias NetworkConnection =
    { networkId : Int
    , networkAdapterPortId : Int
    , networkSwitchId : Int
    }


type alias Network =
    Asset
        { cableColour : String
        }


network name cableColour =
    { name = name
    , cableColour = cableColour
    }


type alias NetworkSwitch =
    PhysicalAsset {}


type alias Psu =
    PhysicalAsset
        { chassisId : Int
        }


type alias Node =
    Asset
        { serverId : Int
        , groupId : Int
        }


nodeConstructor name serverId groupId =
    -- XXX Cannot call this `node` as this conflicts with `Html.node`.
    { name = name
    , serverId = serverId
    , groupId = groupId
    }


type alias Group =
    Asset {}


group name =
    { name = name
    }


fullModel : PhysicalAsset a -> String
fullModel { manufacturer, model } =
    String.join " " [ manufacturer, model ]



-- INIT


init : D.Value -> ( Model, Cmd Msg )
init flags =
    let
        model =
            decodeInitialModel flags
    in
    model ! []


decodeInitialModel : D.Value -> Model
decodeInitialModel value =
    let
        result =
            D.decodeValue stateDecoder value
    in
    case result of
        Ok state ->
            Initialized state

        Err message ->
            Error message


stateDecoder : D.Decoder State
stateDecoder =
    P.decode State
        |> P.required "chassis" (assetDictDecoder chassisDecoder)
        |> P.required "servers" (assetDictDecoder serverDecoder)
        |> P.required "psus" (assetDictDecoder psuDecoder)
        |> P.required "networkAdapters" (assetDictDecoder networkAdapterDecoder)
        |> P.required "networkAdapterPorts" (assetDictDecoder networkAdapterPortDecoder)
        |> P.required "networkConnections" (assetDictDecoder networkConnectionDecoder)
        |> P.required "networks" (assetDictDecoder networkDecoder)
        |> P.required "networkSwitches" (assetDictDecoder networkSwitchDecoder)
        |> P.required "nodes" (assetDictDecoder nodeDecoder)
        |> P.required "groups" (assetDictDecoder groupDecoder)


assetDictDecoder : D.Decoder asset -> D.Decoder (Dict Int asset)
assetDictDecoder assetDecoder =
    D.list
        (D.map2 (,)
            (D.field "id" D.int)
            assetDecoder
        )
        |> D.map Dict.fromList


physicalAssetDecoder constructor =
    assetDecoder constructor
        |> P.requiredAt [ "data", "manufacturer" ] D.string
        |> P.requiredAt [ "data", "model" ] D.string


assetDecoder constructor =
    P.decode constructor
        |> P.required "name" D.string


chassisDecoder : D.Decoder Chassis
chassisDecoder =
    physicalAssetDecoder chassis


serverDecoder : D.Decoder Server
serverDecoder =
    physicalAssetDecoder server
        |> P.required "chassis_id" D.int


psuDecoder =
    -- XXX PSU data is identical to Server data currently, so can just alias.
    serverDecoder


networkAdapterDecoder : D.Decoder NetworkAdapter
networkAdapterDecoder =
    physicalAssetDecoder networkAdapter
        |> P.required "server_id" D.int


networkAdapterPortDecoder : D.Decoder NetworkAdapterPort
networkAdapterPortDecoder =
    P.decode NetworkAdapterPort
        |> P.required "interface" D.string
        |> P.required "network_adapter_id" D.int


networkConnectionDecoder : D.Decoder NetworkConnection
networkConnectionDecoder =
    P.decode NetworkConnection
        |> P.required "network_id" D.int
        |> P.required "network_adapter_port_id" D.int
        |> P.required "network_switch_id" D.int


networkDecoder : D.Decoder Network
networkDecoder =
    assetDecoder network
        |> P.required "cable_colour" D.string


networkSwitchDecoder : D.Decoder NetworkSwitch
networkSwitchDecoder =
    -- XXX NetworkSwitch data is identical to Chassis data currently, so can
    -- just alias.
    chassisDecoder


nodeDecoder : D.Decoder Node
nodeDecoder =
    assetDecoder nodeConstructor
        |> P.required "server_id" D.int
        |> P.required "group_id" D.int


groupDecoder : D.Decoder Group
groupDecoder =
    assetDecoder group



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Initialized state ->
            stateView state

        Error message ->
            span []
                [ text ("Error initializing form: " ++ message)
                ]


stateView : State -> Html Msg
stateView state =
    let
        switches =
            Dict.values state.networkSwitches

        chassis =
            Dict.toList state.chassis
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
    div [ class "network-switch", title ("Network switch: " ++ switch.name) ]
        [ assetTitle <| (fullModel switch ++ " switch")
        ]


chassisView : State -> ( Int, Chassis ) -> Html Msg
chassisView state ( chassisId, chassis ) =
    let
        chassisServers =
            Dict.toList <|
                Dict.filter
                    (\serverId server -> server.chassisId == chassisId)
                    state.servers

        chassisPsus =
            Dict.toList <|
                Dict.filter
                    (\psuId psu -> psu.chassisId == chassisId)
                    state.psus
    in
    div [ class "chassis", title ("Chassis: " ++ chassis.name) ]
        (List.concat
            [ [ assetTitle <| (fullModel chassis ++ " chassis") ]
            , [ div
                    [ class "servers" ]
                    (List.map (serverView state) chassisServers)
              ]
            , [ div [ class "psus" ]
                    (List.map psuView chassisPsus)
              ]
            ]
        )


serverView : State -> ( Int, Server ) -> Html Msg
serverView state ( serverId, server ) =
    let
        serverNetworkAdapters =
            Dict.toList <|
                Dict.filter
                    (\adapterId adapter -> adapter.serverId == serverId)
                    state.networkAdapters

        serverNodes =
            Dict.toList <|
                Dict.filter
                    (\nodeId node -> node.serverId == serverId)
                    state.nodes
    in
    div [ class "server", title ("Server: " ++ server.name) ]
        (List.concat
            [ [ assetTitle <| (fullModel server ++ " server") ]
            , [ div [ class "network-adapters" ]
                    (List.map networkAdapterView serverNetworkAdapters)
              ]
            , [ div [ class "nodes" ]
                    (List.map (nodeView state) serverNodes)
              ]
            ]
        )


networkAdapterView : ( Int, NetworkAdapter ) -> Html Msg
networkAdapterView ( adapterId, adapter ) =
    div
        [ class "network-adapter"
        , attribute "data-network-adapter-id" (toString adapterId)
        , title <|
            String.join " "
                [ "Network adapter:", fullModel adapter, adapter.name ]
        ]
        [ text "N" ]


nodeView : State -> ( Int, Node ) -> Html Msg
nodeView state ( nodeId, node ) =
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


psuView : ( Int, Psu ) -> Html Msg
psuView ( psuId, psu ) =
    div [ class "psu", title <| "PSU: " ++ psu.name ]
        [ text (fullModel psu ++ " PSU") ]


assetTitle : String -> Html msg
assetTitle t =
    span [ class "title" ] [ text t ]



-- MESSAGE


type Msg
    = InboundPortData ( String, E.Value )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case model of
        Initialized state ->
            let
                ( newState, cmd ) =
                    updateState message state
            in
            ( Initialized newState, cmd )

        Error _ ->
            model ! []


updateState : Msg -> State -> ( State, Cmd Msg )
updateState message state =
    case message of
        InboundPortData ( dataTag, data ) ->
            handlePortData state dataTag data ! []


handlePortData : State -> String -> E.Value -> State
handlePortData state dataTag data =
    case dataTag of
        "networkAdapterPositions" ->
            let
                decodedData =
                    D.decodeValue positionsDecoder data
            in
            case decodedData of
                Ok adapterIdsToBoundingRects ->
                    updateNetworkAdapterBoundingRects state adapterIdsToBoundingRects

                Err message ->
                    -- XXX Handle this better
                    let
                        log =
                            Debug.log "Got bad data from JS" message
                    in
                    state

        _ ->
            -- XXX Handle this better
            let
                log =
                    Debug.log "Don't know how to handle dataTag" dataTag
            in
            state


positionsDecoder : D.Decoder (List ( Int, BoundingRect ))
positionsDecoder =
    D.list
        (D.map2
            (,)
            (D.index 0 D.int)
            (D.index 1 boundingRectDecoder)
        )


updateNetworkAdapterBoundingRects : State -> List ( Int, BoundingRect ) -> State
updateNetworkAdapterBoundingRects state adapterIdsToBoundingRects =
    let
        adapters =
            state.networkAdapters

        adaptersWithNewRects =
            -- Dict of NetworkAdapter IDs and NetworkAdapters with new bounding
            -- rects, where the adapter both appears in the state and its ID is
            -- in the list passed (which should be all of them, but we can't
            -- guarantee what JS might send us).
            List.map
                (\( adapterId, rect ) ->
                    let
                        currentAdapter =
                            Dict.get adapterId adapters

                        newAdapter =
                            Maybe.map
                                (\adapter ->
                                    { adapter | boundingRect = Just rect }
                                )
                                currentAdapter
                    in
                    Maybe.map
                        (\newAdapter_ -> ( adapterId, newAdapter_ ))
                        newAdapter
                )
                adapterIdsToBoundingRects
                |> Maybe.Extra.values
                |> Dict.fromList

        newAdapters =
            Dict.intersect
                adaptersWithNewRects
                adapters
    in
    { state | networkAdapters = newAdapters }



-- PORTS


port jsToElm : (( String, E.Value ) -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    jsToElm InboundPortData



-- MAIN


main : Program D.Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
