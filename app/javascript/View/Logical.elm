module View.Logical
    exposing
        ( gendersLayout
        , groupsLayout
        , nodeView
        )

import Data.Group exposing (Group)
import Data.Node as Node exposing (Node)
import Data.State as State exposing (State)
import Dict
import Hashbow
import Html exposing (..)
import Html.Attributes exposing (..)
import Msg exposing (Msg(..))
import Tagged.Dict as TaggedDict exposing (TaggedDict)
import View.Utils
import View.ViewCache exposing (ViewCache)


groupsLayout : ViewCache -> State -> Html Msg
groupsLayout viewCache state =
    let
        groups =
            TaggedDict.values state.groups
    in
    div []
        (List.map (groupView viewCache state) groups)


gendersLayout : ViewCache -> State -> Html Msg
gendersLayout viewCache state =
    let
        nodesByGender =
            TaggedDict.values state.nodes
                |> Node.nodesByGender
    in
    div []
        (Dict.map (genderNodesView viewCache) nodesByGender
            |> Dict.values
        )


groupView : ViewCache -> State -> Group -> Html Msg
groupView viewCache state group =
    let
        nodes =
            State.groupNodesByName state group

        groupColour =
            Hashbow.hashbow group.name

        groupChildren =
            List.concat
                [ [ View.Utils.assetHitBox <| State.GroupId group.id
                  , strong
                        [ class "group-name"
                        , style [ ( "color", groupColour ) ]
                        ]
                        [ text group.name ]
                  ]
                , List.map (nodeView viewCache) nodes
                ]
    in
    div
        [ class "group"
        , style [ ( "border-color", groupColour ) ]
        , title ("Group: " ++ group.name)
        ]
        groupChildren


nodeView : ViewCache -> Node -> Html Msg
nodeView viewCache node =
    div
        [ class "node"
        , title "Node"
        , style [ ( "height", toString viewCache.nodeHeight ++ "px" ) ]
        , View.Utils.idAttribute "data-node-id" node

        -- Picked up by Flipping JS library for animations.
        , attribute "data-flip-key" node.name
        ]
        [ View.Utils.assetHitBox <| State.NodeId node.id
        , text node.name
        ]


genderNodesView : ViewCache -> Node.GenderName -> List Node -> Html Msg
genderNodesView viewCache gender nodes =
    -- XXX DRY up with `groupView`.
    let
        genderColour =
            Hashbow.hashbow gender
    in
    div
        [ class "group"
        , style [ ( "border-color", genderColour ) ]
        , title ("Gender: " ++ gender)
        ]
        (strong
            [ class "group-name"
            , style [ ( "color", genderColour ) ]
            ]
            [ text gender ]
            :: List.map (nodeView viewCache) nodes
        )
