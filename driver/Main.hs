module Main (main) where

import Prelude
import System.Environment

import qualified Run

main :: IO ()
main = getArgs >>= Run.main
