module Test.Main where

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
import HTTPure.Response (ok)
import HTTPure.Server (serve)
import HTTPure.Body (class Body)
import HTTPure.Lookup ((!!))
import HTTPure.Method (Method(Post))
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.Assert (equal)
import Main (Settings, Code, runCompiler)

type ServerMock = ReaderT Code (ReaderT Request Aff)

askCode :: ServerMock Code
askCode = ask

askReq :: ServerMock Request
askReq = lift ask

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

runServerMock :: Code -> Request -> Aff Unit
runServerMock res req = runReaderT (runReaderT (validatePath *> validateMethod) res) req

launchServerMock :: Code -> Aff (Effect Unit)
launchServerMock res = do
  close <- liftEffect $ serve settings.port (\req -> runServerMock res req *> ok res) $ pure unit
  pure $ close $ pure unit

setupSrv :: forall b. Code -> Aff b -> Aff b
setupSrv code act = bracket (launchServerMock code) liftEffect (const act)

main :: Effect Unit
main = runTest do
  suite "compile" do
     test "produces expected output" do
        let expected = "compiled-code"
            compile = runCompiler settings
        actual <- setupSrv expected (compile "code")
        expected `equal` actual
