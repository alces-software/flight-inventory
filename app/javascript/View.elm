module View exposing (viewState)

import Data.State as State exposing (AppLayout(..), State)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import JsonTree
import Msg exposing (Msg(..))
import View.Logical
import View.Physical
import View.SvgLayer as SvgLayer


viewState : State -> Html Msg
viewState state =
    div []
        [ SvgLayer.view state
        , htmlLayer state
        ]


htmlLayer : State -> Html Msg
htmlLayer state =
    div [ class "html-layer" ]
        [ selectedAssetInspector state
        , clusterDiagram state
        ]


selectedAssetInspector : State -> Html Msg
selectedAssetInspector state =
    let
        treeViewElements =
            case
                ( State.selectedAssetData state
                , State.selectedAssetDescription state
                )
            of
                ( Just data, Just description ) ->
                    case JsonTree.parseValue data of
                        Ok jsonNode ->
                            dataJsonTreeElements
                                state.dataJsonTreeState
                                jsonNode
                                description

                        Err message ->
                            -- XXX Handle this better?
                            [ span []
                                [ text <| "Error: " ++ message ]
                            ]

                _ ->
                    [ div
                        [ class "no-selection" ]
                        [ text "Select an asset to inspect" ]
                    ]
    in
    div [ class "selected-asset-inspector" ]
        treeViewElements


dataJsonTreeElements : JsonTree.State -> JsonTree.Node -> String -> List (Html Msg)
dataJsonTreeElements treeState treeNode assetDescription =
    [ h3
        [ class "tree-title" ]
        [ text assetDescription ]
    , JsonTree.view treeNode jsonTreeConfig treeState
    ]


jsonTreeConfig : JsonTree.Config Msg
jsonTreeConfig =
    { onSelect = Nothing
    , toMsg = SetDataJsonTreeState
    }


clusterDiagram : State -> Html Msg
clusterDiagram state =
    let
        controls =
            div
                [ class "app-controls" ]
                (switchLayoutButtons state)

        diagram =
            case state.layout of
                Physical ->
                    View.Physical.layout state

                LogicalInGroups ->
                    View.Logical.groupsLayout state

                LogicalInGenders ->
                    View.Logical.gendersLayout state
    in
    div
        [ class "cluster-diagram" ]
        [ controls
        , diagram
        ]


switchLayoutButtons : State -> List (Html Msg)
switchLayoutButtons state =
    let
        allLayoutsAndText =
            [ ( Physical, "Physical layout" )
            , ( LogicalInGroups, "Logical layout in groups" )
            , ( LogicalInGenders, "Logical layout in genders" )
            ]

        layoutsAndTextWithoutCurrent =
            List.filter
                (\( layout, _ ) -> layout /= state.layout)
                allLayoutsAndText

        layoutButton =
            \( layout, text_ ) ->
                button
                    [ onClick <| SetAppLayout layout ]
                    [ text text_ ]
    in
    List.map layoutButton layoutsAndTextWithoutCurrent
