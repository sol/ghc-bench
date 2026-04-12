{-# LANGUAGE CPP #-}
module Result (
  submit
, Result(..)
#ifdef TEST
, issueTitle
#endif
) where

import Imports

import Data.Text qualified as T
import Data.ByteString.Char8 (ByteString, putStrLn)
import Network.HTTP.Types.URI (renderSimpleQuery)

import SystemInfo

base :: ByteString
base = "https://github.com/sol/ghc-bench/issues/new"

data Result = Result {
  time :: Int
, concurrency :: Int
} deriving (Eq, Show)

submit :: Result -> SystemInfo -> IO ()
submit result system = do
  putStrLn "Open this URL to submit your result:"
  putStrLn $ issueUrl result system

issueUrl :: Result -> SystemInfo -> ByteString
issueUrl result system = base <> renderQuery [
    ("template", "benchmark-result.yml")
  , ("title", issueTitle result.time system)

  , ("time", show result.time)
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

  , ("ram", system.ram)
  ]
  where
    cpuid :: Text
    cpuid = T.intercalate " / " [
        fromMaybe "unknown" system.cpu.vendor
      , fromMaybe "unknown" system.cpu.family
      , fromMaybe "unknown" system.cpu.model
      , fromMaybe "unknown" system.cpu.stepping
      ]

issueTitle :: Int -> SystemInfo -> Text
issueTitle seconds system = unwords ["[result]", show seconds <> "s", "-", description, "-", cpu]
  where
    description :: Text
    description = unwords case (system.vendor, system.product.name) of
      ("LENOVO", _) -> [system.vendor, system.product.version]
      (unknown -> True, _) -> [system.product.category, "computer"]
      (vendor, unknown -> True) -> [vendor, system.product.category]
      (vendor, name) -> [vendor, name]

    unknown :: Text -> Bool
    unknown = (== "To Be Filled By O.E.M.")

    cpu :: Text
    cpu = case system.cpu.vendor of
      Just "GenuineIntel" -> case T.breakOn " @ " system.cpu.name of
        (name, _) -> T.replace "(TM)" "" $ T.replace "(R)" "" name
      _ -> system.cpu.name

renderQuery :: [(ByteString, Text)] -> ByteString
renderQuery = renderSimpleQuery True . map (fmap encodeUtf8)
