/// Configuration management for Selfspy F# implementation
namespace Selfspy.Config

open System
open System.IO
open Selfspy.Types

/// Configuration loading with async workflows
module ConfigLoader =
    
    let getDefaultDataDir () =
        let homeDir = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)
        match Platform.getCurrentPlatform() with
        | "windows" -> Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "selfspy")
        | "darwin" -> Path.Combine(homeDir, "Library", "Application Support", "selfspy")
        | _ -> Path.Combine(homeDir, ".local", "share", "selfspy")
    
    let createDefaultConfig () =
        let dataDir = getDefaultDataDir()
        {
            DataDir = dataDir
            DatabasePath = Path.Combine(dataDir, "selfspy.db")
            CaptureText = true
            CaptureMouse = true
            CaptureWindows = true
            UpdateIntervalMs = 100
            EncryptionEnabled = true
            Debug = false
            PrivacyMode = false
            ExcludeApplications = []
            MaxDatabaseSizeMb = 500
        }

let loadConfig () : Async<Config> =
    async {
        let config = ConfigLoader.createDefaultConfig()
        
        // Ensure data directory exists
        if not (Directory.Exists(config.DataDir)) then
            Directory.CreateDirectory(config.DataDir) |> ignore
        
        return config
    }