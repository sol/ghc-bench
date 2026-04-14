module Benchmark.BuildCabalPackage (run) where

import Benchmark.Util

run :: String -> FilePath -> Concurrency -> FilePath -> IO Int
run package ghc concurrency sandbox = do
  callWith (chdir sandbox) "cabal" ["unpack", package]
  build ghc concurrency (sandbox </> package)

build :: FilePath -> Concurrency -> FilePath -> IO Int
build ghc concurrency dir = do
  cabal "build" ["--only-dependencies", "--only-download"]
  measure do
    cabal "build" ["--only-dependencies"]
    cabal "build" []
  where
    cabal :: FilePath -> [FilePath] -> IO ()
    cabal command args = callWith (chdir dir) "cabal" $ [
        "--store-dir=" <> dir </> "store"
      , command
      , "--with-compiler=" <> ghc
      , "--jobs=" <> show concurrency
      , "--enable-tests"
      , "--enable-benchmarks"
      ] ++ args
