module Main (main) where

import Prelude (Unit, bind, discard)
import Data.Tuple (Tuple (Tuple))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Node.Process (stdin, stdout)
import Node.Stream.Aff (readSome, write, end, toStringUTF8, fromStringUTF8)
import Compiler (runCompiler)

main :: Effect Unit
main = launchAff_ do
  Tuple input _ <- readSome stdin
  code <- toStringUTF8 input
  code' <- runCompiler { protocol: "https", hostname: "compile.purescript.org", port: 443 } code
  output <- fromStringUTF8 code'
  write stdout output
  end stdout
