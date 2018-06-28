module Data.NetworkAdapterPort exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P


type alias NetworkAdapterPort =
    { id : Int
    , interface : String
    , networkAdapterId : Int
    }


decoder : D.Decoder NetworkAdapterPort
decoder =
    P.decode NetworkAdapterPort
        |> P.required "id" D.int
        |> P.required "interface" D.string
        |> P.required "network_adapter_id" D.int
