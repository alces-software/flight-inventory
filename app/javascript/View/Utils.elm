module View.Utils exposing (..)

import Data.Asset exposing (Asset)
import Data.State as State
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Msg exposing (Msg(..))
import Tagged


{-| Attribute to display asset ID in DOM, to be picked up in JS.
-}
idAttribute : String -> Asset idTag a -> Html.Attribute msg
idAttribute dataAttr { id } =
    Tagged.untag id
        |> toString
        |> attribute dataAttr


assetHitBox : State.SelectableAssetId -> Html Msg
assetHitBox assetId =
    -- Each selectable asset displayed in the Cluster diagram has a hit box, an
    -- absolutely positioned div exactly covering the asset element's area. The
    -- `onClick` handler and corresponding styling is added to this rather than
    -- the asset element itself, as this avoids both the propagated click event
    -- also triggering parent asset `onClick` handlers, and the styling also
    -- being applied to the child asset elements.
    div
        [ class "asset-hit-box"
        , onClick <| SelectAsset assetId
        ]
        []
