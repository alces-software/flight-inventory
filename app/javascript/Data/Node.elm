module Data.Node
    exposing
        ( GenderName
        , Id
        , IdTag
        , Node
        , decoder
        , nodesByGender
        )

import Data.Asset as Asset exposing (Asset)
import Data.Group as Group
import Data.Server as Server
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Node =
    Asset IdTag
        { serverId : Server.Id
        , groupId : Group.Id

        -- Genders have a many-to-many relationship with Nodes, and only have a
        -- single interesting property, `name`, which also uniquely identifies
        -- that Gender within a domain. Therefore rather than have to do a
        -- double join to get the Gender names associated with a Node we just
        -- nest these here.
        , genders : List GenderName
        }


type alias GenderName =
    -- Provides no type safety, but at least gives an indication of what we
    -- mean in functions which work with gender name Strings.
    String


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Node
decoder =
    Asset.decoder create
        |> P.required "server_id" Asset.idDecoder
        |> P.required "group_id" Asset.idDecoder
        |> P.required "genders" (D.list D.string)


create :
    Id
    -> String
    -> D.Value
    -> Server.Id
    -> Group.Id
    -> List String
    -> Node
create id name data serverId groupId genders =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    , serverId = serverId
    , groupId = groupId
    , genders = genders
    }


nodesByGender : List Node -> GendersDict
nodesByGender nodes =
    let
        genderNodePairs : List ( GenderName, Node )
        genderNodePairs =
            List.concatMap
                (\n -> List.map (\g -> ( g, n )) n.genders)
                nodes

        collateNodeGenders : ( GenderName, Node ) -> GendersDict -> GendersDict
        collateNodeGenders ( gender, node ) gendersDict =
            let
                newNodeList =
                    [ node ]

                updateNodesForGender =
                    \maybeNodeList ->
                        Just <|
                            case maybeNodeList of
                                Just nodeList ->
                                    List.concat [ nodeList, newNodeList ]

                                Nothing ->
                                    newNodeList
            in
            Dict.update gender updateNodesForGender gendersDict
    in
    List.foldl collateNodeGenders Dict.empty genderNodePairs


type alias GendersDict =
    Dict GenderName (List Node)
