module Data.Chassis exposing (Chassis, decoder)

import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Chassis =
    PhysicalAsset {}


decoder : D.Decoder Chassis
decoder =
    PhysicalAsset.decoder PhysicalAsset.create
