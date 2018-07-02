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


create : Id -> String -> D.Value -> Server.Id -> Group.Id -> Node
create id name data serverId groupId =
    { id = id
    , name = name
    , data = data
    , serverId = serverId
    , groupId = groupId
    }
