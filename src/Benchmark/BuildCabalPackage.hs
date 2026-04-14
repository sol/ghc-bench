module Benchmark.BuildCabalPackage (run) where

import Benchmark.Util

run :: String -> FilePath -> Concurrency -> FilePath -> IO Int
run package ghc concurrency sandbox = do
  callWith (chdir sandbox) "cabal" ["unpack", package, indexState]
  build ghc concurrency (sandbox </> package)

build :: FilePath -> Concurrency -> FilePath -> IO Int
build ghc concurrency dir = do
  cabal "user-config" ["init"]
  cabal "build" ["--only-dependencies", "--only-download"]
  measure do
    cabal "build" ["--only-dependencies"]
    cabal "build" []
  where
    cabal :: FilePath -> [FilePath] -> IO ()
    cabal command = callWith (chdir dir) "cabal" . case command of
      "user-config" -> mappend globalArgs
      _ -> mappend args
      where
        globalArgs :: [FilePath]
        globalArgs = [
            "--config-file=" <> dir </> "ghc-bench-cabal-config"
          , "--store-dir=" <> dir </> "store"
          , command
          ]

        args :: [FilePath]
        args = globalArgs ++ [
            indexState
          , "--with-compiler=" <> ghc
          , "--jobs=" <> show concurrency
          , "--enable-tests"
          , "--enable-benchmarks"
          ]

indexState :: FilePath
indexState = "--index-state=2026-04-15T08:18:05Z"
