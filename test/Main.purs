module Test.Main (main) where

import Prelude (Unit)
import Effect (Effect)
import Test.Compiler as Compiler

main :: Effect Unit
main = Compiler.runTests
