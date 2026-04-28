module RunSpec (spec) where

import Helper
import System.IO.Silently
import README (ensureFile)

import Run qualified
import Run (DryRun(..), Prepare(..), PrintQR(..))

spec :: Spec
spec = do
  describe "--dry-run" do
    it "prints commands" do
      let run = Run.run "~/.cache/ghc-bench" ($ "<sandbox>") DryRun NoPrepare [] "/path/to/ghc-9.12.4" 20
      capture_ run >>= ensureFile "test/dry-run" . encodeUtf8 . pack

  describe "parseOptions" do
    it "accepts --dry-run" do
      Run.parseOptions ["--dry-run", "foo", "bar"]
        `shouldBe` (DryRun, (NoPrepare, (NoPrintQR, ["foo", "bar"])))

    it "accepts --prepare" do
      Run.parseOptions ["--prepare", "foo", "bar"]
        `shouldBe` (NoDryRun, (Prepare, (NoPrintQR, ["foo", "bar"])))

    it "accepts --qr" do
      Run.parseOptions ["--qr", "foo", "bar"]
        `shouldBe` (NoDryRun, (NoPrepare, (PrintQR, ["foo", "bar"])))
