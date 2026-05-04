module Blob (
  requireAll
, download
, Blob(..)
) where

import Imports

import Data.Text qualified as T
import System.Directory (doesFileExist, renameFile)

import Command qualified

data Blob = Blob {
  url :: FilePath
, path :: FilePath
, hash :: Text
} deriving (Eq, Show)

download :: Blob -> IO ()
download blob = do
  ensure blob.url blob.path
  verify blob

ensure :: FilePath -> FilePath -> IO ()
ensure url path = unless -< doesFileExist path $ do
  let tmp = path <> ".tmp"
  curl ["-L", url, "-o", tmp]
  renameFile tmp path

verify :: Blob -> IO ()
verify Blob {..} = do
  actual <- sha256sum path
  when (actual /= hash) . error $ unlines [
      "sha256sum mismatch!"
    , ""
    , "  url:      " <> pack url
    , "  file:     " <> pack path
    , "  expected: " <> hash
    , "  actual:   " <> actual
    ]

requireAll :: IO ()
requireAll = do
  Command.require "curl"
  Command.require "sha256sum"

curl :: [String] -> IO ()
curl = Command.call "curl"

sha256sum :: String -> IO Text
sha256sum file = T.take 64 <$> Command.run "sha256sum" [file]
