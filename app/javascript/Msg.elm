module Msg exposing (..)

import Data.State as State
import Json.Encode as E
import JsonTree


type Msg
    = InboundPortData ( String, E.Value )
    | SelectAsset State.SelectableAssetId
    | SetDataJsonTreeState JsonTree.State
    | SetAppLayout State.AppLayout
