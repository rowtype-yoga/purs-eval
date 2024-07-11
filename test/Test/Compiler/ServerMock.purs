module Test.Compiler.ServerMock (settings, setupSrv) where

import Prelude (Unit, ($), (<<<), unit, pure, bind, const)
import Data.Argonaut.Core (Json)
import Data.Argonaut.Decode (JsonDecodeError, printJsonDecodeError)
import Data.Argonaut.Decode.Class (class DecodeJson, decodeJson)
import Data.Argonaut.Decode.Generic (genericDecodeJson)
import Data.Argonaut.Encode.Class (class EncodeJson, encodeJson)
import Data.Argonaut.Encode.Generic (genericEncodeJson)
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Data.Functor ((<$>))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(Nothing))
import Data.Newtype (class Newtype, unwrap, wrap)
import Node.HTTP.Types (ServerResponse)
import Effect (Effect)
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Effect.Exception (Error, error)
import HTTPurple (RouteDuplex', Method(Post), (/), ResponseHeaders, noArgs, mkRoute, serve, ok, notFound, toJson)
import HTTPurple.Json.Argonaut (jsonEncoder)
import Compiler (Settings, Code, SuccessResult)


newtype SuccessResult_ = SuccessResult_ SuccessResult

derive instance Generic SuccessResult_ _

derive instance Newtype SuccessResult_ _

instance EncodeJson SuccessResult_ where
   encodeJson = genericEncodeJson

instance DecodeJson SuccessResult_ where
   decodeJson = genericDecodeJson

successToJson :: SuccessResult -> Json
successToJson = (encodeJson :: SuccessResult_ -> Json) <<< wrap

successFromJson_ :: Json -> Either Error SuccessResult
successFromJson_ json = unwrap <$> (error <<< printJsonDecodeError) `lmap` (decodeJson json :: Either JsonDecodeError SuccessResult_)

settings :: Settings
settings = { protocol: "http"
           , hostname: "localhost"
           , port: 3000
           , parser: successFromJson_
           }

data Route = Compile

derive instance Generic Route _

route :: RouteDuplex' Route
route = mkRoute
  { "Compile": "compile" / noArgs
  }


mkRouter
   :: forall a. 
      String
   -> { method :: Method, route :: Route | a }
   -> Aff { headers :: ResponseHeaders, status :: Int , writeBody :: ServerResponse -> Aff Unit }
mkRouter js  = case _ of
   { route: Compile, method: Post } ->  ok $ toJson jsonEncoder $ successToJson { js, warnings: Nothing }
   _ -> notFound

launchServerMock :: Code -> Aff (Effect Unit)
launchServerMock c = liftEffect do
   let router = mkRouter c 
   close <- serve { port: settings.port } { route, router }
   pure $ close $ pure unit

setupSrv :: forall b. Code -> Aff b -> Aff b
setupSrv code act = bracket (launchServerMock code) liftEffect (const act)
