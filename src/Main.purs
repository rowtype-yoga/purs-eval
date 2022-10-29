module Main where

import Prelude (Unit, ($), (<<<), void, pure, bind)

import Control.Monad.Error.Class (liftEither)
import Data.Bifunctor (lmap)
import Data.Maybe (Maybe(Just))
import Effect (Effect)
import Effect.Aff (Aff, error)
import Node.Process (stdin, stdout)
import Node.Stream (pipe)
import Affjax.ResponseFormat (string)
import Affjax.Node (post, printError)
import Affjax.RequestBody (RequestBody (String))

compile :: String -> Aff String
compile s = do
  mRes <- post string "http://localhost:3000/compile" $ Just $ String s
  res <- liftEither $ (error <<< printError) `lmap` mRes 
  pure res.body

main :: Effect Unit
main = void $ stdin `pipe` stdout
