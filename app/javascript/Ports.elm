port module Ports exposing (..)

import Json.Encode as E


port jsToElm : (( String, E.Value ) -> msg) -> Sub msg


port animateSwitchLayout : () -> Cmd msg
