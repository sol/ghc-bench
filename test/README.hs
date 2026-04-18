module README (
  update
, ensureFile
) where

import Helper

import Data.List qualified as List
import Control.Exception
import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory)
import Data.ByteString (ByteString)
import Data.ByteString qualified as B
import Data.Text qualified as T
import Data.Text.IO.Utf8 qualified as Utf8
import Data.Set qualified as Set
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map

import Result
import SystemInfo

update :: [Result] -> IO ()
update results = do
      Utf8.readFile "README.md"
  >>= (updateResults results >>> encodeUtf8 >>> ensureFile "README.md")

updateResults :: [Result] -> Text -> Text
updateResults (resultTable -> results) = splitOutResultTable >>> \ case
  (prefix, (_results, suffix)) -> mconcat [prefix, "\n", results, "\n", suffix]
  where
    splitOutResultTable = T.breakOnEnd "## Benchmark results\n" >>> (<&> T.breakOn "## ")

type Configuration = (Cpu, Concurrency)

aggregateResults :: [Result] -> Map Configuration (Map Label [Seconds])
aggregateResults = Map.fromListWith (Map.unionWith mappend) . map resultTimes
  where
    resultTimes :: Result -> (Configuration, Map Label [Seconds])
    resultTimes result = (configuration, return <$> Map.fromList result.times)
      where
        configuration :: Configuration
        configuration = (result.system.cpu, result.concurrency)

resultTable :: [Result] -> Text
resultTable results = unlines $ map joinColumns table
  where
    table :: [[Text]]
    table = header : replicate (length header) "---" : map formatRow rows

    joinColumns :: [Text] -> Text
    joinColumns columns = mconcat ["| ", T.intercalate " | " columns, " |"]

    header :: [Text]
    header = "CPU" : map formatLabel labels

    rows :: [(Configuration, [Maybe Seconds])]
    rows = List.sortOn bar . map xxx $ Map.toList aggregated
      where
        bar :: (Configuration, [Maybe Seconds]) -> [Seconds]
        bar = map (fromMaybe maxBound) . snd

        xxx :: (Configuration, Map Label [Seconds]) -> (Configuration, [Maybe Seconds])
        xxx (c, Map.mapMaybe median -> times) = (c, foo)
          where
            foo = map (`Map.lookup` times) labels

    formatRow :: (Configuration, [Maybe Seconds]) -> [Text]
    formatRow ((cpu, _), times) = formatCpu cpu : map formatColumn times
      where
        formatColumn :: Maybe Seconds -> Text
        formatColumn = \ case
          Nothing -> "-"
          Just t -> formatTime t

    aggregated :: Map Configuration (Map Label [Seconds])
    aggregated = aggregateResults results

    labels :: [Label]
    labels = sortLabels . Set.toList . mconcat . map Map.keysSet $ Map.elems aggregated

    sortLabels :: [Label] -> [Label]
    sortLabels = List.sortOn p
      where
        p :: Label -> Maybe (Int, Label)
        p label = ($> label) <$> List.find pp labelOrder
          where
            pp :: (Int, Text) -> Bool
            pp (_, ppp) = T.isSuffixOf ppp (label.toText)

        labelOrder :: [(Int, Text)]
        labelOrder = zip [0..] [
            "ghc"
          , "-dependencies"
          , "-build"
          ]

ensureFile :: FilePath -> ByteString -> IO ()
ensureFile file new = do
  old <- try @IOException $ B.readFile file
  unless (old == Right new) do
    createDirectoryIfMissing True (takeDirectory file)
    B.writeFile file new

formatLabel :: Label -> Text
formatLabel = \ case
  "ghc-9.12.4" -> "[GHC 9.12.4 build](src/Benchmark/BuildGhc.hs)"
  "hedgehog-1.7-dependencies" -> "[hedgehog-1.7-dependencies](src/Benchmark/BuildCabalPackage.hs)"
  "hedgehog-1.7-build" -> "[hedgehog-1.7-dependencies](src/Benchmark/BuildCabalPackage.hs)"
  Label label -> label


formatCpu :: Cpu -> Text
formatCpu cpu = mconcat ["[", cpuName cpu, "](", pack $ basePath cpu,  ")"]

median :: [Seconds] -> Maybe Seconds
median = List.sort >>> \ case
  [] -> Nothing
  values -> Just $ values !! (length values `div` 2)
