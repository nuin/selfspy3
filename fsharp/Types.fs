/// Core type definitions for Selfspy F# implementation
/// Leveraging F#'s excellent type system and discriminated unions

namespace Selfspy.Types

open System

/// Configuration with immutable record types
[<CLIMutable>]
type Config = {
    DataDir: string
    DatabasePath: string
    CaptureText: bool
    CaptureMouse: bool
    CaptureWindows: bool
    UpdateIntervalMs: int
    EncryptionEnabled: bool
    Debug: bool
    PrivacyMode: bool
    ExcludeApplications: string list
    MaxDatabaseSizeMb: int
}

/// Window information with comprehensive tracking
[<CLIMutable>]
type WindowInfo = {
    Title: string
    Application: string
    BundleId: string
    ProcessId: int
    X: int
    Y: int
    Width: int
    Height: int
    Timestamp: DateTime
}

/// Keyboard event with encryption support
[<CLIMutable>]
type KeyEvent = {
    Key: string
    Application: string
    ProcessId: int
    Count: int
    Encrypted: bool
    Timestamp: DateTime
}

/// Mouse event with detailed tracking
[<CLIMutable>]
type MouseEvent = {
    X: int
    Y: int
    Button: int
    EventType: string
    ProcessId: int
    Timestamp: DateTime
}

/// System permissions with granular control
[<CLIMutable>]
type Permissions = {
    Accessibility: bool
    InputMonitoring: bool
    ScreenRecording: bool
}

/// System information for diagnostics
[<CLIMutable>]
type SystemInfo = {
    Platform: string
    Architecture: string
    DotNetVersion: string
    FSharpVersion: string
    Hostname: string
    Username: string
}

/// Application usage statistics
[<CLIMutable>]
type AppUsage = {
    Name: string
    Percentage: float
    Duration: int64
    Events: int64
}

/// Comprehensive activity statistics
[<CLIMutable>]
type ActivityStats = {
    Keystrokes: int64
    Clicks: int64
    WindowChanges: int64
    ActiveTimeSeconds: int64
    TopApps: AppUsage list
    DateRange: DateTime * DateTime
}

/// Command line options with discriminated unions
type StartOptions = {
    NoText: bool
    NoMouse: bool
    Debug: bool
}

type StatsOptions = {
    Days: int
    Json: bool
}

type ExportOptions = {
    Format: string
    Output: string option
    Days: int
}

/// Main command types with pattern matching support
type Command =
    | Start of StartOptions
    | Stop
    | Stats of StatsOptions
    | Check
    | Export of ExportOptions
    | Version

/// Export format enumeration
type ExportFormat =
    | Json
    | Csv
    | Sql
    
    member this.ToString() =
        match this with
        | Json -> "json"
        | Csv -> "csv"
        | Sql -> "sql"

/// Monitor state for tracking
type MonitorState =
    | Stopped
    | Starting
    | Running
    | Stopping
    
    member this.IsActive =
        match this with
        | Running -> true
        | _ -> false

/// Storage operations result types
type StorageResult<'T> = Result<'T, string>

/// Platform detection helper
module Platform =
    let getCurrentPlatform () =
        match Environment.OSVersion.Platform with
        | PlatformID.Win32NT -> "windows"
        | PlatformID.Unix ->
            if System.IO.Directory.Exists("/System/Library") then "darwin"
            elif System.IO.Directory.Exists("/proc") then "linux"
            else "unix"
        | PlatformID.MacOSX -> "darwin"
        | _ -> "unknown"

/// Utility functions for data processing
module Utils =
    let formatNumber (num: int64) =
        if num >= 1_000_000L then
            sprintf "%.1fM" (float num / 1_000_000.0)
        elif num >= 1_000L then
            sprintf "%.1fK" (float num / 1_000.0)
        else
            string num
    
    let formatDuration (seconds: int64) =
        let hours = seconds / 3600L
        let minutes = (seconds % 3600L) / 60L
        
        if hours > 0L then
            sprintf "%dh %dm" hours minutes
        else
            sprintf "%dm" minutes
    
    let getCurrentTimestamp () = DateTime.UtcNow
    
    let toUnixTimestamp (dateTime: DateTime) =
        DateTimeOffset(dateTime).ToUnixTimeSeconds()
    
    let fromUnixTimestamp (timestamp: int64) =
        DateTimeOffset.FromUnixTimeSeconds(timestamp).DateTime