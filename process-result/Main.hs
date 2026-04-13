{-# OPTIONS_GHC -Wno-orphans #-}
module Main (main) where

import Imports

import Data.Yaml (ToJSON, encodeFile)
import System.Environment (getArgs)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory)

import Result
import SystemInfo

instance ToJSON Result
deriving newtype instance ToJSON Concurrency
instance ToJSON SystemInfo
instance ToJSON Product
instance ToJSON Board
instance ToJSON Cpu

main :: IO ()
main = do
  [body, timestamp] <- getArgs

  let
    result :: Result
    result = parseFromIssueBody (pack body)

    path :: FilePath
    path = resultPath (fromString timestamp) result.system

  createDirectoryIfMissing True (takeDirectory path)
  encodeFile path result
