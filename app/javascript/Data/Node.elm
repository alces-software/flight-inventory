module Data.Node exposing (Id, IdTag, Node, decoder)

import Data.Asset as Asset exposing (Asset)
import Data.Group as Group
import Data.Server as Server
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
        , genders : List String
        }


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
