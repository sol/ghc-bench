module Benchmark.BuildGhc (Tarball(..), run) where

import Benchmark.Util

import Blob (Blob)
import Blob qualified

data Tarball = Tarball {
  blob :: Blob
, root :: FilePath
} deriving (Eq, Show)

run :: Tarball -> FilePath -> Concurrency -> Benchmark ()
run tarball stage0 concurrency = setEnv "GHC" stage0 do
  download tarball.blob
  tar ["-xf", tarball.blob.path]
  cd tarball.root do
    call "./configure" []
    hadrian ["--help"] -- this makes sure that building hadrian dependencies is not measured
    measure "build" do
      hadrian ["-j" <> show concurrency, "--flavour=quickest"]
  where
    hadrian = call "hadrian/build"
