module Test.Main where

import Prelude (Unit, ($), (==), mempty, unit, pure, bind, const)
import Control.Bind ((>=>))
import Control.Apply ((*>))
import Control.Monad.Error.Class (class MonadThrow, throwError, liftMaybe)
import Effect
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Effect.Exception (Error, error)
import HTTPure.Request (Request)
import HTTPure.Response (ok)
import HTTPure.Server (serve)
import HTTPure.Body (class Body)
import HTTPure.Path (read)
import HTTPure.Lookup ((!!))
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.Assert (equal)
import Main (compile)

validateReq :: forall m. MonadThrow Error m => Request -> m Unit
validateReq req = do
   let invalidPath = error "invalid path"
       missingPath = error "missing path"
   p <- liftMaybe missingPath $ read req !! 0
   case p == "/compile" of
        true -> pure unit
        false -> throwError invalidPath 

mockSrv :: forall a. Body a => a -> Aff (Effect Unit)
mockSrv res = do
  close <- liftEffect $ serve 3000 (\req -> validateReq req *> ok res) $ pure unit
  pure $ close $ pure unit

setupSrv :: forall a b. Body a => a -> Aff b -> Aff b
setupSrv res act = bracket (mockSrv res) liftEffect (const act)

main :: Effect Unit
main = runTest do
  suite "compile" do
     test "produces expected output" do
        let expected = "2"
        actual <- setupSrv expected (compile "1+1")
        actual `equal` expected
