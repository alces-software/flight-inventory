module Data.Group exposing (..)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D


type alias Group =
    Asset IdTag {}


type alias Id =
    Asset.Id IdTag


type IdTag
    = IdTag


decoder : D.Decoder Group
decoder =
    Asset.decoder Asset.create
