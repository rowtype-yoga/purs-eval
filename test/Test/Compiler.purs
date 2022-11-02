module Test.Compiler (runTests) where

import Prelude (Unit, bind, discard, show)
import Data.Semigroup ((<>))
import Data.Foldable (foldMap)
import Data.Tuple (Tuple(Tuple))
import Effect (Effect)
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.Assert (equal)
import Test.Compiler.ServerMock (settings, setupSrv)
import Compiler (Code, runCompiler, appendMain)

mkImport :: String -> String -> Tuple Code Code
mkImport url mod = let
  impa     = "import * as " <> mod <> "from \""
  impb     = mod <> "/index.js\";"
  code     = impa <> "../" <> impb <> "\n"
  expected = impa <> url <> "/output/" <> impb <> "\n"
in Tuple code expected

runTests :: Effect Unit
runTests = runTest do
  suite "compile" do
    test "produces expected output" do
      let srv = "compiled-code"
          compile  = runCompiler settings
          expected = appendMain srv
      actual <- setupSrv srv (compile "code")
      expected `equal` actual
    test "rename imports" do
      let url =  settings.protocol
              <> "://"
              <> settings.hostname
              <> ":"
              <> show settings.port
          Tuple code expected = mkImport url `foldMap` [ "Prelude", "Effect" ]
          compile  = runCompiler settings
      actual <- setupSrv code (compile code)
      (appendMain expected) `equal` actual
