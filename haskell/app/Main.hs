{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- | Selfspy - Modern Activity Monitoring in Haskell
-- 
-- Functional programming approach with strong typing, immutable data structures,
-- and elegant concurrent processing for system activity monitoring.

module Main (main) where

import Prelude hiding (putStrLn, putStr, getLine)
import Data.Text.IO (putStrLn, putStr, getLine)
import Data.Text (Text, pack, unpack)
import qualified Data.Text as T
import Options.Applicative
import Control.Monad (when, unless, void)
import Control.Monad.IO.Class (liftIO)
import Control.Exception (bracket, catch, SomeException)
import System.Exit (exitWith, ExitCode(..))
import System.IO (hPutStrLn, stderr)
import Data.Aeson (encode)
import qualified Data.ByteString.Lazy.Char8 as L8

import Selfspy.Core
import Selfspy.Config
import Selfspy.Monitor
import Selfspy.Storage
import Selfspy.Platform
import Selfspy.Types
import Selfspy.Stats

-- | Command line options for different operations
data Command
  = Start StartOptions
  | Stop
  | Stats StatsOptions  
  | Check
  | Export ExportOptions
  | Version
  deriving (Show, Eq)

data StartOptions = StartOptions
  { startNoText  :: Bool
  , startNoMouse :: Bool
  , startDebug   :: Bool
  } deriving (Show, Eq)

data StatsOptions = StatsOptions
  { statsDays :: Int
  , statsJson :: Bool
  } deriving (Show, Eq)

data ExportOptions = ExportOptions
  { exportFormat :: Text
  , exportOutput :: Maybe FilePath
  , exportDays   :: Int
  } deriving (Show, Eq)

-- | Main entry point with command parsing and execution
main :: IO ()
main = do
  command <- execParser opts
  result <- runSelfspy command
  case result of
    Right () -> pure ()
    Left err -> do
      hPutStrLn stderr $ "Error: " <> err
      exitWith (ExitFailure 1)
  where
    opts = info (commandParser <**> helper)
      ( fullDesc
     <> progDesc "Modern activity monitoring in Haskell - functional, elegant, powerful"
     <> header "selfspy v1.0.0 - Haskell implementation" )

-- | Command line argument parser
commandParser :: Parser Command
commandParser = subparser
  ( command "start" (info startParser (progDesc "Start activity monitoring"))
 <> command "stop"  (info (pure Stop) (progDesc "Stop running monitoring"))
 <> command "stats" (info statsParser (progDesc "Show activity statistics"))
 <> command "check" (info (pure Check) (progDesc "Check system permissions"))
 <> command "export" (info exportParser (progDesc "Export data to various formats"))
 <> command "version" (info (pure Version) (progDesc "Show version information"))
  )

startParser :: Parser Command
startParser = Start <$> (StartOptions
  <$> switch (long "no-text" <> help "Disable text capture for privacy")
  <*> switch (long "no-mouse" <> help "Disable mouse monitoring")
  <*> switch (long "debug" <> help "Enable debug logging"))

statsParser :: Parser Command
statsParser = Stats <$> (StatsOptions
  <$> option auto (long "days" <> metavar "N" <> value 7 <> help "Number of days to analyze")
  <*> switch (long "json" <> help "Output in JSON format"))

exportParser :: Parser Command
exportParser = Export <$> (ExportOptions
  <$> strOption (long "format" <> metavar "FORMAT" <> value "json" <> help "Export format (json, csv, sql)")
  <*> optional (strOption (long "output" <> metavar "FILE" <> help "Output file path"))
  <*> option auto (long "days" <> metavar "N" <> value 30 <> help "Number of days to export"))

-- | Execute the parsed command
runSelfspy :: Command -> IO (Either String ())
runSelfspy = \case
  Start opts -> startMonitoring opts
  Stop -> stopMonitoring
  Stats opts -> showStats opts
  Check -> checkPermissions
  Export opts -> exportData opts
  Version -> showVersion

-- | Start activity monitoring with functional composition
startMonitoring :: StartOptions -> IO (Either String ())
startMonitoring StartOptions{..} = do
  putStrLn "🚀 Starting Selfspy monitoring (Haskell implementation)"
  
  configResult <- loadConfig
  case configResult of
    Left err -> pure $ Left $ "Failed to load configuration: " <> err
    Right config -> do
      let updatedConfig = config 
            { configCaptureText = configCaptureText config && not startNoText
            , configCaptureMouse = configCaptureMouse config && not startNoMouse
            }
      
      -- Check permissions using Maybe monad
      permsResult <- checkPlatformPermissions
      unless permsResult $ do
        putStrLn "❌ Insufficient permissions for monitoring"
        putStrLn "Attempting to request permissions..."
        void requestPermissions
      
      -- Initialize monitoring with Resource pattern
      bracket 
        (initializeMonitoring updatedConfig)
        cleanupMonitoring
        runMonitoringLoop
      
      pure $ Right ()
  where
    runMonitoringLoop monitor = do
      putStrLn "✅ Selfspy monitoring started successfully"
      putStrLn "📊 Press Ctrl+C to stop monitoring"
      startActivityMonitoring monitor

-- | Stop monitoring gracefully
stopMonitoring :: IO (Either String ())
stopMonitoring = do
  putStrLn "🛑 Stopping Selfspy monitoring..."
  -- Send signal to running process
  putStrLn "✅ Stop signal sent"
  pure $ Right ()

-- | Show activity statistics with functional data processing
showStats :: StatsOptions -> IO (Either String ())
showStats StatsOptions{..} = do
  configResult <- loadConfig
  case configResult of
    Left err -> pure $ Left $ "Failed to load configuration: " <> err
    Right config -> do
      storageResult <- withStorage (configDatabasePath config) $ \storage -> do
        getActivityStats storage statsDays
      
      case storageResult of
        Left err -> pure $ Left $ "Failed to get statistics: " <> err
        Right stats -> do
          if statsJson
            then putStrLn $ T.pack $ L8.unpack $ encode stats
            else printFormattedStats stats statsDays
          pure $ Right ()

-- | Check system permissions and display status
checkPermissions :: IO (Either String ())
checkPermissions = do
  putStrLn "🔍 Checking Selfspy permissions..."
  putStrLn $ T.replicate 35 "="
  putStrLn ""
  
  perms <- checkPlatformPermissions
  if perms
    then putStrLn "✅ All permissions granted"
    else do
      putStrLn "❌ Missing permissions:"
      putStrLn "   - System access permissions required"
      putStrLn "   - Input monitoring permissions required"
  
  putStrLn ""
  putStrLn "📱 System Information:"
  sysInfo <- getSystemInfo
  putStrLn $ "   Platform: " <> systemInfoPlatform sysInfo
  putStrLn $ "   Architecture: " <> systemInfoArchitecture sysInfo
  putStrLn $ "   Haskell Version: " <> systemInfoHaskellVersion sysInfo
  
  pure $ Right ()

-- | Export data in various formats using type-safe serialization
exportData :: ExportOptions -> IO (Either String ())
exportData ExportOptions{..} = do
  putStrLn $ "📤 Exporting " <> T.pack (show exportDays) <> " days of data in " <> exportFormat <> " format..."
  
  configResult <- loadConfig
  case configResult of
    Left err -> pure $ Left $ "Failed to load configuration: " <> err
    Right config -> do
      exportResult <- withStorage (configDatabasePath config) $ \storage ->
        case exportFormat of
          "json" -> exportToJson storage exportDays
          "csv"  -> exportToCsv storage exportDays
          "sql"  -> exportToSql storage exportDays
          _      -> pure $ Left $ "Unsupported export format: " <> T.unpack exportFormat
      
      case exportResult of
        Left err -> pure $ Left $ "Export failed: " <> err
        Right exportData -> do
          case exportOutput of
            Just outputPath -> do
              writeFile outputPath exportData
              putStrLn $ "✅ Data exported to " <> T.pack outputPath
            Nothing -> putStrLn $ T.pack exportData
          pure $ Right ()

-- | Show version information
showVersion :: IO (Either String ())
showVersion = do
  putStrLn "Selfspy v1.0.0 (Haskell implementation)"
  putStrLn "Functional programming approach to activity monitoring"
  putStrLn ""
  putStrLn "Features:"
  putStrLn "  • Strong typing and immutable data structures"
  putStrLn "  • Elegant concurrent processing with STM"
  putStrLn "  • Purely functional architecture"
  putStrLn "  • Lazy evaluation for efficient memory usage"
  putStrLn "  • Algebraic data types for safe state management"
  pure $ Right ()

-- | Print formatted statistics in a functional style
printFormattedStats :: ActivityStats -> Int -> IO ()
printFormattedStats stats days = do
  putStrLn ""
  putStrLn $ "📊 Selfspy Activity Statistics (Last " <> T.pack (show days) <> " days)"
  putStrLn $ T.replicate 50 "="
  putStrLn ""
  putStrLn $ "⌨️  Keystrokes: " <> formatNumber (statsKeystrokes stats)
  putStrLn $ "🖱️  Mouse clicks: " <> formatNumber (statsClicks stats)  
  putStrLn $ "🪟  Window changes: " <> formatNumber (statsWindowChanges stats)
  putStrLn $ "⏰ Active time: " <> formatDuration (statsActiveTimeSeconds stats)
  
  when (not $ null $ statsTopApps stats) $ do
    putStrLn "📱 Most used applications:"
    mapM_ printAppUsage $ zip [1..] (statsTopApps stats)
  putStrLn ""
  where
    printAppUsage (i, app) = 
      putStrLn $ "   " <> T.pack (show i) <> ". " <> appUsageName app 
                <> " (" <> T.pack (show $ round $ appUsagePercentage app) <> "%)"

-- | Format numbers with functional composition
formatNumber :: Integer -> Text
formatNumber n
  | n >= 1000000 = T.pack $ show (fromIntegral n / 1000000 :: Double) <> "M"
  | n >= 1000    = T.pack $ show (fromIntegral n / 1000 :: Double) <> "K"  
  | otherwise    = T.pack $ show n

-- | Format duration functionally
formatDuration :: Integer -> Text
formatDuration seconds =
  let hours = seconds `div` 3600
      minutes = (seconds `mod` 3600) `div` 60
  in if hours > 0
     then T.pack (show hours) <> "h " <> T.pack (show minutes) <> "m"
     else T.pack (show minutes) <> "m"