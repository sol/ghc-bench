module SystemInfoSpec (spec) where

import Helper
import System.Environment (lookupEnv)

import Fixtures.System qualified as System

import SystemInfo

spec :: Spec
spec = do
  describe "collect" do
    it "collects system information" do
      lookupEnv "USER" >>= \ case
        Just "sol" -> SystemInfo.collect `shouldReturn` System.i10900K_desktop
        _ -> pendingWith "add your system info to run this test"
