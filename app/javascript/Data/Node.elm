module Data.Node exposing (Node, decoder)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Node =
    Asset
        { serverId : Int
        , groupId : Int
        }


decoder : D.Decoder Node
decoder =
    Asset.decoder create
        |> P.required "server_id" D.int
        |> P.required "group_id" D.int


create id name serverId groupId =
    { id = id
    , name = name
    , serverId = serverId
    , groupId = groupId
    }
