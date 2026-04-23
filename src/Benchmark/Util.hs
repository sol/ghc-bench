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

import SystemInfo (Concurrency)
import Benchmark.Type

tar :: [String] -> Benchmark ()
tar = call "tar"
