module Test.Main where

import Prelude (Unit, ($), (==), (>>=), unit, pure, bind, const)
import Control.Apply ((*>))
import Control.Monad.Error.Class (class MonadThrow, throwError, liftMaybe)
import Control.Monad.Reader.Trans (ReaderT, ask, runReaderT)
import Effect
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Effect.Exception (Error, error)
import HTTPure.Request (Request)
import HTTPure.Response (ok)
import HTTPure.Server (serve)
import HTTPure.Body (class Body)
import HTTPure.Lookup ((!!))
import HTTPure.Method (Method(Post))
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.Assert (equal)
import Main (compile)

type RequestValidator = ReaderT Request Aff Unit

validatePath :: RequestValidator
validatePath = do
   let invalidPath = error "invalid path"
       missingPath = error "missing path"
   req <- ask
   p <- liftMaybe missingPath $ req.path !! 0
   case p == "compile" of
        true -> pure unit
        false -> throwError invalidPath 

validateMethod :: RequestValidator
validateMethod = ask >>= case _ of
   { method: Post } -> pure unit
   _ -> throwError $ error "invalid method"

runReqValidator :: Request -> Aff Unit
runReqValidator req = runReaderT (validatePath *> validateMethod) req

mockSrv :: forall a. Body a => a -> Aff (Effect Unit)
mockSrv res = do
  close <- liftEffect $ serve 3000 (\req -> runReqValidator req *> ok res) $ pure unit
  pure $ close $ pure unit

setupSrv :: forall a b. Body a => a -> Aff b -> Aff b
setupSrv res act = bracket (mockSrv res) liftEffect (const act)

main :: Effect Unit
main = runTest do
  suite "compile" do
     test "produces expected output" do
        let expected = "2"
        actual <- setupSrv expected (compile "1+1")
        expected `equal` actual
