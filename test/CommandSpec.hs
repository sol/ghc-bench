module CommandSpec (spec) where

import Helper

import System.IO
import System.IO.Silently
import Control.Exception

import Command

spec :: Spec
spec = do
  describe "resolve" do
    it "returns the absolute path to an executable" do
      resolve "cp" `shouldReturn` "/usr/bin/cp"

    context "when executable does not exist" do
      it "terminates" do
        hCapture [stderr] (try $ resolve "d3b07384") `shouldReturn` (
            "ghc-bench: `d3b07384` is required, but couldn't be found on the search PATH.\n"
          , Left $ ExitFailure 1
          )
