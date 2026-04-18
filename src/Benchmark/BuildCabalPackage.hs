module Benchmark.BuildCabalPackage (run) where

import Benchmark.Util

run :: String -> FilePath -> Concurrency -> FilePath -> IO [(String, Seconds)]
run package ghc concurrency sandbox = do
  callWith (chdir sandbox) "cabal" ["unpack", package, indexState]
  build ghc concurrency (sandbox </> package)

build :: FilePath -> Concurrency -> FilePath -> IO [(String, Seconds)]
build ghc concurrency dir = do
  cabal "user-config" ["init"]
  downloadDependencies
  traverse (traverse measure) [
      ("dependencies", installDependencies)
    , ("build", buildPackage)
    ]
  where
    downloadDependencies = cabal "build" ["--only-dependencies", "--only-download"]
    installDependencies = cabal "build" ["--only-dependencies"]
    buildPackage = cabal "build" []

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
