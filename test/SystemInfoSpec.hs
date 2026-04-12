module SystemInfoSpec (spec) where

import Helper

import Command qualified as Command
import Fixtures.System qualified as System

import SystemInfo

spec :: Spec
spec = do
  describe "collect" do
    it "collects system information" do
      Command.eval "whoami" <&> strip >>= \ case
        "sol" -> SystemInfo.collect `shouldReturn` System.i10900K_desktop
        _ -> pendingWith "add your system info to run this test"
