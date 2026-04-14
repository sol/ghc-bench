module Imports (module Imports) where

import Prelude as Imports hiding (read, show, lines, unlines, words, unwords, error, putStrLn)

import Data.Maybe as Imports

import Data.String as Imports (IsString(..))
import Data.Functor as Imports (void, (<&>))
import Data.Bifunctor as Imports (Bifunctor(..))
import Control.Arrow as Imports ((>>>))
import Control.Monad as Imports (when, unless)
import Data.Foldable as Imports (for_)

import GHC.Stack as Imports (HasCallStack)
import GHC.Generics as Imports (Generic)

import Data.Text as Imports (Text, show, lines, unlines, words, unwords, pack, unpack, strip)
import Data.Text.Encoding as Imports (encodeUtf8)

import System.Exit as Imports (ExitCode(..))
import System.FilePath as Imports ((</>))

import Prelude qualified
import Text.Read (readMaybe)
import System.Exit (die)
import System.Directory (removePathForcibly)
import System.IO.Temp (createTempDirectory)
import Control.Exception (bracket)

withTempDirectory :: FilePath -> FilePath -> (FilePath -> IO a) -> IO a
withTempDirectory dir name = bracket (createTempDirectory dir name) removePathForcibly

error :: Text -> IO a
error message = die $ "ghc-bench: " <> unpack message

read :: HasCallStack => Read a => Text -> a
read input = case readMaybe (unpack input) of
  Just a -> a
  Nothing -> Prelude.error . unpack . unwords $ ["Prelude.read: could not parse", show input]

class Bind m r where
  bind :: (a -> r) -> m a -> r

instance Monad m => Bind m (m b) where
  bind :: (a -> m b) -> m a -> m b
  bind = (=<<)

instance Bind m r => Bind m (b -> r) where
  bind :: (a -> b -> r) -> m a -> b -> r
  bind f ma b = bind (flip f b) ma

infixl 1 -<

(-<) :: Bind m r => (a -> r) -> m a -> r
(-<) = bind

pass :: Applicative m => m ()
pass = pure ()
