module RunSpec (spec) where

import Helper
import System.IO.Silently
import README (ensureFile)

import Run qualified

spec :: Spec
spec = do
  describe "--dry-run" do
    it "prints commands" do
      let run = Run.run "~/.cache/ghc-bench" ($ "<sandbox>") True [] "/path/to/ghc-9.12.4" 20
      capture_ run >>= ensureFile "test/dry-run" . encodeUtf8 . pack
