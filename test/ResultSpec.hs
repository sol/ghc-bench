{-# OPTIONS_GHC -Wno-unused-top-binds #-}
{-# OPTIONS_GHC -Wno-orphans #-}
module ResultSpec (spec) where

import README (ensureFile)
import Data.Text qualified as T
import Data.Set qualified as Set
import Data.Set (Set)
import Data.List qualified as List
import Helper

import Control.Exception
import Data.Ord (comparing)
import Data.Yaml (ToJSON(..), object, (.=))
import Data.Yaml.Pretty qualified as Yaml
import Data.ByteString (ByteString)
import Data.ByteString qualified as B
import System.Directory (listDirectory, createDirectoryIfMissing)
import System.FilePath (takeDirectory)
import Data.Text.IO.Utf8 qualified as Utf8

import Fixtures.System qualified as System

import SystemInfo
import Result

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import README qualified (update)

spec :: Spec
spec = do
  describe "issueTitle" do
    context "with a desktop system" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.i10900K_desktop `shouldBe`

          "[result] 0s - desktop computer - Intel Core i9-10900K CPU"

    context "with a laptop system" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.dell_xps `shouldBe`

          "[result] 0s - Dell Inc. XPS 13 9310 - 11th Gen Intel Core i7-1165G7"

    context "with a LENOVO ThinkPad" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.x200 `shouldBe`

          "[result] 0s - LENOVO ThinkPad X200 - Intel Core2 Duo CPU     P8700 "

  describe "parseFromIssueBody" do
    let
      fixtures = [
          ("raw/2026-04-12T16:01:13Z", Result {
              times = [("ghc-9.12.4", 526)]
            , concurrency = 20
            , system = System.i10900K_desktop
            }
          )
        , ("raw/2026-04-12T13:37:10Z", Result {
              times = [("ghc-9.12.4", 715)]
            , concurrency = 8
            , system = System.dell_xps
            }
          )
        , ("raw/2026-04-12T17:38:23Z", Result {
              times = [("ghc-9.12.4", 3013)]
            , concurrency = 2
            , system = System.x200
            }
          )
        ]

    for_ fixtures \ (name, expected) -> do
      it name do
        entry <- parseFromIssueBody <$> Utf8.readFile name
        entry `shouldBe` expected

  describe "resultPath" do
    context "with a desktop system" do
      it "creates a descriptive path" do
        resultPath "2026-04-13" System.i10900K_desktop `shouldBe`
          "results/intel/10th/i9-10900K/ASRock-Z490M-ITX-ac_2026-04-13.yaml"

    context "with a laptop system" do
      it "creates a descriptive path" do
        resultPath "2026-04-13" System.dell_xps `shouldBe`
          "results/intel/11th/i7-1165G7/XPS-13-9310_2026-04-13.yaml"

    context "with a LENOVO ThinkPad" do
      it "creates a descriptive path" do
        resultPath "2026-04-13" System.x200 `shouldBe`
          "results/intel/core_2/P8700/X200-7455D7G_2026-04-13.yaml"

  fit "process results" do
    results <- processResults "raw"
    README.update results

processResults :: FilePath -> IO [Result]
processResults dir = do
  listDirectory dir >>= traverse \ timestamp -> do
    body <- Utf8.readFile (dir </> timestamp)
    let
      result :: Result
      result = parseFromIssueBody body

      path :: FilePath
      path = resultPath (fromString timestamp) result.system
    encodeFile path result
    return result

encodeFile :: FilePath -> Result -> IO ()
encodeFile file result = do
  ensureFile file $ Yaml.encodePretty conf result
  where
    conf :: Yaml.Config
    conf = Yaml.setConfCompare (comparing byFieldOrder) Yaml.defConfig

    byFieldOrder :: Text -> Int
    byFieldOrder name = fromMaybe maxBound (lookup name fieldOrder)

fieldOrder :: [(Text, Int)]
fieldOrder = flip zip [1..] [
    "times"
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

instance ToJSON Result where
  toJSON Result{..} = object [
      "times" .= Map.fromList times
    , "concurrency" .= concurrency
    , "system" .= system
    ]

deriving newtype instance ToJSON Concurrency
instance ToJSON SystemInfo
instance ToJSON Product
instance ToJSON Board
instance ToJSON Cpu
