module Compiler
  ( Settings
  , Code
  , ErrorPosition
  , Suggestion
  , CompileWarning
  , SuccessResult
  , successFromJson 
  , runCompiler
  )
  where

import Prelude (bind, pure, show, ($), (<<<), const)
import Control.Monad.Error.Class (liftEither)
import Control.Monad.Reader.Trans (ReaderT, runReaderT, ask)
import Control.Monad.Trans.Class (lift)
import Data.Argonaut.Core (Json)
import Data.Argonaut.Decode (printJsonDecodeError)
import Data.Argonaut.Decode.Class (decodeJson)
import Data.Argonaut.Parser (jsonParser)
import Data.Functor ((<$>))
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Data.Maybe (Maybe(Just))
import Data.Monoid ((<>))
import Effect.Aff (Aff, error)
import Effect.Exception (Error)
import Affjax.ResponseFormat (string)
import Affjax.Node (post, printError)
import Affjax.RequestBody (RequestBody (String))
import Parsing.String as PS
import Parsing.String.Replace as PS.Replace

type Settings = { protocol :: String
                , hostname :: String
                , port :: Int
                , parser :: Json -> Either Error SuccessResult
                }
type Code = String
type Compiler = ReaderT Code (ReaderT Settings Aff)

-- extracted from github:purescript/trypurescript
type ErrorPosition =
  { startLine :: Int
  , endLine :: Int
  , startColumn :: Int
  , endColumn :: Int
  }
type Suggestion =
  { replacement :: String
  , replaceRange :: Maybe ErrorPosition
  }
type CompileWarning =
  { errorCode :: String
  , message :: String
  , position :: Maybe ErrorPosition
  , suggestion :: Maybe Suggestion
  }
type SuccessResult =
  { js :: String
  , warnings :: Maybe (Array CompileWarning)
  }
-- end of imports from github:purescript/trypurescript

successFromJson :: Json -> Either Error SuccessResult
successFromJson json = (error <<< printJsonDecodeError) `lmap` (decodeJson json)

askCode :: Compiler Code
askCode = ask

askSettings :: Compiler Settings
askSettings = lift ask

liftAff :: forall a. Aff a -> Compiler a
liftAff h = lift $ lift h

rename :: String -> String -> Code -> Code
rename url output code = PS.Replace.replace code (prefix <$> PS.string "from \"..") where
  prefix = const $ "from \"" <> url <> output

compile :: Compiler Code
compile = do
  code <- askCode
  s <- askSettings
  let url = s.protocol <> "://" <> s.hostname <> ":" <> show s.port
      endpoint = "/compile"
      output = "/output"
  mRes <- liftAff $ post string (url <> endpoint) $ Just $ String code
  res <- liftEither $ (error <<< printError) `lmap` mRes 
  body <- liftEither $ error `lmap` (jsonParser res.body)
  succ <- liftEither $ s.parser body
  pure $ rename url output succ.js

runCompiler :: Settings -> Code -> Aff Code
runCompiler s code = runReaderT (runReaderT compile code) s
