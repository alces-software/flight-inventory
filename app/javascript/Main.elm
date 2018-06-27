port module Main exposing (..)

import Dict exposing (Dict)
import Hashbow
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
import List.Extra
import Maybe.Extra
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
        | id : Int
        , name : String
    }


type alias PhysicalAsset a =
    Asset
        { a
            | manufacturer : String
            , model : String
        }


physicalAsset id name manufacturer model =
    -- Note: Have to define own constructor function here, and in similar
    -- places below, as extensible records do not currently define their own
    -- constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
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


server id name manufacturer model chassisId =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , chassisId = chassisId
    }


type alias NetworkAdapter =
    PhysicalAsset
        { serverId : Int
        , boundingRect : Maybe BoundingRect
        }


networkAdapter id name manufacturer model serverId =
    { id = id
    , name = name
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
    , width : Float
    , height : Float
    }


boundingRectDecoder : D.Decoder BoundingRect
boundingRectDecoder =
    P.decode BoundingRect
        |> P.required "top" D.float
        |> P.required "bottom" D.float
        |> P.required "left" D.float
        |> P.required "right" D.float
        |> P.required "width" D.float
        |> P.required "height" D.float


boundingRectLeftMiddlePoint : BoundingRect -> Point
boundingRectLeftMiddlePoint rect =
    let
        x =
            rect.left

        y =
            rect.top + (rect.height / 2)
    in
    { x = x, y = y }


type alias Point =
    { x : Float, y : Float }


type alias Line =
    { start : Point
    , end : Point
    , width : Int
    }


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


network id name cableColour =
    { id = id
    , name = name
    , cableColour = cableColour
    }


type alias NetworkSwitch =
    PhysicalAsset
        { boundingRect : Maybe BoundingRect
        }


networkSwitch id name manufacturer model =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , boundingRect = Nothing
    }


type alias Psu =
    PhysicalAsset
        { chassisId : Int
        }


type alias Node =
    Asset
        { serverId : Int
        , groupId : Int
        }


nodeConstructor id name serverId groupId =
    -- XXX Cannot call this `node` as this conflicts with `Html.node`.
    { id = id
    , name = name
    , serverId = serverId
    , groupId = groupId
    }


type alias Group =
    Asset {}


asset id name =
    { id = id
    , name = name
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
        |> P.required "id" D.int
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
    physicalAssetDecoder networkSwitch


nodeDecoder : D.Decoder Node
nodeDecoder =
    assetDecoder nodeConstructor
        |> P.required "server_id" D.int
        |> P.required "group_id" D.int


groupDecoder : D.Decoder Group
groupDecoder =
    assetDecoder asset



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
        [ assetTitle <| (fullModel switch ++ " switch")
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
            [ [ assetTitle <| (fullModel server ++ " server") ]
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
                [ "Network adapter:", fullModel adapter, adapter.name ]
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
        [ text (fullModel psu ++ " PSU") ]


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

        adapters =
            linkedAssets ports .networkAdapterId .networkAdapters

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
    drawNetworkAlongAxis xAxis network switches adapters


drawNetworkAlongAxis : Float -> Network -> List NetworkSwitch -> List NetworkAdapter -> List (Svg msg)
drawNetworkAlongAxis xAxis network switches adapters =
    let
        switchLines =
            linesForAssets trunkLineWidth switches

        adapterLines =
            linesForAssets regularLineWidth adapters

        linesForAssets =
            \width assetsWithRects ->
                List.map
                    (\start -> Line start (endPointFromStart start) width)
                    (startPointsForAssets assetsWithRects)

        startPointsForAssets =
            \assetsWithRects ->
                List.map
                    (.boundingRect >> Maybe.map boundingRectLeftMiddlePoint)
                    assetsWithRects
                    |> Maybe.Extra.values

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

                networkLabelPosition =
                    Point top.x (top.y - 20)

                networkLabel =
                    text_
                        [ x <| toString networkLabelPosition.x
                        , y <| toString networkLabelPosition.y
                        , Svg.Attributes.style <|
                            "fill: "
                                ++ network.cableColour
                                ++ "; font-size: 20px;"
                        ]
                        [ Svg.text network.name ]

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
            in
            networkLabel :: List.map drawLine allLines

        _ ->
            -- If we don't have a top and a bottom point then we can't have any
            -- points in the network at all, so nothing to draw.
            []



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
            { state
                | networkAdapters =
                    handlePositionsMessage state.networkAdapters data
            }

        "networkSwitchPositions" ->
            { state
                | networkSwitches =
                    handlePositionsMessage state.networkSwitches data
            }

        _ ->
            -- XXX Handle this better
            let
                log =
                    Debug.log "Don't know how to handle dataTag" dataTag
            in
            state


type alias WithBoundingRects a =
    Dict Int { a | boundingRect : Maybe BoundingRect }


handlePositionsMessage : WithBoundingRects a -> E.Value -> WithBoundingRects a
handlePositionsMessage currentAssets data =
    let
        decodedData =
            D.decodeValue positionsDecoder data
    in
    case decodedData of
        Ok adapterIdsToBoundingRects ->
            updateAssetBoundingRects currentAssets adapterIdsToBoundingRects

        Err message ->
            -- XXX Handle this better
            let
                log =
                    Debug.log "Got bad data from JS" message
            in
            currentAssets


positionsDecoder : D.Decoder (List ( Int, BoundingRect ))
positionsDecoder =
    D.list
        (D.map2
            (,)
            (D.index 0 D.int)
            (D.index 1 boundingRectDecoder)
        )


updateAssetBoundingRects : WithBoundingRects a -> List ( Int, BoundingRect ) -> WithBoundingRects a
updateAssetBoundingRects currentAssets assetIdsToNewRects =
    let
        assetsWithNewRects =
            -- Dict of asset IDs and assets with new bounding rects, where the
            -- asset both appears in the state and its ID is in the list passed
            -- (which currently should be all of them, but we can't guarantee what JS
            -- might send us).
            List.map
                (\( assetId, rect ) ->
                    let
                        currentAsset =
                            Dict.get assetId currentAssets
                    in
                    Maybe.map
                        (\asset ->
                            ( assetId, { asset | boundingRect = Just rect } )
                        )
                        currentAsset
                )
                assetIdsToNewRects
                |> Maybe.Extra.values
                |> Dict.fromList
    in
    Dict.intersect
        assetsWithNewRects
        currentAssets



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
