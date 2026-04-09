module Run (main) where

import Imports
import Prelude qualified

import Data.Text.IO (putStrLn)

import GHC.Clock (getMonotonicTimeNSec)
import System.Directory (createDirectoryIfMissing)
import System.Environment.Blank (setEnv)
import System.Exit (die)

import Command (tar, nproc, sh)
import Command qualified

import SystemInfo qualified

import Asset (Asset(..))
import Asset qualified

import Result (Result(..))
import Result qualified

version :: FilePath
version = "9.12.4"

bootGhc :: FilePath
bootGhc = "ghc-" <> version

baseDir :: FilePath
baseDir = "/tmp/ghc-bench"

sourceTarball :: Asset
sourceTarball = Asset {
    url = "https://downloads.haskell.org/~ghc/" <> version <> "/ghc-" <> version <> "-src.tar.gz"
  , path = baseDir </> "ghc-" <> version <> "-src.tar.gz"
  , hash = "df71d96169056d3a6d7ec17498864cbdd5511bda196440dc38a692133833dfa4"
  }

main :: [String] -> IO ()
main args = do
  Command.requireAll
  Command.require "cabal"
  ghc <- Command.resolve bootGhc
  createDirectoryIfMissing False baseDir
  info <- SystemInfo.collect
  result <- case args of
    [] -> run ghc sourceTarball
    ["info"] -> return Result {time = 0, concurrency = 0}
    _ -> die "usage: ghc-bench [info]"
  putStrLn $ "Build time: " <> show result.time <> "s"
  putStrLn ""
  Result.submit result info

run :: FilePath -> Asset -> IO Result
run ghc source = withTempDirectory baseDir "run" \ sandbox -> do
  Asset.download source
  tar ["-xf", source.path, "-C", sandbox]
  build (sandbox </> "ghc-" <> version) ghc

build :: FilePath -> FilePath -> IO Result
build dir ghc = do
  setEnv "GHC" ghc True
  sh dir "./configure"

  -- this makes sure that building hadrian dependencies is not measured
  sh dir "hadrian/build --help"

  concurrency <- nproc
  time <- measure do
    sh dir $ "hadrian/build -j" <> Prelude.show concurrency <> " --flavour=quickest"
  return Result{..}

measure :: IO () -> IO Int
measure action = do
  start <- getMonotonicTimeNSec
  action
  end <- getMonotonicTimeNSec
  let dtSeconds = fromIntegral (end - start) / 1e9 :: Double
  pure (round dtSeconds)
