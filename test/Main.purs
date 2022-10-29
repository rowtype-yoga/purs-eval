module Test.Main where

import Prelude (Unit, ($), unit, pure, bind, const)
import Effect
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import HTTPure.Response (ok)
import HTTPure.Server (serve)
import HTTPure.Body (class Body)
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.Assert (equal)
import Main (compile)

mockSrv :: forall a. Body a => a -> Aff (Effect Unit)
mockSrv res = do
  close <- liftEffect $ serve 3000 (const $ ok res) $ pure unit
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
