module Benchmark.Ghci (run) where

import Benchmark.Util
import Benchmark.BuildCabalPackage (withPackage)

run :: String -> FilePath -> Concurrency -> Benchmark ()
run package ghc _concurrency = withPackage package do
  measure "ghci" do
    call "bash" ["-c", command]
  where
    command :: String
    command = unwords [
        "echo"
      , "|"
      , ghc
      , "--interactive"
      , "-ignore-dot-ghci"
      , "-isrc"
      , "`find src -name '*.hs'`"
      , "-Iinclude"
      , "-XHaskell2010"
      ]
