module Test.Compiler.ServerMock (settings, setupSrv) where

import Prelude (Unit, ($), (==), (>>=), (<<<), unit, pure, bind, const, discard)
import Control.Apply ((*>))
import Control.Monad.Error.Class (throwError, liftMaybe)
import Control.Monad.Reader.Trans (ReaderT, ask, runReaderT)
import Control.Monad.Trans.Class (lift)
import Data.Argonaut.Core (Json, stringify)
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
import Effect
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Effect.Exception (Error, error)
import HTTPure.Request (Request)
import HTTPure.Response (ResponseM, Response, ok)
import HTTPure.Server (serve)
import HTTPure.Lookup ((!!))
import HTTPure.Method (Method(Post))
import HTTPure.Body (class Body)
import HTTPure.Headers (header)
import Node.Stream.Aff (write, end, fromStringUTF8)
import Node.HTTP (responseAsStream)
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

newtype Json_ = Json_ Json

derive instance Newtype Json_ _
   
instance Body Json_ where
   defaultHeaders _ = pure $ header "Content-Type" "application/json"
   write json res = do
      let stream = responseAsStream res
      body' <- liftEffect $ fromStringUTF8 $ stringify $ unwrap $ json
      write stream body'
      end stream

type ServerMock = ReaderT Code (ReaderT Request Aff)

askRes :: ServerMock Code
askRes = ask

askReq :: ServerMock Request
askReq = lift ask

settings :: Settings
settings = { protocol: "http"
           , hostname: "localhost"
           , port: 3000
           , parser: successFromJson_
           }

validatePath :: ServerMock Unit
validatePath = do
   let invalidPath = error "invalid path"
       missingPath = error "missing path"
   req <- askReq
   p <- liftMaybe missingPath $ req.path !! 0
   case p == "compile" of
        true -> pure unit
        false -> throwError invalidPath 

validateMethod :: ServerMock Unit
validateMethod = askReq >>= case _ of
   { method: Post } -> pure unit
   _ -> throwError $ error "invalid method"

validate :: ServerMock Unit
validate = validatePath *> validateMethod

answer :: ServerMock Response
answer = do
   res <- askRes
   let json :: Json_
       json = wrap $ successToJson { js: res, warnings: Nothing }
   ok json

runServerMock :: Code -> Request -> ResponseM
runServerMock res req = runReaderT (runReaderT (validate *> answer) res) req

launchServerMock :: Code -> Aff (Effect Unit)
launchServerMock res = do
  close <- liftEffect $ serve settings.port (\req -> runServerMock res req) $ pure unit
  pure $ close $ pure unit

setupSrv :: forall b. Code -> Aff b -> Aff b
setupSrv code act = bracket (launchServerMock code) liftEffect (const act)
