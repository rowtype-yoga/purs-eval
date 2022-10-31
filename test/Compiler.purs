module Test.Compiler (runTests) where

import Prelude (Unit, bind)
import Effect
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.Assert (equal)
import Test.Compiler.ServerMock (settings, setupSrv)
import Compiler (runCompiler)

runTests :: Effect Unit
runTests = runTest do
  suite "compile" do
    test "produces expected output" do
      let expected = "compiled-code"
          compile = runCompiler settings
      actual <- setupSrv expected (compile "code")
      expected `equal` actual
