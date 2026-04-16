module SystemInfo (
  collect
, SystemInfo(..)
, Product(..)
, Board(..)
, Cpu(..)
) where

import Imports hiding (product)

import Data.List (nub)
import Control.Exception

import Data.Text qualified as T
import Data.Text.IO.Utf8 qualified as Utf8

import Command (eval, uname, lscpu, free, awk)

data SystemInfo = SystemInfo {
  os :: Text
, arch :: Text
, vendor :: Text
, product :: Product
, board :: Board
, cpu :: Cpu
, ram :: Int
} deriving (Eq, Show, Generic)

collect :: IO SystemInfo
collect = do
  os <- eval ". /etc/os-release && echo $NAME || uname" <&> strip
  arch <- uname ["--machine"]
  vendor <- fromFile "/sys/class/dmi/id/sys_vendor"
  product <- getProductInfo
  board <- getBoardInfo
  cpu <- getCpuInfo
  ram <- free ["-b"] >>= awk "/Mem:/ {print $2}" <&> toGb . read . strip
  return SystemInfo {..}
  where
    toGb :: Int -> Int
    toGb bytes = case ceiling @Double $ fromIntegral bytes / 1024 / 1024 / 1024 of
      31 -> 32 -- adjust for reserved ram that is not visible to the os
      n -> n

data Product = Product {
  category :: Text
, chassis_type :: Text
, family :: Text
, name :: Text
, version :: Text
} deriving (Eq, Show, Generic)

getProductInfo :: IO Product
getProductInfo = do
  chassis_type <- fromFile "/sys/class/dmi/id/chassis_type"
  family <- fromFile "/sys/class/dmi/id/product_family"
  name <- fromFile "/sys/class/dmi/id/product_name"
  version <- fromFile "/sys/class/dmi/id/product_version"
  return Product {
      category = interpretChassisType chassis_type
    , ..
    }

interpretChassisType :: Text -> Text
interpretChassisType = \ case
  "3" -> "desktop"
  "4" -> "desktop"
  "8" -> "laptop"
  "9" -> "laptop"
  "10" -> "laptop"
  "14" -> "laptop"
  _ -> "unknown"

data Board = Board {
  vendor :: Text
, name :: Text
} deriving (Eq, Show, Generic)

getBoardInfo :: IO Board
getBoardInfo = do
  vendor <- fromFile "/sys/class/dmi/id/board_vendor"
  name <- fromFile "/sys/class/dmi/id/board_name"
  return Board {..}

data Cpu = Cpu {
  name :: Text
, cores :: Int
, threads :: Int
, vendor :: Maybe Text
, family :: Maybe Text
, model :: Maybe Text
, stepping :: Maybe Text
} deriving (Eq, Ord, Show, Generic)

getCpuInfo :: IO Cpu
getCpuInfo = do
  threads <- lscpu ["-p=SOCKET,CORE,CPU,MODELNAME"] <&> parse
  let
    cpus  = nub [(socket, name) | (socket, _, _, name) <- threads]
    cores = nub [(socket, core) | (socket, core, _, _) <- threads]
  fields <- lscpu [] <&> parseFields
  return Cpu {
      name = T.intercalate " / " $ map snd cpus
    , cores = length cores
    , threads = length threads
    , vendor = lookup "Vendor ID" fields
    , family = lookup "CPU family" fields
    , model = lookup "Model" fields
    , stepping = lookup "Stepping" fields
    }
  where
    parse :: Text -> [(Text, Text, Text, Text)]
    parse = mapMaybe parseLine . removeComments . lines

    parseLine :: Text -> Maybe (Text, Text, Text, Text)
    parseLine = T.splitOn "," >>> \ case
      socket : core : thread : name -> Just (socket, core, thread, T.intercalate "," name)
      _ -> Nothing

    removeComments :: [Text] -> [Text]
    removeComments = filter (not . T.isPrefixOf "#")

    parseFields :: Text -> [(Text, Text)]
    parseFields = map parseField . lines

    parseField :: Text -> (Text, Text)
    parseField = fmap (strip . T.drop 1) . T.breakOn ": "

fromFile :: FilePath -> IO Text
fromFile p = try @IOException (Utf8.readFile p) <&> \ case
  Left _ -> "unknown"
  Right c -> strip c
