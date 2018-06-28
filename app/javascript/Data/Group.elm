module Data.Group exposing (..)

import Data.Asset as Asset exposing (Asset)
import Json.Decode as D
import Json.Decode.Pipeline as P


type alias Group =
    Asset {}


decoder : D.Decoder Group
decoder =
    Asset.decoder Asset.create
