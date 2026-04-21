module Benchmark.BuildCabalPackage (run, withPackage) where

import Benchmark.Util

indexState :: FilePath
indexState = "--index-state=2026-04-15T08:18:05Z"

withPackage :: String -> Benchmark () -> Benchmark ()
withPackage package action = do
  call "cabal" ["unpack", package, indexState]
  cd package action

run :: String -> FilePath -> Concurrency -> Benchmark ()
run package ghc concurrency = withPackage package do
  cabal "user-config" ["init"]
  cabal "configure" [
      "--with-compiler=" <> ghc
    , "--jobs=" <> show concurrency
    , "--enable-tests"
    , "--enable-benchmarks"
    , indexState
    ]
  cabal "build" ["--only-dependencies", "--only-download"]
  measure "dependencies" do
    cabal "build" ["--only-dependencies"]
  measure "build" do
    cabal "build" []
  where
    cabal :: FilePath -> [FilePath] -> Benchmark ()
    cabal command = call "cabal" . mappend [
        "--config-file=ghc-bench-cabal-config"
      , "--store-dir=store"
      , command
      ]
