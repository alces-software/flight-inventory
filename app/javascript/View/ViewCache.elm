module View.ViewCache exposing (..)

import Data.State exposing (State)
import Geometry.Networks


type alias ViewCache =
    { adapterHeight : Int
    }


init : State -> ViewCache
init state =
    -- We calculate these values needed in many places once up-front and then
    -- thread this record through as needed, rather than repeating this many
    -- times at point of use, since doing that is somewhat time consuming and
    -- noticeably slows things down.
    { adapterHeight = Geometry.Networks.adapterHeight state
    }
