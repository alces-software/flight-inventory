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


create : Id -> String -> D.Value -> String -> String -> NetworkSwitch
create id name data manufacturer model =
    -- Note: Have to define own constructor function here as extensible records
    -- do not currently define their own constructor with their alias name (see
    -- https://stackoverflow.com/a/47876225/2620402).
    { id = id
    , name = name
    , data = data
    , manufacturer = manufacturer
    , model = model
    , boundingRect = Nothing
    }
