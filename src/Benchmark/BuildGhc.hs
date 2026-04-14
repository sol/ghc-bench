module Benchmark.BuildGhc (Tarball(..), run) where

import Benchmark.Util

import Blob (Blob)
import Blob qualified
import Command (tar)

data Tarball = Tarball {
  blob :: Blob
, root :: FilePath
} deriving (Eq, Show)

run :: Tarball -> FilePath -> Concurrency -> FilePath -> IO Int
run tarball stage0 concurrency sandbox = do
  Blob.download tarball.blob
  tar ["-xf", tarball.blob.path, "-C", sandbox]
  build stage0 concurrency (sandbox </> tarball.root)

build :: FilePath -> Concurrency -> FilePath -> IO Int
build stage0 concurrency dir = do
  call "./configure" []
  hadrian ["--help"] -- this makes sure that building hadrian dependencies is not measured
  measure do
    hadrian ["-j" <> show concurrency, "--flavour=quickest"]
  where
    hadrian = call "hadrian/build"
    call command args = callWith Env { dir, extend = [("GHC", stage0)] } command args
