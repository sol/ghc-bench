{-# LANGUAGE CPP #-}
module Result (
  submit
, Result(..)
, Concurrency(..)
, parseFromIssueBody
, resultPath
, formatTime
, cpuName
, basePath

#ifdef TEST
, issueTitle
#endif
) where

import Imports hiding (product)
import Prelude qualified

import Data.Text qualified as T
import Data.ByteString.Char8 (ByteString, putStrLn)
import System.FilePath (joinPath)
import Network.HTTP.Types.URI (renderSimpleQuery)

import Command (Concurrency(..))
import SystemInfo

base :: ByteString
base = "https://github.com/sol/ghc-bench/issues/new"

data Result = Result {
  times :: [(Text, Int)]
, concurrency :: Concurrency
, system :: SystemInfo
} deriving (Eq, Show, Generic)

submit :: Result -> IO ()
submit result = do
  putStrLn "Open this URL to submit your result:"
  putStrLn $ "\n  " <> issueUrl result

issueUrl :: Result -> ByteString
issueUrl result = base <> renderQuery [
    ("template", "benchmark-result.yml")
  , ("title", issueTitle (sum $ map snd result.times) system)

  , ("times", formatTimes result.times)
  , ("concurrency", show result.concurrency)

  , ("os", system.os)
  , ("arch", system.arch)

  , ("system_vendor", system.vendor)

  , ("product_category", system.product.category)
  , ("product_chassis_type", system.product.chassis_type)
  , ("product_family", system.product.family)
  , ("product_name", system.product.name)
  , ("product_version", system.product.version)

  , ("board", unwords [system.board.vendor, system.board.name])

  , ("cpu_name", system.cpu.name)
  , ("cpu_cores", show system.cpu.cores)
  , ("cpu_threads", show system.cpu.threads)

  , ("cpuid", cpuid)

  , ("ram", show system.ram)
  ]
  where
    system :: SystemInfo
    system = result.system

    cpuid :: Text
    cpuid = T.intercalate " / " [
        fromMaybe "unknown" system.cpu.vendor
      , fromMaybe "unknown" system.cpu.family
      , fromMaybe "unknown" system.cpu.model
      , fromMaybe "unknown" system.cpu.stepping
      ]

issueTitle :: Int -> SystemInfo -> Text
issueTitle seconds system = unwords ["[result]", formatTime seconds, "-", description, "-", cpuName system.cpu]
  where
    description :: Text
    description = unwords case (system.vendor, system.product.name) of
      ("LENOVO", _) -> [system.vendor, system.product.version]
      (unknown -> True, _) -> [system.product.category, "computer"]
      (vendor, unknown -> True) -> [vendor, system.product.category]
      (vendor, name) -> [vendor, name]

cpuName :: Cpu -> Text
cpuName cpu = case cpu.vendor of
  Just "GenuineIntel" -> case T.breakOn " @ " cpu.name of
    (name, _) ->
        unwords
      . filter (/= "CPU")
      . words
      . tryStripPrefix "11th Gen "
      . T.replace "(R)" ""
      . T.replace "(TM)" " "
      $ name
  _ -> cpu.name

formatTime :: Int -> Text
formatTime seconds = case seconds `divMod` 60 of
  (0, s) -> show s <> "s"
  (m, s) -> mconcat [show seconds, "s (", show m, "m ", show s, "s)"]

unknown :: Text -> Bool
unknown = (== "To Be Filled By O.E.M.")

renderQuery :: [(ByteString, Text)] -> ByteString
renderQuery = renderSimpleQuery True . map (fmap encodeUtf8)

parseFromIssueBody :: Text -> Result
parseFromIssueBody markdown = Result {
    times = parseTimes $ get "Build times (seconds)"
  , concurrency = Concurrency $ int "Used number of threads"
  , system
  }
  where
    system :: SystemInfo
    system = SystemInfo {
        os = get "Operating System"
      , arch = get "Architecture"
      , vendor = get "System Vendor"
      , product
      , board
      , cpu
      , ram = int "RAM Size (GB)"
      }

    product :: Product
    product = Product {
        category = get "Product Category"
      , chassis_type = get "Chassis Type"
      , family = get "Product Family"
      , name = get "Product Name"
      , version = get "Product Version"
      }

    board :: Board
    board = case T.breakOnEnd " " $ get "Motherboard" of
      (strip -> vendor, name) -> Board {..}

    cpuid :: Text
    cpuid = get "CPUID (vendor / family / model / stepping)"

    cpu :: Cpu
    cpu = case map unknownToNothing $ T.splitOn " / " cpuid of
      [vendor, family, model, stepping] -> Cpu {
          name = get "CPU Name"
        , cores = int "Cores"
        , threads = int "Threads"
        , ..
        }
      _ -> Prelude.error $ "Invalid CPUID: " <> unpack cpuid

    unknownToNothing :: Text -> Maybe Text
    unknownToNothing "unknown" = Nothing
    unknownToNothing value = Just value

    get :: Text -> Text
    get key = case lookup key sections of
      Just value -> value
      Nothing -> Prelude.error $ "Missing field: " <> unpack key

    int :: Text -> Int
    int = read . get

    sections :: [(Text, Text)]
    sections = parseSections markdown

    parseSections :: Text -> [(Text, Text)]
    parseSections = map parseSection . reverse . drop 1 . T.splitOn "\n### "
      where
        parseSection :: Text -> (Text, Text)
        parseSection = bimap strip strip . T.break (== '\n') >>> \ case
          (key, "_No response_") -> (key, "")
          (key, value) -> (key, value)

formatTimes :: [(Text, Int)] -> Text
formatTimes = unwords . map \ case
  (name, time) -> mconcat [name, ":", show time]

parseTimes :: Text -> [(Text, Int)]
parseTimes = words >>> map parseTime
  where
    parseTime :: Text -> (Text, Int)
    parseTime = T.breakOn ":" >>> fmap (read . T.drop 1)

newtype Timestamp = Timestamp String
  deriving newtype (Eq, Show, Read, IsString)

resultPath :: Timestamp -> SystemInfo -> FilePath
resultPath (Timestamp timestamp) system = joinPathComponents path
  where
    path :: [Text]
    path = resultPath_ system.cpu ++  [file]

    file :: Text
    file = model <> "_" <> pack timestamp <> ".yaml"

    model :: Text
    model = T.intercalate "-"  case (system.vendor, system.product.name) of
      ("LENOVO", _) -> [tryStripPrefix "ThinkPad " system.product.version, system.product.name]
      (_, unknown -> True) -> [system.board.vendor, system.board.name]
      (_, name) -> [name]

basePath :: Cpu -> String
basePath = joinPathComponents . resultPath_

resultPath_ :: Cpu -> [Text]
resultPath_ cpu = "results" : vendor : cpuToPathComponents cpu
  where
    vendor :: Text
    vendor = case cpu.vendor of
      Just "GenuineIntel" -> "intel"
      Just "AuthenticAMD" -> "amd"
      Just name -> name
      Nothing -> "unknown"

cpuToPathComponents :: Cpu -> [Text]
cpuToPathComponents cpu = case (cpu.vendor, cpu.family, cpu.model, cpu.stepping) of
  (Just "GenuineIntel", Just "6", Just "165", Just "5") -> ["10th", T.take 9 $ T.drop 18 cpu.name]
  (Just "GenuineIntel", Just "6", Just "140", Just "1") -> ["11th", T.take 9 $ T.drop 27 cpu.name]
  (Just "GenuineIntel", Just "6", Just "23", Just "10") -> ["core_2", T.take 5 $ T.drop 31 cpu.name]
  _ -> ["unknown", T.replace " " "_" cpu.name]

joinPathComponents :: [Text] -> String
joinPathComponents = joinPath . sanitizePathComponents

sanitizePathComponent :: Text -> FilePath
sanitizePathComponent component = case sanitize component of
  "" -> "unknown"
  name -> name
  where
    sanitize = unpack . T.filter (/= '\0') . T.replace "/" "-" . T.intercalate "-" . T.words

sanitizePathComponents :: [Text] -> [FilePath]
sanitizePathComponents = map sanitizePathComponent

tryStripPrefix :: Text -> Text -> Text
tryStripPrefix prefix value = fromMaybe value $ T.stripPrefix prefix value
