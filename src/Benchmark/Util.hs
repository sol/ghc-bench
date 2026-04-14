{-# LANGUAGE NoFieldSelectors #-}
module Benchmark.Util (

  module Imports

, Concurrency
, measure

, callWith
, Env(..)
, chdir
) where

import Prelude as Imports
import System.FilePath as Imports ((</>))

import GHC.Clock (getMonotonicTimeNSec)

import Command

measure :: IO () -> IO Int
measure action = do
  start <- getMonotonicTimeNSec
  action
  end <- getMonotonicTimeNSec
  let dtSeconds = fromIntegral (end - start) / 1e9 :: Double
  pure (round dtSeconds)
