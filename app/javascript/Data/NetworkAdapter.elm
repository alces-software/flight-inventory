module Data.NetworkAdapter exposing (NetworkAdapter, decoder)

import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Geometry.BoundingRect as BoundingRect exposing (BoundingRect)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkAdapter =
    PhysicalAsset
        { serverId : Int
        , boundingRect : Maybe BoundingRect
        }


decoder : D.Decoder NetworkAdapter
decoder =
    PhysicalAsset.decoder create
        |> P.required "server_id" D.int


create id name manufacturer model serverId =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , serverId = serverId
    , boundingRect = Nothing
    }
