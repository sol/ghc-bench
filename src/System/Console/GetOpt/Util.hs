module System.Console.GetOpt.Util where

import Prelude
import System.IO
import System.Exit
import System.Environment
import System.Console.GetOpt

evalWithHelp :: config -> [OptDescr (config -> config)] -> [String] -> IO (config, [String])
evalWithHelp defaults = evalIOWithHelp defaults . liftM

evalIOWithHelp :: config -> [OptDescr (config -> IO config)] -> [String] -> IO (config, [String])
evalIOWithHelp defaults = evalIO defaults . appendHelpOption

eval :: config -> [OptDescr (config -> config)] -> [String] -> IO (config, [String])
eval defaults = evalIO defaults . liftM

evalIO :: config -> [OptDescr (config -> IO config)] -> [String] -> IO (config, [String])
evalIO defaults options argv = case getOpt Permute options argv of
  (_, _, err : _) -> tryHelp err
  (opts, args, []) -> (,) <$> foldM defaults opts <*> pure args

liftM :: Monad m => [OptDescr (config -> config)] -> [OptDescr (config -> m config)]
liftM = map (fmap . fmap $ return)

foldM :: Monad m => config -> [config -> m config] -> m config
foldM = foldl' (>>=) . pure

fold :: config -> [config -> config] -> config
fold = foldl' (flip id)

printHelp :: [OptDescr a] -> IO ()
printHelp options = do
  name <- getProgName
  Prelude.putStr $ usageInfo ("Usage: " ++ name ++ " [OPTION]...\n\nOPTIONS") options

printHelpAndExit :: [OptDescr a] -> IO b
printHelpAndExit options = do
  printHelp options
  exitSuccess

tryHelp :: String -> IO a
tryHelp message = do
  name <- getProgName
  hPutStr stderr $ name ++ ": " ++ message ++ "Try `" ++ name ++ " --help' for more information.\n"
  exitFailure

appendHelpOption :: [OptDescr (a -> IO b)] -> [OptDescr (a -> IO b)]
appendHelpOption options = opts
  where
    opts = options ++ [helpOption opts]

helpOption :: [OptDescr a] -> OptDescr (t -> IO b)
helpOption options = Option [] ["help"] (NoArg \ _ -> printHelpAndExit options) "display this help and exit"
