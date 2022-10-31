module Test.Compiler.ServerMock (settings, setupSrv) where

import Prelude (Unit, ($), (==), (>>=), unit, pure, bind, const)
import Control.Apply ((*>))
import Control.Monad.Error.Class (throwError, liftMaybe)
import Control.Monad.Reader.Trans (ReaderT, ask, runReaderT)
import Control.Monad.Trans.Class (lift)
import Effect
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import HTTPure.Request (Request)
import HTTPure.Response (ResponseM, Response, ok)
import HTTPure.Server (serve)
import HTTPure.Lookup ((!!))
import HTTPure.Method (Method(Post))
import Compiler (Settings, Code)

type ServerMock = ReaderT Code (ReaderT Request Aff)

askRes :: ServerMock Code
askRes = ask

askReq :: ServerMock Request
askReq = lift ask

liftAff :: forall a. Aff a -> ServerMock a
liftAff h = lift $ lift h

settings :: Settings
settings = { protocol: "http", hostname: "localhost", port: 3000 }

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
   liftAff $ ok res

runServerMock :: Code -> Request -> ResponseM
runServerMock res req = runReaderT (runReaderT (validate *> answer) res) req

launchServerMock :: Code -> Aff (Effect Unit)
launchServerMock res = do
  close <- liftEffect $ serve settings.port (\req -> runServerMock res req) $ pure unit
  pure $ close $ pure unit

setupSrv :: forall b. Code -> Aff b -> Aff b
setupSrv code act = bracket (launchServerMock code) liftEffect (const act)
