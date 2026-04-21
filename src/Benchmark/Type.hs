module Benchmark.Type (
  Label(..)
, Seconds(..)
, Benchmark
, dependencies
, dryRun
, run

, withLabel
, setEnv
, cd
, download
, call
, measure
) where

import Imports

import GHC.Clock (getMonotonicTimeNSec)
import Data.Char (isSpace)
import Data.Text qualified as T
import Data.Text.IO.Utf8 qualified as Utf8
import System.FilePath (splitPath)
import Control.Monad.Trans.Class (MonadTrans(..))
import Control.Monad.Trans.Reader
import Control.Monad.Trans.Writer.CPS hiding (tell)
import Control.Monad.Trans.Writer.CPS qualified as Writer

import Blob (Blob)
import Blob qualified
import Command hiding (callWith)
import Command qualified

newtype Label = Label Text
  deriving newtype (Eq, Show, Ord, IsString)

newtype Seconds = Seconds Int
  deriving newtype (Eq, Show, Num, Ord, Bounded)

data Command =
    SetEnv String String [Command]
  | ChangeDirectory FilePath [Command]
  | Download Blob
  | Call FilePath [FilePath]
  | Measure Label [Command]
  deriving (Show)

type Benchmark = ReaderT [String] (Writer [Command])

dependencies :: Benchmark () -> [FilePath]
dependencies = collectDependencies . toForest

dryRun :: Benchmark () -> IO [(Label, Seconds)]
dryRun action = do
  let (times, output) = dryRunForest $ toForest action
  Utf8.putStrLn output
  return times

run :: Benchmark () -> IO [(Label, Seconds)]
run = execForest . toForest

toForest :: Benchmark () -> [Command]
toForest = toForestWith []

toForestWith :: [String] -> Benchmark () -> [Command]
toForestWith labels action = execWriter $ runReaderT action labels

tell :: Command -> Benchmark ()
tell = lift . Writer.tell . return

withLabel :: String -> Benchmark () -> Benchmark ()
withLabel = local . (:)

setEnv :: String -> String -> Benchmark () -> Benchmark ()
setEnv key value action = do
  labels <- ask
  let commands = toForestWith labels action
  tell $ SetEnv key value commands

cd :: FilePath -> Benchmark () -> Benchmark ()
cd dir action = do
  labels <- ask
  let commands = toForestWith labels action
  tell $ ChangeDirectory dir commands

download :: Blob -> Benchmark ()
download = tell . Download

call :: FilePath -> [FilePath] -> Benchmark ()
call command = tell . Call command

measure :: String -> Benchmark () -> Benchmark ()
measure label action = withLabel label do
  labels <- ask
  let commands = toForestWith labels action
  tell $ Measure (toLabel labels) commands

collectDependencies :: [Command] -> [FilePath]
collectDependencies = concatMap \ case
  Download _ -> []
  Call path _ -> case splitPath path of
    [name] -> [name]
    _ -> []
  SetEnv _ _ commands -> collectDependencies commands
  ChangeDirectory _ commands -> collectDependencies commands
  Measure _ commands -> collectDependencies commands

dryRunForest :: [Command] -> ([(Label, Seconds)], Text)
dryRunForest = fmap unlines . runWriter . \ commands -> do
  writeLine ""
  writeLine "############################################"
  writeLine "# With a fresh temporary working directory #"
  writeLine "############################################"
  writeLine ""
  go commands
  where
    writeLine :: Text -> Writer [Text] ()
    writeLine = Writer.tell . (: [])

    go :: [Command] -> Writer [Text] [(Label, Seconds)]
    go = fmap concat . traverse \ case
      ChangeDirectory dir commands -> do
        writeLine $ "cd " <> pack dir
        go commands

      SetEnv name value commands -> do
        writeLine $ "export " <> pack name <> "=" <> pack value
        go commands

      Download blob -> do
        writeLine ""
        writeLine $ "# Ensure that " <> pack blob.path <> " exists; download if necessary."
        writeLine $ "# url: " <> pack blob.url
        writeLine $ "# sha256: " <> blob.hash
        writeLine ""
        return []

      Call command args -> do
        writeLine $ showCommand command args
        return []

      Measure (Label label) commands -> do
        writeLine ""
        writeLine $ "# MEASURE " <> label
        times <- go commands
        return $ (Label label, 0) : times

showCommand :: String -> [String] -> Text
showCommand command = unwords . map showArg . (:) command

showArg :: String -> Text
showArg arg
  | any isSpace arg = show arg
  | otherwise = pack arg

execForest :: [Command] -> IO [(Label, Seconds)]
execForest = go mempty
  where
    go env = fmap concat . traverse \ case
      SetEnv name value commands -> do
        go env { extend = (name, value) : env.extend } commands

      ChangeDirectory dir commands -> do
        go env { dir = env.dir </> dir } commands

      Download blob -> do
        Blob.download blob $> []

      Call command args -> do
        Command.callWith env command args $> []

      Measure label cs -> do
        start <- getMonotonicTimeNSec
        times <- go env cs
        end <- getMonotonicTimeNSec
        let
          time :: Double
          time = fromIntegral (end - start) / 1e9
        return $ (label, Seconds (round time)) : times

toLabel :: [String] -> Label
toLabel = Label . T.intercalate "-" . map pack . reverse
