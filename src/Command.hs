module Command (
  requireAll
, require
, resolve

, eval

, awk
, uname
, free
, lscpu
, sha256sum
, nproc

, curl
, tar

, Concurrency(..)

, callWith
, Env(..)
, chdir
) where

import Imports hiding (strip)

import Data.Char (isSpace)
import Data.Text qualified as T

import System.Environment (getEnvironment)
import System.Process hiding (readProcess, callProcess)
import System.Process qualified as Process

newtype Concurrency = Concurrency Int
  deriving newtype (Eq, Ord, Show, Read, Num)

eval :: String -> IO Text
eval command = run "bash" ["-c", command]

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

nproc :: IO Concurrency
nproc = read <$> readProcess "nproc" [] ""

curl :: [String] -> IO ()
curl = call "curl"

tar :: [String] -> IO ()
tar = call "tar"

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

require :: FilePath -> IO ()
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

run :: FilePath -> [FilePath] -> IO Text
run command args = readProcess command args ""

readProcess :: FilePath -> [FilePath] -> Text -> IO Text
readProcess name args input = pack <$> Process.readProcess name args (unpack input)

call :: FilePath -> [FilePath] -> IO ()
call = callWith mempty

callWith :: Env -> FilePath -> [FilePath] -> IO ()
callWith Env{..} command args = do
  env <- case extend of
    [] -> return Nothing
    values -> Just . (values ++) <$> getEnvironment
  callProcess (proc command args) {
      cwd = case dir of
        "" -> Nothing
        d -> Just d
    , env
    }

data Env = Env {
  dir :: FilePath
, extend :: [(FilePath, FilePath)]
}

instance Semigroup Env where
  Env _ envl <> Env dir envr = Env dir (envl ++ envr)

instance Monoid Env where
  mempty = Env "" []

chdir :: FilePath -> Env
chdir dir = mempty { dir }

callProcess :: CreateProcess -> IO ()
callProcess command = withCreateProcess command wait
  where
    wait _ _ _ = waitForProcess >=> \ case
      ExitSuccess -> pass
      ExitFailure status -> externalCommandFailed status case cmdspec command of
        ShellCommand cmd -> [cmd]
        RawCommand cmd args -> cmd : args

externalCommandFailed :: Int -> [String] -> IO a
externalCommandFailed status command = Imports.error $ T.intercalate "\n" [
    "external command failed with exit status " <> show status
  , ""
  , "  " <> unwords (map pack command)
  ]
