module RunSpec (spec) where

import Helper
import System.IO.Silently
import README (ensureFile)

import Run (Config(..), Mode(..), defaultConfig, parseOptions)
import Run qualified

spec :: Spec
spec = do
  describe "--dry-run" do
    it "prints commands" do
      let run = Run.run "~/.cache/ghc-bench" ($ "<sandbox>") defaultConfig { mode = DryRun } [] "/path/to/ghc-9.12.4" 20
      capture_ run >>= ensureFile "test/dry-run" . encodeUtf8 . pack

  describe "parseOptions" do
    it "accepts --dry-run" do
      parseOptions ["--dry-run", "foo", "bar"]
        `shouldReturn` (defaultConfig { mode = DryRun }, ["foo", "bar"])

    it "accepts --prepare" do
      parseOptions ["--prepare", "foo", "bar"]
        `shouldReturn` (defaultConfig { mode = Prepare }, ["foo", "bar"])

    it "accepts --qr" do
      parseOptions ["--qr", "foo", "bar"]
        `shouldReturn` (defaultConfig { printQR = True }, ["foo", "bar"])
