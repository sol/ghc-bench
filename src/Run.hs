module Run (main) where

import Imports

import Data.Text.IO (putStrLn)

import System.Directory (createDirectoryIfMissing)
import System.Exit (die)

import Command (nproc)
import Command qualified

import SystemInfo qualified

import Blob (Blob(..))

import Result (Result(..))
import Result qualified
import Benchmark.BuildGhc (Tarball(..))
import Benchmark.BuildGhc qualified as BuildGhc
import Benchmark.BuildCabalPackage qualified as BuildCabalPackage

version :: FilePath
version = "9.12.4"

ghc :: FilePath
ghc = "ghc-" <> version

baseDir :: FilePath
baseDir = "/tmp/ghc-bench"

sourceTarball :: Tarball
sourceTarball = Tarball {
    blob = Blob {
      url = "https://downloads.haskell.org/~ghc/" <> version <> "/ghc-" <> version <> "-src.tar.gz"
    , path = baseDir </> "ghc-" <> version <> "-src.tar.gz"
    , hash = "df71d96169056d3a6d7ec17498864cbdd5511bda196440dc38a692133833dfa4"
    }
  , root = "ghc-" <> version
  }

cabalPackage :: FilePath
cabalPackage = "hspec-2.11.17"

main :: [String] -> IO ()
main args = do
  Command.requireAll
  Command.require "cabal"
  stage0 <- Command.resolve ghc
  createDirectoryIfMissing False baseDir
  system <- SystemInfo.collect
  concurrency <- nproc
  time <- withTempDirectory baseDir "build" $ \ dir -> case args of
    [] -> BuildGhc.run sourceTarball stage0 concurrency dir
    ["cabal"] -> BuildCabalPackage.run cabalPackage ghc concurrency dir
    ["info"] -> return 0
    _ -> die "usage: ghc-bench [info]"
  putStrLn $ "\nBuild time: " <> show time <> "s"
  putStrLn ""
  Result.submit Result {..}
