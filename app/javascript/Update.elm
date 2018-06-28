module Update exposing (updateState)

import Data.State as State exposing (State)
import Dict exposing (Dict)
import Geometry.BoundingRect as BoundingRect
    exposing
        ( BoundingRect
        , HasBoundingRect
        )
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra
import Msg exposing (Msg(..))


type alias WithBoundingRects a =
    Dict Int (HasBoundingRect a)


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
            (D.index 1 BoundingRect.decoder)
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
