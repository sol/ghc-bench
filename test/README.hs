module README where

import Data.Text qualified as T
import Data.Set qualified as Set
import Data.Set (Set)
import Data.List qualified as List
import Helper

import Control.Exception
import Data.Ord (comparing)
import Data.Yaml (ToJSON(..), object, (.=))
import Data.Yaml.Pretty qualified as Yaml
import Data.ByteString (ByteString)
import Data.ByteString qualified as B
import System.Directory (listDirectory, createDirectoryIfMissing)
import System.FilePath (takeDirectory)
import Data.Text.IO.Utf8 qualified as Utf8

import Fixtures.System qualified as System

import SystemInfo
import Result

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map

update :: [Result] -> IO ()
update results = do
  t <- Utf8.readFile "README.md"

  let
    (pre, xx) = T.breakOnEnd "## Benchmark results\n" t
    (_, post) = T.breakOn "## " xx

  ensureFile "README.md" . encodeUtf8 $ mconcat [
      pre
    , "\n"
    , mdTable results
    , "\n"
    , post
    ]

type Label = Text
type Seconds = Int
type Configuration = (Cpu, Concurrency)

type ResultMap = Map Label (Map Configuration [Seconds])

type Aggregation = Map Configuration (Map Label [Seconds])
type FinalAggregation = Map Configuration (Map Label Seconds)

median :: [Seconds] -> Maybe Seconds
median = List.sort >>> \ case
  [] -> Nothing
  xs -> Just $ xs !! (length xs `div` 2)

aggregateResults :: [Result] -> Map Configuration (Map Label [Seconds])
aggregateResults = Map.fromListWith bar . map foo
  where
    bar ::
      Map Label [Seconds]
      -> Map Label [Seconds]
      -> Map Label [Seconds]
    bar = Map.unionWith (++)

    foo :: Result -> (Configuration, Map Label [Seconds])
    foo result = (configuration, return <$> Map.fromList result.times)
      where
        configuration :: Configuration
        configuration = (result.system.cpu, result.concurrency)

mdTable :: [Result] -> Text
mdTable results = unlines $ map joinColumns xxx
  where
    joinColumns :: [Text] -> Text
    joinColumns columns = mconcat ["| ", T.intercalate " | " columns, " |"]

    xxx :: [[Text]]
    xxx = header : (replicate (length header) "---" ) : map formatRow rows

    header = "CPU" : map formatLabel labels

    rows :: [(Cpu, Map Text Int)]
    rows = List.sortOn f $ map (fmap $ Map.mapMaybe median) $ map (first fst) $ Map.toList aggregated
      where
        f :: (Cpu, Map Text Int) -> [Int]
        f (_, xs) = map g labels
          where
            g :: Text -> Int
            g l = Map.findWithDefault maxBound l xs

    formatRow :: (Cpu, Map Text Int) -> [Text]
    formatRow (cpu, times) = formatCpu cpu : map formatColumn labels
      where
        formatColumn :: Label -> Text
        formatColumn label = case Map.lookup label times of
          Nothing -> "-"
          Just t -> formatTime t

    aggregated :: Map Configuration (Map Label [Seconds])
    aggregated = aggregateResults results

    labels :: [Label]
    labels = Set.toList . mconcat . map Map.keysSet $ Map.elems aggregated

ensureFile :: FilePath -> ByteString -> IO ()
ensureFile file new = do
  old <- try @IOException $ B.readFile file
  unless (old == Right new) do
    createDirectoryIfMissing True (takeDirectory file)
    B.writeFile file new

formatLabel :: Text -> Text
formatLabel = \ case
  "ghc-9.12.4" -> "building GHC 9.12.4 with `--flavour=quickest`"
  label -> label

formatCpu :: Cpu -> Text
formatCpu cpu = mconcat ["[", cpuName cpu, "](", pack $ basePath cpu,  ")"]
