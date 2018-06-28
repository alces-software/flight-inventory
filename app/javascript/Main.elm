port module Main exposing (..)

import Data.State as State exposing (State)
import Html exposing (..)
import Json.Decode as D
import Json.Encode as E
import Msg exposing (Msg(..))
import Update
import View


-- MODEL
-- XXX Use stricter types for IDs in all types, e.g. using
-- http://package.elm-lang.org/packages/joneshf/elm-tagged/latest.


type Model
    = Initialized State
    | Error String



-- INIT


init : D.Value -> ( Model, Cmd Msg )
init flags =
    let
        model =
            decodeInitialModel flags
    in
    model ! []


decodeInitialModel : D.Value -> Model
decodeInitialModel value =
    let
        result =
            D.decodeValue State.decoder value
    in
    case result of
        Ok state ->
            Initialized state

        Err message ->
            Error message



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Initialized state ->
            View.viewState state

        Error message ->
            span []
                [ text ("Error initializing app: " ++ message)
                ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case model of
        Initialized state ->
            let
                ( newState, cmd ) =
                    Update.updateState message state
            in
            ( Initialized newState, cmd )

        Error _ ->
            model ! []



-- PORTS


port jsToElm : (( String, E.Value ) -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    jsToElm InboundPortData



-- MAIN


main : Program D.Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
