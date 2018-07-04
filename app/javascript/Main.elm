module Main exposing (..)

import Data.State as State exposing (State)
import Html exposing (..)
import Json.Decode as D
import Msg exposing (Msg(..))
import Ports
import Update
import View


-- MODEL


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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.jsToElm InboundPortData



-- MAIN


main : Program D.Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
