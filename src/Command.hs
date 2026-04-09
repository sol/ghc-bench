module Command (
  requireAll
, require
, resolve

, eval
, sh

, awk
, uname
, free
, lscpu
, sha256sum
, nproc

, curl
, tar
) where

import Imports hiding (strip)

import Data.Char (isSpace)
import Data.Text qualified as T

import System.Process (readProcessWithExitCode, rawSystem, callProcess)
import System.Process qualified as Process

eval :: String -> IO Text
eval command = run "bash" ["-c", command]

sh :: FilePath -> String -> IO ()
sh dir command = rawSystem "bash" ["-c", "cd " <> dir <> " && " <> command] >>= \ case
  ExitSuccess -> pass
  ExitFailure _ -> error $ "Running `" <> pack command <> "` failed!"

awk :: Text -> Text -> IO Text
awk command = readProcess "awk" [unpack command]

uname :: [String] -> IO Text
uname args = run "uname" args <&> T.strip

free :: [String] -> IO Text
free = run "free"

lscpu :: [String] -> IO Text
lscpu = run "lscpu"

sha256sum :: String -> IO Text
sha256sum file = T.take 64 <$> run "sha256sum" [file]

nproc :: IO Int
nproc = read <$> Process.readProcess "nproc" [] ""

curl :: [String] -> IO ()
curl = callProcess "curl"

tar :: [String] -> IO ()
tar = callProcess "tar"

requireAll :: IO ()
requireAll = do
  require "bash"
  require "awk"
  require "uname"
  require "free"
  require "lscpu"
  require "sha256sum"
  require "nproc"
  require "curl"
  require "tar"

require :: String -> IO ()
require = void . resolve

resolve :: FilePath -> IO FilePath
resolve name = readProcessWithExitCode "which" [name] "" >>= \ case
  (ExitFailure _, _, _) -> error message
  (ExitSuccess, path, _) -> return $ strip path
  where
    message :: Text
    message = mconcat ["`", pack name, "` is required, but couldn't be found on the search PATH."]

    strip :: String -> String
    strip = reverse . dropWhile isSpace . reverse . dropWhile isSpace

run :: String -> [String] -> IO Text
run command args = readProcess command args ""

readProcess :: FilePath -> [FilePath] -> Text -> IO Text
readProcess name args input = pack <$> Process.readProcess name args (unpack input)
