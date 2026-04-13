module ResultSpec (spec) where

import Helper

import Fixtures.System qualified as System

import Result

spec :: Spec
spec = do
  describe "issueTitle" do
    context "with a desktop system" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.i10900K_desktop `shouldBe`

          "[result] 0s - desktop computer - Intel Core i9-10900K CPU"

    context "with a laptop system" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.dell_xps `shouldBe`

          "[result] 0s - Dell Inc. XPS 13 9310 - 11th Gen Intel Core i7-1165G7"

    context "with a LENOVO ThinkPad" do
      it "creates a descriptive issue title" do
        issueTitle 0 System.x200 `shouldBe`

          "[result] 0s - LENOVO ThinkPad X200 - Intel Core2 Duo CPU     P8700 "
