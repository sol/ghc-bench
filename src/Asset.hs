module Asset (
  download
, Asset(..)
) where

import Imports

import System.Directory (doesFileExist, renameFile)

import Command (curl, sha256sum)

data Asset = Asset {
  url :: FilePath
, path :: FilePath
, hash :: Text
} deriving (Eq, Show)

download :: Asset -> IO ()
download asset = do
  ensure asset.url asset.path
  verify asset.path asset.hash

ensure :: FilePath -> FilePath -> IO ()
ensure url path = unless -< doesFileExist path $ do
  let tmp = path <> ".tmp"
  curl ["-L", url, "-o", tmp]
  renameFile tmp path

verify :: FilePath -> Text -> IO ()
verify path expected = do
  actual <- sha256sum path
  when (actual /= expected) . error $ unlines [
      "SHA256 mismatch!"
    , "Expected: " <> expected
    , "Actual:   " <> actual
    ]
