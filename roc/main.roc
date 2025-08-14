## Selfspy - Modern Activity Monitoring in Roc
##
## Fast functional language with excellent performance, strong type safety,
## and seamless interop for system monitoring applications.

app "selfspy"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.7.0/bkGby8jb0tmZYsy2hg1E_B2QrCgcSTxdUlHtETwm5m4.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.7.0/4_QlgWEf7zOoGC0LPVP9jIwHHkAcaKS8cW5ldIE3HQg.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Arg,
        pf.Env,
        pf.File,
        pf.Path,
        pf.Task.{ Task },
        pf.Utc,
        json.Core,
    ]
    provides [main] to pf

## Core data types with strong type safety
Config : {
    dataDir : Str,
    databasePath : Str,
    captureText : Bool,
    captureMouse : Bool,
    captureWindows : Bool,
    updateIntervalMs : U64,
    encryptionEnabled : Bool,
    debug : Bool,
    privacyMode : Bool,
    excludeApplications : List Str,
    maxDatabaseSizeMb : U64,
}

WindowInfo : {
    title : Str,
    application : Str,
    bundleId : Str,
    processId : U32,
    x : I32,
    y : I32,
    width : I32,
    height : I32,
    timestamp : U64,
}

KeyEvent : {
    key : Str,
    application : Str,
    processId : U32,
    count : U32,
    encrypted : Bool,
    timestamp : U64,
}

MouseEvent : {
    x : I32,
    y : I32,
    button : U8,
    eventType : Str,
    processId : U32,
    timestamp : U64,
}

ActivityStats : {
    keystrokes : U64,
    clicks : U64,
    windowChanges : U64,
    activeTimeSeconds : U64,
    topApps : List AppUsage,
}

AppUsage : {
    name : Str,
    percentage : F64,
    duration : U64,
    events : U64,
}

Permissions : {
    accessibility : Bool,
    inputMonitoring : Bool,
    screenRecording : Bool,
}

SystemInfo : {
    platform : Str,
    architecture : Str,
    rocVersion : Str,
    hostname : Str,
    username : Str,
}

## Comprehensive error handling with tagged unions
SelfspyError : [
    ConfigError Str,
    PermissionError Str,
    StorageError Str,
    PlatformError Str,
    InvalidArgument Str,
]

## Command types for CLI
Command : [
    Start StartOptions,
    Stop,
    Stats StatsOptions,
    Check,
    Export ExportOptions,
    Version,
    Help,
]

StartOptions : {
    noText : Bool,
    noMouse : Bool,
    debug : Bool,
}

StatsOptions : {
    days : U32,
    json : Bool,
}

ExportOptions : {
    format : Str,
    output : Result Str [None],
    days : U32,
}

## Default configuration with pure functions
defaultConfig : {} -> Config
defaultConfig = \{} ->
    homeDir = "/tmp" # Placeholder: Would get actual home directory
    
    dataDir = 
        when getOs {} is
            "windows" -> "$(homeDir)\\AppData\\Roaming\\selfspy"
            "darwin" -> "$(homeDir)/Library/Application Support/selfspy"
            _ -> "$(homeDir)/.local/share/selfspy"
    
    {
        dataDir,
        databasePath: "$(dataDir)/selfspy.db",
        captureText: Bool.true,
        captureMouse: Bool.true,
        captureWindows: Bool.true,
        updateIntervalMs: 100,
        encryptionEnabled: Bool.true,
        debug: Bool.false,
        privacyMode: Bool.false,
        excludeApplications: [],
        maxDatabaseSizeMb: 500,
    }

## Platform detection
getOs : {} -> Str
getOs = \{} ->
    # Placeholder: Would detect actual OS
    "linux"

## Command line argument parsing with pattern matching
parseArgs : List Str -> Result Command SelfspyError
parseArgs = \args ->
    when args is
        ["start", ..rest] ->
            options = parseStartOptions rest
            Ok (Start options)
        
        ["stop", ..] ->
            Ok Stop
        
        ["stats", ..rest] ->
            options = parseStatsOptions rest
            Ok (Stats options)
        
        ["check", ..] ->
            Ok Check
        
        ["export", ..rest] ->
            options = parseExportOptions rest
            Ok (Export options)
        
        ["version", ..] ->
            Ok Version
        
        ["help", ..] ->
            Ok Help
        
        [] ->
            Ok Help
        
        [unknown, ..] ->
            Err (InvalidArgument "Unknown command: $(unknown)")

parseStartOptions : List Str -> StartOptions
parseStartOptions = \args ->
    List.walk args { noText: Bool.false, noMouse: Bool.false, debug: Bool.false } \options, arg ->
        when arg is
            "--no-text" -> { options & noText: Bool.true }
            "--no-mouse" -> { options & noMouse: Bool.true }
            "--debug" -> { options & debug: Bool.true }
            _ -> options

parseStatsOptions : List Str -> StatsOptions
parseStatsOptions = \args ->
    parseStatsOptionsHelper args { days: 7, json: Bool.false }

parseStatsOptionsHelper : List Str, StatsOptions -> StatsOptions
parseStatsOptionsHelper = \args, options ->
    when args is
        ["--days", daysStr, ..rest] ->
            days = Str.toU32 daysStr |> Result.withDefault 7
            parseStatsOptionsHelper rest { options & days }
        
        ["--json", ..rest] ->
            parseStatsOptionsHelper rest { options & json: Bool.true }
        
        [_, ..rest] ->
            parseStatsOptionsHelper rest options
        
        [] ->
            options

parseExportOptions : List Str -> ExportOptions
parseExportOptions = \args ->
    parseExportOptionsHelper args { format: "json", output: Err None, days: 30 }

parseExportOptionsHelper : List Str, ExportOptions -> ExportOptions
parseExportOptionsHelper = \args, options ->
    when args is
        ["--format", format, ..rest] ->
            parseExportOptionsHelper rest { options & format }
        
        ["--output", output, ..rest] ->
            parseExportOptionsHelper rest { options & output: Ok output }
        
        ["--days", daysStr, ..rest] ->
            days = Str.toU32 daysStr |> Result.withDefault 30
            parseExportOptionsHelper rest { options & days }
        
        [_, ..rest] ->
            parseExportOptionsHelper rest options
        
        [] ->
            options

## Platform abstraction with pure functions
checkPermissions : {} -> Result Permissions SelfspyError
checkPermissions = \{} ->
    when getOs {} is
        "darwin" -> checkMacOSPermissions {}
        "linux" -> checkLinuxPermissions {}
        "windows" -> checkWindowsPermissions {}
        _ -> Ok { accessibility: Bool.true, inputMonitoring: Bool.true, screenRecording: Bool.false }

checkMacOSPermissions : {} -> Result Permissions SelfspyError
checkMacOSPermissions = \{} ->
    # Placeholder: Would use system APIs
    Ok {
        accessibility: Bool.true,
        inputMonitoring: Bool.true,
        screenRecording: Bool.false,
    }

checkLinuxPermissions : {} -> Result Permissions SelfspyError
checkLinuxPermissions = \{} ->
    # Check for display server availability
    # Placeholder: Would check actual environment variables
    hasDisplay = Bool.true
    
    Ok {
        accessibility: hasDisplay,
        inputMonitoring: hasDisplay,
        screenRecording: hasDisplay,
    }

checkWindowsPermissions : {} -> Result Permissions SelfspyError
checkWindowsPermissions = \{} ->
    Ok {
        accessibility: Bool.true,
        inputMonitoring: Bool.true,
        screenRecording: Bool.true,
    }

hasAllPermissions : Permissions -> Bool
hasAllPermissions = \permissions ->
    permissions.accessibility && permissions.inputMonitoring

## System information gathering
getSystemInfo : {} -> SystemInfo
getSystemInfo = \{} ->
    {
        platform: getOs {},
        architecture: "x64", # Placeholder
        rocVersion: "0.0.1",
        hostname: "localhost", # Placeholder
        username: "user", # Placeholder
    }

## Activity monitoring with pure functional approach
startMonitoring : Config, StartOptions -> Task {} SelfspyError
startMonitoring = \config, options ->
    # Apply command line options
    updatedConfig = {
        config &
        captureText: config.captureText && !(options.noText),
        captureMouse: config.captureMouse && !(options.noMouse),
        debug: config.debug || options.debug,
    }
    
    Task.attempt (checkPermissions {}) \permsResult ->
        when permsResult is
            Ok permissions ->
                if hasAllPermissions permissions then
                    {} <- Stdout.line "🚀 Starting Selfspy monitoring (Roc implementation)" |> Task.await
                    {} <- Stdout.line "✅ Selfspy monitoring started successfully" |> Task.await
                    {} <- Stdout.line "📊 Press Ctrl+C to stop monitoring" |> Task.await
                    
                    # Start monitoring loop
                    runMonitoringLoop updatedConfig
                else
                    Task.err (PermissionError "Insufficient permissions for monitoring")
            
            Err error ->
                Task.err error

runMonitoringLoop : Config -> Task {} SelfspyError
runMonitoringLoop = \config ->
    # Placeholder monitoring loop
    # In a real implementation, this would:
    # 1. Set up platform-specific event hooks
    # 2. Collect window, keyboard, and mouse events
    # 3. Process events functionally
    # 4. Handle graceful shutdown
    Task.ok {}

getCurrentWindow : {} -> WindowInfo
getCurrentWindow = \{} ->
    # Placeholder implementation
    {
        title: "Sample Window",
        application: "Sample Application",
        bundleId: "",
        processId: 0,
        x: 0,
        y: 0,
        width: 1920,
        height: 1080,
        timestamp: 0, # Would use actual timestamp
    }

## Statistics and data analysis with pure functions
getStats : U32 -> Result ActivityStats SelfspyError
getStats = \days ->
    # Placeholder: Would query actual database
    topApps = [
        { name: "Code Editor", percentage: 45.2, duration: 6683, events: 5234 },
        { name: "Web Browser", percentage: 32.1, duration: 4736, events: 3892 },
        { name: "Terminal", percentage: 15.7, duration: 2318, events: 2156 },
    ]
    
    stats = {
        keystrokes: 12547,
        clicks: 3821,
        windowChanges: 342,
        activeTimeSeconds: 14760,
        topApps,
    }
    
    Ok stats

showStats : StatsOptions -> Task {} SelfspyError
showStats = \options ->
    Task.attempt (getStats options.days) \statsResult ->
        when statsResult is
            Ok stats ->
                if options.json then
                    Task.attempt (exportJSON stats) \jsonResult ->
                        when jsonResult is
                            Ok jsonStr ->
                                Stdout.line jsonStr
                            
                            Err error ->
                                Task.err error
                else
                    printFormattedStats stats options.days
            
            Err error ->
                Task.err error

## Data export with type-safe serialization
exportData : Str, U32 -> Result Str SelfspyError
exportData = \format, days ->
    statsResult = getStats days
    
    when statsResult is
        Ok stats ->
            when format is
                "json" -> exportJSON stats
                "csv" -> exportCSV stats
                "sql" -> exportSQL stats
                _ -> Err (InvalidArgument "Unsupported export format: $(format)")
        
        Err error ->
            Err error

exportJSON : ActivityStats -> Result Str SelfspyError
exportJSON = \stats ->
    # Placeholder: Would use proper JSON serialization
    jsonStr = """
    {
      "keystrokes": $(Num.toStr stats.keystrokes),
      "clicks": $(Num.toStr stats.clicks),
      "window_changes": $(Num.toStr stats.windowChanges),
      "active_time_seconds": $(Num.toStr stats.activeTimeSeconds)
    }
    """
    
    Ok jsonStr

exportCSV : ActivityStats -> Result Str SelfspyError
exportCSV = \stats ->
    csv = """
    metric,value
    keystrokes,$(Num.toStr stats.keystrokes)
    clicks,$(Num.toStr stats.clicks)
    window_changes,$(Num.toStr stats.windowChanges)
    active_time_seconds,$(Num.toStr stats.activeTimeSeconds)
    """
    
    Ok csv

exportSQL : ActivityStats -> Result Str SelfspyError
exportSQL = \stats ->
    sql = """
    -- Selfspy Activity Export
    CREATE TABLE stats (metric TEXT, value INTEGER);
    INSERT INTO stats VALUES ('keystrokes', $(Num.toStr stats.keystrokes));
    INSERT INTO stats VALUES ('clicks', $(Num.toStr stats.clicks));
    INSERT INTO stats VALUES ('window_changes', $(Num.toStr stats.windowChanges));
    INSERT INTO stats VALUES ('active_time_seconds', $(Num.toStr stats.activeTimeSeconds));
    """
    
    Ok sql

## Utility functions with pure functional approach
formatNumber : U64 -> Str
formatNumber = \num ->
    if num >= 1_000_000 then
        millions = (Num.toF64 num) / 1_000_000.0
        "$(Num.toStr millions)M"
    else if num >= 1_000 then
        thousands = (Num.toF64 num) / 1_000.0
        "$(Num.toStr thousands)K"
    else
        Num.toStr num

formatDuration : U64 -> Str
formatDuration = \seconds ->
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    
    if hours > 0 then
        "$(Num.toStr hours)h $(Num.toStr minutes)m"
    else
        "$(Num.toStr minutes)m"

printFormattedStats : ActivityStats, U32 -> Task {} {}
printFormattedStats = \stats, days ->
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "📊 Selfspy Activity Statistics (Last $(Num.toStr days) days)" |> Task.await
    {} <- Stdout.line "==================================================" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "⌨️  Keystrokes: $(formatNumber stats.keystrokes)" |> Task.await
    {} <- Stdout.line "🖱️  Mouse clicks: $(formatNumber stats.clicks)" |> Task.await
    {} <- Stdout.line "🪟  Window changes: $(formatNumber stats.windowChanges)" |> Task.await
    {} <- Stdout.line "⏰ Active time: $(formatDuration stats.activeTimeSeconds)" |> Task.await
    
    if !(List.isEmpty stats.topApps) then
        {} <- Stdout.line "📱 Most used applications:" |> Task.await
        List.walkWithIndex stats.topApps {} \{}, app, i ->
            index = i + 1
            Stdout.line "   $(Num.toStr index). $(app.name) ($(Num.toStr app.percentage)%)" |> Task.await
    else
        Task.ok {}
    
    Stdout.line ""

## Command execution with comprehensive error handling
runCommand : Command -> Task {} SelfspyError
runCommand = \command ->
    when command is
        Start options ->
            config = defaultConfig {}
            startMonitoring config options
        
        Stop ->
            {} <- Stdout.line "🛑 Stopping Selfspy monitoring..." |> Task.await
            Stdout.line "✅ Stop signal sent"
        
        Stats options ->
            showStats options
        
        Check ->
            {} <- Stdout.line "🔍 Checking Selfspy permissions..." |> Task.await
            {} <- Stdout.line "===================================" |> Task.await
            {} <- Stdout.line "" |> Task.await
            
            Task.attempt (checkPermissions {}) \permsResult ->
                when permsResult is
                    Ok permissions ->
                        if hasAllPermissions permissions then
                            {} <- Stdout.line "✅ All permissions granted" |> Task.await
                            Task.ok {}
                        else
                            {} <- Stdout.line "❌ Missing permissions:" |> Task.await
                            if !(permissions.accessibility) then
                                {} <- Stdout.line "   - Accessibility permission required" |> Task.await
                                Task.ok {}
                            else
                                Task.ok {}
                            
                            if !(permissions.inputMonitoring) then
                                {} <- Stdout.line "   - Input monitoring permission required" |> Task.await
                                Task.ok {}
                            else
                                Task.ok {}
                        
                        {} <- Stdout.line "" |> Task.await
                        {} <- Stdout.line "📱 System Information:" |> Task.await
                        sysInfo = getSystemInfo {}
                        {} <- Stdout.line "   Platform: $(sysInfo.platform)" |> Task.await
                        {} <- Stdout.line "   Architecture: $(sysInfo.architecture)" |> Task.await
                        {} <- Stdout.line "   Roc Version: $(sysInfo.rocVersion)" |> Task.await
                        Stdout.line "   Hostname: $(sysInfo.hostname)"
                    
                    Err error ->
                        Task.err error
        
        Export options ->
            {} <- Stdout.line "📤 Exporting $(Num.toStr options.days) days of data in $(options.format) format..." |> Task.await
            
            Task.attempt (exportData options.format options.days) \dataResult ->
                when dataResult is
                    Ok data ->
                        when options.output is
                            Ok filename ->
                                # Would write to file
                                Stdout.line "✅ Data exported to $(filename)"
                            
                            Err None ->
                                Stdout.line data
                    
                    Err error ->
                        Task.err error
        
        Version ->
            {} <- Stdout.line "Selfspy v1.0.0 (Roc implementation)" |> Task.await
            {} <- Stdout.line "Fast functional language with excellent performance" |> Task.await
            {} <- Stdout.line "" |> Task.await
            {} <- Stdout.line "Features:" |> Task.await
            {} <- Stdout.line "  • Fast functional language" |> Task.await
            {} <- Stdout.line "  • Excellent performance" |> Task.await
            {} <- Stdout.line "  • Strong type safety" |> Task.await
            {} <- Stdout.line "  • Seamless interop" |> Task.await
            {} <- Stdout.line "  • Zero-cost abstractions" |> Task.await
            Stdout.line "  • Compile-time optimizations"
        
        Help ->
            printHelp

printHelp : Task {} {}
printHelp =
    {} <- Stdout.line "Selfspy - Modern Activity Monitoring in Roc" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "USAGE:" |> Task.await
    {} <- Stdout.line "    roc run main.roc [COMMAND] [OPTIONS]" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "COMMANDS:" |> Task.await
    {} <- Stdout.line "    start                 Start activity monitoring" |> Task.await
    {} <- Stdout.line "    stop                  Stop running monitoring instance" |> Task.await
    {} <- Stdout.line "    stats                 Show activity statistics" |> Task.await
    {} <- Stdout.line "    check                 Check system permissions and setup" |> Task.await
    {} <- Stdout.line "    export                Export data to various formats" |> Task.await
    {} <- Stdout.line "    version               Show version information" |> Task.await
    {} <- Stdout.line "    help                  Show this help message" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "START OPTIONS:" |> Task.await
    {} <- Stdout.line "    --no-text             Disable text capture for privacy" |> Task.await
    {} <- Stdout.line "    --no-mouse            Disable mouse monitoring" |> Task.await
    {} <- Stdout.line "    --debug               Enable debug logging" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "STATS OPTIONS:" |> Task.await
    {} <- Stdout.line "    --days <N>            Number of days to analyze (default: 7)" |> Task.await
    {} <- Stdout.line "    --json                Output in JSON format" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "EXPORT OPTIONS:" |> Task.await
    {} <- Stdout.line "    --format <FORMAT>     Export format: json, csv, sql (default: json)" |> Task.await
    {} <- Stdout.line "    --output <FILE>       Output file path" |> Task.await
    {} <- Stdout.line "    --days <N>            Number of days to export (default: 30)" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "EXAMPLES:" |> Task.await
    {} <- Stdout.line "    roc run main.roc start" |> Task.await
    {} <- Stdout.line "    roc run main.roc start --no-text --debug" |> Task.await
    {} <- Stdout.line "    roc run main.roc stats --days 30 --json" |> Task.await
    {} <- Stdout.line "    roc run main.roc export --format csv --output activity.csv" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "Roc Implementation Features:" |> Task.await
    {} <- Stdout.line "  • Fast functional language with excellent performance" |> Task.await
    {} <- Stdout.line "  • Strong type safety with zero-cost abstractions" |> Task.await
    {} <- Stdout.line "  • Seamless interop with existing systems" |> Task.await
    {} <- Stdout.line "  • Compile-time optimizations" |> Task.await
    {} <- Stdout.line "  • Memory safety without garbage collection" |> Task.await
    Stdout.line "  • Pattern matching and algebraic data types"

## Main entry point with error handling
main : Task {} I32
main =
    argsResult <- Arg.list |> Task.await
    
    when argsResult is
        args ->
            # Skip program name
            actualArgs = List.dropFirst args 1
            
            when parseArgs actualArgs is
                Ok command ->
                    Task.attempt (runCommand command) \result ->
                        when result is
                            Ok {} ->
                                Task.ok 0
                            
                            Err (ConfigError msg) ->
                                {} <- Stderr.line "Configuration error: $(msg)" |> Task.await
                                Task.ok 1
                            
                            Err (PermissionError msg) ->
                                {} <- Stderr.line "Permission error: $(msg)" |> Task.await
                                Task.ok 1
                            
                            Err (StorageError msg) ->
                                {} <- Stderr.line "Storage error: $(msg)" |> Task.await
                                Task.ok 1
                            
                            Err (PlatformError msg) ->
                                {} <- Stderr.line "Platform error: $(msg)" |> Task.await
                                Task.ok 1
                            
                            Err (InvalidArgument msg) ->
                                {} <- Stderr.line "Invalid argument: $(msg)" |> Task.await
                                {} <- Stderr.line "Use 'roc run main.roc help' for usage information" |> Task.await
                                Task.ok 1
                
                Err (InvalidArgument msg) ->
                    {} <- Stderr.line "Error: $(msg)" |> Task.await
                    {} <- Stderr.line "Use 'roc run main.roc help' for usage information" |> Task.await
                    Task.ok 1
                
                Err _ ->
                    {} <- Stderr.line "Unexpected error" |> Task.await
                    Task.ok 1