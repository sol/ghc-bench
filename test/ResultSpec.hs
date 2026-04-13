module ResultSpec (spec) where

import Helper
import Data.Text.IO.Utf8 qualified as Utf8

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

  describe "parseFromIssueBody" do
    let
      fixtures = [
          ("test/fixtures/i10900K_desktop", Result {
              time = 526
            , concurrency = 20
            , system = System.i10900K_desktop
            }
          )
        , ("test/fixtures/dell_xps", Result {
              time = 715
            , concurrency = 8
            , system = System.dell_xps
            }
          )
        , ("test/fixtures/x200", Result {
              time = 3013
            , concurrency = 2
            , system = System.x200
            }
          )
        ]

    for_ fixtures \ (name, expected) -> do
      it name do
        entry <- parseFromIssueBody <$> Utf8.readFile name
        entry `shouldBe` expected

  describe "resultPath" do
    context "with a desktop system" do
      it "creates a descriptive path" do
        resultPath "2026-04-13" System.i10900K_desktop `shouldBe`
          "results/intel/10th/i9-10900K/ASRock-Z490M-ITX-ac_2026-04-13.yaml"

    context "with a laptop system" do
      it "creates a descriptive path" do
        resultPath "2026-04-13" System.dell_xps `shouldBe`
          "results/intel/11th/i7-1165G7/XPS-13-9310_2026-04-13.yaml"

    context "with a LENOVO ThinkPad" do
      it "creates a descriptive path" do
        resultPath "2026-04-13" System.x200 `shouldBe`
          "results/intel/core_2/P8700/X200-7455D7G_2026-04-13.yaml"
