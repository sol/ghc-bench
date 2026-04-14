module System.Process.Extra (
  module System.Process
, callCreateProcess
) where

import Prelude
import System.Process as System.Process

import GHC.IO.Exception (IOErrorType(..))
import System.IO.Error (mkIOError)
import System.Exit (ExitCode(..))
import System.IO
import Control.Exception qualified as C

-- https://github.com/haskell/process/pull/358
callCreateProcess :: CreateProcess -> IO ()
callCreateProcess command = do
    exit_code <- withCreateProcess_ "callCreateProcess"
                   command $ \_ _ _ p ->
                   waitForProcess p
    case exit_code of
      ExitSuccess   -> return ()
      ExitFailure r -> processFailed "callCreateProcess" (cmdspec command) r

processFailed :: String -> CmdSpec -> Int -> IO a
processFailed fun = \ case
  ShellCommand cmd -> processFailedException fun cmd []
  RawCommand cmd args -> processFailedException fun cmd args

withCreateProcess_
  :: String
  -> CreateProcess
  -> (Maybe Handle -> Maybe Handle -> Maybe Handle -> ProcessHandle -> IO a)
  -> IO a
withCreateProcess_ fun c action =
    C.bracketOnError (createProcess_ fun c) cleanupProcess
                     (\(m_in, m_out, m_err, ph) -> action m_in m_out m_err ph)

processFailedException :: String -> String -> [String] -> Int -> IO a
processFailedException fun cmd args exit_code =
      ioError (mkIOError OtherError (fun ++ ": " ++ cmd ++
                                     concatMap ((' ':) . show) args ++
                                     " (exit " ++ show exit_code ++ ")")
                                 Nothing Nothing)
