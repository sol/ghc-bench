{-# OPTIONS_GHC -Wno-orphans #-}
module Main (main) where

import Imports

import Data.Ord (comparing)
import Data.Yaml (ToJSON)
import Data.Yaml.Pretty qualified as Yaml
import Data.ByteString qualified as B
import System.Environment (getArgs)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory)

import Result
import SystemInfo

fieldOrder :: [(Text, Int)]
fieldOrder = flip zip [1..] [
    "time"
  , "concurrency"
  , "os"
  , "arch"
  , "category"
  , "chassis_type"
  , "name"
  , "cores"
  , "threads"
  , "vendor"
  , "family"
  , "model"
  , "stepping"
  , "version"
  , "product"
  , "board"
  , "cpu"
  , "ram"
  ]

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

  encodeFile path result

encodeFile :: FilePath -> Result -> IO ()
encodeFile file result = do
  ensureDirectory file
  B.writeFile file $ Yaml.encodePretty conf result
  where
    conf :: Yaml.Config
    conf = Yaml.setConfCompare (comparing byFieldOrder) Yaml.defConfig

    byFieldOrder :: Text -> Int
    byFieldOrder name = fromMaybe maxBound (lookup name fieldOrder)

ensureDirectory :: FilePath -> IO ()
ensureDirectory = createDirectoryIfMissing True . takeDirectory
