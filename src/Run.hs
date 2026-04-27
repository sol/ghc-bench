module Run (
  main

, DryRun(..)
, PrintQR(..)
, parseOptions
, run
) where

import Imports

import Data.List qualified as List
import Data.Text.IO (putStr, putStrLn)
import System.Directory (getXdgDirectory, XdgDirectory(..), getTemporaryDirectory, createDirectoryIfMissing)
import System.Exit (die)

import Command qualified
import SystemInfo (Concurrency)
import SystemInfo qualified
import Blob (Blob(..))
import Blob qualified
import Result (Result(..), Label(..), Seconds)
import Result qualified
import Benchmark.Type (Benchmark, withLabel)
import Benchmark.Type qualified as Benchmark
import Benchmark.BuildGhc (Tarball(..))
import Benchmark.BuildGhc qualified as BuildGhc
import Benchmark.BuildCabalPackage qualified as BuildCabalPackage
import Benchmark.Ghci qualified as Ghci

version :: FilePath
version = "9.12.4"

ghc :: FilePath
ghc = "ghc-" <> version

sourceTarball :: FilePath -> Tarball
sourceTarball dir = Tarball {
    blob = Blob {
      url = "https://downloads.haskell.org/~ghc/" <> version <> "/ghc-" <> version <> "-src.tar.gz"
    , path = dir </> "ghc-" <> version <> "-src.tar.gz"
    , hash = "078e0272f52407601e24f054a1efc2c5"
    }
  , root = "ghc-" <> version
  }

cabalPackage :: FilePath
cabalPackage = "hedgehog-1.7"

ghciPackage :: FilePath
ghciPackage = "containers-0.8"

data DryRun = NoDryRun | DryRun
  deriving (Eq, Show, Bounded)

data PrintQR = NoPrintQR | PrintQR
  deriving (Eq, Show, Bounded)

parseOptions :: [FilePath] -> (DryRun, (PrintQR, [FilePath]))
parseOptions = fmap parsePrintQR . parseDryRun

parseDryRun :: [FilePath] -> (DryRun, [FilePath])
parseDryRun = parseOption "dry-run"

parsePrintQR :: [FilePath] -> (PrintQR, [FilePath])
parsePrintQR = parseOption "qr"

parseOption :: Bounded a => String -> [String] -> (a, [String])
parseOption name = List.partition (== "--" <> name) >>> first \ case
  [] -> minBound
  _ -> maxBound

main :: [String] -> IO ()
main (parseOptions -> (dryRun, (printQR, args))) = do

  cacheDir <- getXdgDirectory XdgCache "ghc-bench"
  createDirectoryIfMissing True cacheDir
  baseDir <- getTemporaryDirectory <&> (</> "ghc-bench")
  createDirectoryIfMissing False baseDir

  qrencode <- case printQR of
    NoPrintQR -> do
      return Nothing
    PrintQR -> do
      let command = "qrencode"
      Command.require command
      return $ Just (\ url -> Command.call command ["-t", "ANSIUTF8", url])

  Blob.requireAll
  SystemInfo.requireAll
  stage0 <- Command.resolve ghc
  system <- SystemInfo.collect
  concurrency <- SystemInfo.nproc

  putStr . unlines $ "" : SystemInfo.pretty system

  times <- run cacheDir (withTempDirectory baseDir "build") dryRun args stage0 concurrency
  unless (null times) do
    putStrLn "\ntimes:"
    for_ times \ (Label name, time) -> do
      putStrLn $ "  " <> name <> ": " <> (Result.formatTime time)

    putStrLn ""
    Result.submit Result {..} qrencode

type WithTempDirectory = forall a. (FilePath -> IO a) -> IO a

run :: FilePath -> WithTempDirectory -> DryRun -> [String] -> FilePath -> Concurrency -> IO [(Label, Seconds)]
run cacheDir withTemp dryRun args stage0 concurrency = requireDependencies >> case args of
  [] -> runAll
  [name] | Just action <- lookup name actions -> action
  _ -> die usage
  where
    source :: Tarball
    source = sourceTarball cacheDir

    requireDependencies :: IO ()
    requireDependencies = for_ dependencies Command.require

    dependencies :: [FilePath]
    dependencies = List.nub $ concatMap (Benchmark.dependencies . snd) benchmarkActions

    benchmarkActions :: [(String, Benchmark ())]
    benchmarkActions = [
        ("ghc", withLabel ghc $ BuildGhc.run source stage0 concurrency)
      , ("cabal", withLabel cabalPackage $ BuildCabalPackage.run cabalPackage ghc concurrency)
      , ("ghci", withLabel ghciPackage $ Ghci.run ghciPackage ghc concurrency)
      ]

    runAll :: IO [(Label, Seconds)]
    runAll = concat <$> sequence (map snd actions)

    actions :: [(String, IO [(Label, Seconds)])]
    actions = map (fmap $ withTemp . runBenchmark dryRun) benchmarkActions

    usage :: FilePath
    usage = "\nusage: ghc-bench [ " <> List.intercalate " | " (map fst actions) <> " ] [ --dry-run ]"

runBenchmark :: DryRun -> Benchmark () -> FilePath -> IO [(Label, Seconds)]
runBenchmark dryRun action dir = case dryRun of
  NoDryRun -> Benchmark.run $ Benchmark.cd dir action
  DryRun -> Benchmark.dryRun $ Benchmark.cd dir action
