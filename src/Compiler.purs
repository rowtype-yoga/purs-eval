module Compiler (Settings, Code, runCompiler) where

import Prelude (bind, pure, show, ($), (<<<))
import Control.Monad.Error.Class (liftEither)
import Control.Monad.Reader.Trans (ReaderT, runReaderT, ask)
import Control.Monad.Trans.Class (lift)
import Data.Bifunctor (lmap)
import Data.Maybe (Maybe(Just))
import Data.Monoid ((<>))
import Effect.Aff (Aff, error)
import Affjax.ResponseFormat (string)
import Affjax.Node (post, printError)
import Affjax.RequestBody (RequestBody (String))

type Settings = { protocol :: String, hostname :: String, port :: Int }
type Code = String
type Compiler = ReaderT Code (ReaderT Settings Aff)

askCode :: Compiler Code
askCode = ask

askSettings :: Compiler Settings
askSettings = lift ask

liftAff :: forall a. Aff a -> Compiler a
liftAff h = lift $ lift h

compile :: Compiler Code
compile = do
  code <- askCode
  s <- askSettings
  let url = s.protocol <> "://" <> s.hostname <> ":" <> show s.port <> "/compile"
  mRes <- liftAff $ post string url $ Just $ String code
  res <- liftEither $ (error <<< printError) `lmap` mRes 
  pure res.body

runCompiler :: Settings -> Code -> Aff Code
runCompiler s code = runReaderT (runReaderT compile code) s
