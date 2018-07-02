module Data.NetworkSwitch exposing (Id, IdTag, NetworkSwitch, decoder)

import Data.Asset as Asset
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Geometry.BoundingRect exposing (HasBoundingRect)
import Json.Decode as D


type alias NetworkSwitch =
    HasBoundingRect (PhysicalAsset IdTag {})


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder NetworkSwitch
decoder =
    PhysicalAsset.decoder create


create : Id -> String -> String -> String -> NetworkSwitch
create id name manufacturer model =
    { id = id
    , name = name
    , manufacturer = manufacturer
    , model = model
    , boundingRect = Nothing
    }
