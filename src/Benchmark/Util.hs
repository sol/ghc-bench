{-# LANGUAGE NoFieldSelectors #-}
module Benchmark.Util (

  module Imports

, Concurrency

, Seconds(..)
, measure

, callWith
, Env(..)
, chdir
) where

import Prelude as Imports
import System.FilePath as Imports ((</>))

import GHC.Clock (getMonotonicTimeNSec)

import Command

newtype Seconds = Seconds Int
  deriving newtype (Eq, Show, Num, Ord, Bounded)

measure :: IO () -> IO Seconds
measure action = do
  start <- getMonotonicTimeNSec
  action
  end <- getMonotonicTimeNSec
  let dtSeconds = fromIntegral (end - start) / 1e9 :: Double
  pure . Seconds $ round dtSeconds
