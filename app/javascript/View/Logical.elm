module View.Logical
    exposing
        ( gendersLayout
        , groupedElements
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


groupsLayout : State -> Html Msg
groupsLayout state =
    let
        groups =
            TaggedDict.values state.groups
    in
    div []
        (List.map (groupView state) groups)


gendersLayout : State -> Html Msg
gendersLayout state =
    let
        nodesByGender =
            TaggedDict.values state.nodes
                |> Node.nodesByGender
    in
    div []
        (Dict.map genderNodesView nodesByGender
            |> Dict.values
        )


groupView : State -> Group -> Html Msg
groupView state group =
    let
        nodes =
            State.groupNodesByName state group
    in
    groupedElements group (List.map nodeView nodes)


nodeView : Node -> Html Msg
nodeView node =
    div
        [ class "node"
        , title "Node"

        -- Picked up by Flipping JS library for animations.
        , attribute "data-flip-key" node.name
        ]
        [ View.Utils.assetHitBox <| State.NodeId node.id
        , text node.name
        ]


groupedElements : Group -> List (Html Msg) -> Html Msg
groupedElements group children =
    let
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
                , children
                ]
    in
    div
        [ class "group"
        , style [ ( "border-color", groupColour ) ]
        , title ("Group: " ++ group.name)
        ]
        groupChildren


genderNodesView : Node.GenderName -> List Node -> Html Msg
genderNodesView gender nodes =
    -- XXX DRY up with above.
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
            :: List.map nodeView nodes
        )
