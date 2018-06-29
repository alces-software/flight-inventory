module Data.Chassis exposing (..)

import Data.Asset as Asset
import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D


type alias Chassis =
    PhysicalAsset IdTag {}


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Chassis
decoder =
    PhysicalAsset.decoder PhysicalAsset.create
