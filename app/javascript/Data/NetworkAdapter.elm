module Data.NetworkAdapter exposing (Id, IdTag, NetworkAdapter, decoder)

import Data.Asset as Asset
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Server as Server
import Geometry.BoundingRect exposing (HasBoundingRect)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkAdapter =
    HasBoundingRect (PhysicalAsset IdTag { serverId : Server.Id })


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder NetworkAdapter
decoder =
    PhysicalAsset.decoder create
        |> P.required "server_id" Asset.idDecoder


create : Id -> String -> D.Value -> String -> String -> Server.Id -> NetworkAdapter
create id name data manufacturer model serverId =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    , manufacturer = manufacturer
    , model = model
    , serverId = serverId
    , boundingRect = Nothing
    }
