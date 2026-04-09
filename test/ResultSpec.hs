module ResultSpec (spec) where

import Helper

import Fixtures.System qualified as System

import Result

spec :: Spec
spec = do
  describe "issueTitle" do
    context "with a desktop system" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.i10900K_desktop `shouldBe` "[result] 0s - desktop computer - Intel Core i9-10900K CPU"

    context "with a laptop system" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.t60_ThinkPad `shouldBe` "[result] 0s - LENOVO ThinkPad T60 - Intel Core 2 Duo Processor T7200"
