{-# LANGUAGE NoFieldSelectors #-}
module Benchmark.Util (
  module Imports
, Benchmark
, Concurrency

, withLabel
, setEnv
, cd
, download
, call
, measure

, tar
) where

import Prelude as Imports

import Benchmark.Type
import Command (Concurrency)

tar :: [String] -> Benchmark ()
tar = call "tar"
