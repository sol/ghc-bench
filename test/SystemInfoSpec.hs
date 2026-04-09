module SystemInfoSpec (spec) where

import Helper

import SystemInfo

import Fixtures.System qualified as System

spec :: Spec
spec = do
  describe "collect" do
    it "collects system information" do
      SystemInfo.collect `shouldReturn` System.i10900K_desktop
