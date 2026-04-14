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

import Command (Concurrency)

import GHC.Clock (getMonotonicTimeNSec)
import System.Environment (getEnvironment)
import System.Process.Extra

measure :: IO () -> IO Int
measure action = do
  start <- getMonotonicTimeNSec
  action
  end <- getMonotonicTimeNSec
  let dtSeconds = fromIntegral (end - start) / 1e9 :: Double
  pure (round dtSeconds)

callWith :: Env -> FilePath -> [FilePath] -> IO ()
callWith Env{..} command args = do
  env <- case extend of
    [] -> return Nothing
    values -> Just . (values ++) <$> getEnvironment
  callCreateProcess (proc command args) {
      cwd = case dir of
        "" -> Nothing
        d -> Just d
    , env
    }

data Env = Env {
  dir :: FilePath
, extend :: [(FilePath, FilePath)]
}

instance Semigroup Env where
  Env _ envl <> Env dir envr = Env dir (envl ++ envr)

instance Monoid Env where
  mempty = Env "" []

chdir :: FilePath -> Env
chdir dir = mempty { dir }
