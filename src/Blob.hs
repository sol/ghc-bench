module Blob (
  requireAll
, download
, Blob(..)
) where

import Imports

import GHC.Fingerprint (getFileHash)
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
  actual <- show <$> getFileHash path
  when (actual /= hash) . error $ unlines [
      "hash mismatch!"
    , ""
    , "  url:      " <> pack url
    , "  file:     " <> pack path
    , "  expected: " <> hash
    , "  actual:   " <> actual
    ]

requireAll :: IO ()
requireAll = do
  Command.require "curl"

curl :: [String] -> IO ()
curl = Command.call "curl"
