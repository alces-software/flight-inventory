module Msg exposing (..)

import Json.Encode as E


type Msg
    = InboundPortData ( String, E.Value )
