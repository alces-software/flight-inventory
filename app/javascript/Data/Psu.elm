module Data.Psu exposing (..)

import Data.PhysicalAsset as PhysicalAsset exposing (PhysicalAsset)
import Data.Server as Server
import Json.Decode as D


type alias Psu =
    PhysicalAsset
        { chassisId : Int
        }


decoder : D.Decoder Psu
decoder =
    -- XXX PSU data is identical to Server data currently, so can just alias.
    Server.decoder
