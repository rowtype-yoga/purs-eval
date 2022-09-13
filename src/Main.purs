module Main where

import Prelude (Unit, void, ($))

import Effect (Effect)
import Node.Process (stdin, stdout)
import Node.Stream (pipe)

main :: Effect Unit
main = void $ stdin `pipe` stdout
