module Data.NetworkAdapter exposing (Id, IdTag, NetworkAdapter, decoder)

import Data.Asset as Asset
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Server as Server
import Geometry.BoundingRect as BoundingRect exposing (BoundingRect)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkAdapter =
    PhysicalAsset IdTag
        { serverId : Server.Id
        , boundingRect : Maybe BoundingRect
        }


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder NetworkAdapter
decoder =
    PhysicalAsset.decoder create
        |> P.required "server_id" Asset.idDecoder


create : Id -> String -> String -> String -> Server.Id -> NetworkAdapter
create id name manufacturer model serverId =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , serverId = serverId
    , boundingRect = Nothing
    }
