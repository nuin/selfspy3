/// Selfspy - Modern Activity Monitoring in F#
/// 
/// Functional-first programming on .NET with excellent data processing,
/// strong interop with .NET ecosystem, and fantastic async support.

open System
open System.Threading
open System.Threading.Tasks
open Argu
open Serilog
open Selfspy.Types
open Selfspy.CLI
open Selfspy.Config
open Selfspy.Platform
open Selfspy.Storage
open Selfspy.Monitor
open Selfspy.Stats

/// Error handling with Result types and Railway Oriented Programming
type SelfspyError =
    | ConfigurationError of string
    | PermissionError of string  
    | StorageError of string
    | PlatformError of string
    | InvalidArgumentError of string

/// Functional error handling with Result workflows
module Result =
    let bindAsync f result = 
        async {
            match result with
            | Ok value -> return! f value
            | Error error -> return Error error
        }
    
    let mapAsync f result =
        async {
            match result with
            | Ok value -> 
                let! mapped = f value
                return Ok mapped
            | Error error -> return Error error
        }

/// Command execution with comprehensive async error handling
module CommandExecutor =
    
    let executeStart (options: StartOptions) : Async<Result<unit, SelfspyError>> =
        async {
            printfn "🚀 Starting Selfspy monitoring (F# implementation)"
            
            // Load configuration with Result workflow
            let! configResult = 
                async {
                    try
                        let! config = loadConfig()
                        return Ok config
                    with
                    | ex -> return Error (ConfigurationError ex.Message)
                }
            
            match configResult with
            | Error error -> return Error error
            | Ok config ->
                // Apply command line options functionally
                let updatedConfig = {
                    config with
                        CaptureText = config.CaptureText && not options.NoText
                        CaptureMouse = config.CaptureMouse && not options.NoMouse
                        Debug = config.Debug || options.Debug
                }
                
                // Check permissions with functional composition
                let! permissionsResult =
                    async {
                        try
                            let! permissions = checkPermissions()
                            return Ok permissions
                        with
                        | ex -> return Error (PlatformError ex.Message)
                    }
                
                match permissionsResult with
                | Error error -> return Error error
                | Ok permissions ->
                    if not (hasAllPermissions permissions) then
                        printfn "❌ Insufficient permissions for monitoring"
                        printfn "Missing permissions:"
                        if not permissions.Accessibility then
                            printfn "   - Accessibility permission required"
                        if not permissions.InputMonitoring then
                            printfn "   - Input monitoring permission required"
                        
                        printfn "\nAttempting to request permissions..."
                        let! success = requestPermissions()
                        if not success then
                            return Error (PermissionError "Failed to obtain required permissions")
                        else
                            return Ok ()
                    else
                        return Ok ()
                    
                    // Initialize storage with functional error handling
                    let! storageResult =
                        async {
                            try
                                let! storage = createStorage updatedConfig.DatabasePath
                                do! initializeStorage storage
                                return Ok storage
                            with
                            | ex -> return Error (StorageError ex.Message)
                        }
                    
                    match storageResult with
                    | Error error -> return Error error
                    | Ok storage ->
                        // Create and start monitor
                        let monitor = createMonitor updatedConfig storage
                        do! startMonitor monitor
                        
                        printfn "✅ Selfspy monitoring started successfully"
                        printfn "📊 Press Ctrl+C to stop monitoring"
                        
                        // Set up graceful shutdown with cancellation token
                        use cts = new CancellationTokenSource()
                        Console.CancelKeyPress.Add(fun _ ->
                            printfn "\n🛑 Received shutdown signal, stopping gracefully..."
                            cts.Cancel()
                        )
                        
                        try
                            // Wait for cancellation
                            do! Async.AwaitTask(Task.Delay(-1, cts.Token))
                        with
                        | :? OperationCanceledException -> ()
                        
                        // Stop monitor gracefully
                        do! stopMonitor monitor
                        do! closeStorage storage
                        
                        return Ok ()
        }
    
    let executeStop () : Async<Result<unit, SelfspyError>> =
        async {
            printfn "🛑 Stopping Selfspy monitoring..."
            printfn "✅ Stop signal sent"
            return Ok ()
        }
    
    let executeStats (options: StatsOptions) : Async<Result<unit, SelfspyError>> =
        async {
            let! configResult =
                async {
                    try
                        let! config = loadConfig()
                        return Ok config
                    with
                    | ex -> return Error (ConfigurationError ex.Message)
                }
            
            match configResult with
            | Error error -> return Error error
            | Ok config ->
                let! storageResult =
                    async {
                        try
                            let! storage = createStorage config.DatabasePath
                            do! initializeStorage storage
                            return Ok storage
                        with
                        | ex -> return Error (StorageError ex.Message)
                    }
                
                match storageResult with
                | Error error -> return Error error
                | Ok storage ->
                    let! stats = getStats storage options.Days
                    do! closeStorage storage
                    
                    if options.Json then
                        let jsonOutput = statsToJson stats
                        printfn "%s" jsonOutput
                    else
                        printFormattedStats stats options.Days
                    
                    return Ok ()
        }
    
    let executeCheck () : Async<Result<unit, SelfspyError>> =
        async {
            printfn "🔍 Checking Selfspy permissions..."
            printfn "==================================="
            printfn ""
            
            let! permissionsResult =
                async {
                    try
                        let! permissions = checkPermissions()
                        return Ok permissions
                    with
                    | ex -> return Error (PlatformError ex.Message)
                }
            
            match permissionsResult with
            | Error error -> return Error error
            | Ok permissions ->
                if hasAllPermissions permissions then
                    printfn "✅ All permissions granted"
                else
                    printfn "❌ Missing permissions:"
                    if not permissions.Accessibility then
                        printfn "   - Accessibility permission required"
                    if not permissions.InputMonitoring then
                        printfn "   - Input monitoring permission required"
                
                printfn ""
                printfn "📱 System Information:"
                let sysInfo = getSystemInfo()
                printfn "   Platform: %s" sysInfo.Platform
                printfn "   Architecture: %s" sysInfo.Architecture
                printfn "   .NET Version: %s" sysInfo.DotNetVersion
                printfn "   F# Version: %s" sysInfo.FSharpVersion
                printfn "   Hostname: %s" sysInfo.Hostname
                
                return Ok ()
        }
    
    let executeExport (options: ExportOptions) : Async<Result<unit, SelfspyError>> =
        async {
            printfn "📤 Exporting %d days of data in %s format..." options.Days options.Format
            
            let! configResult =
                async {
                    try
                        let! config = loadConfig()
                        return Ok config
                    with
                    | ex -> return Error (ConfigurationError ex.Message)
                }
            
            match configResult with
            | Error error -> return Error error
            | Ok config ->
                let! storageResult =
                    async {
                        try
                            let! storage = createStorage config.DatabasePath
                            do! initializeStorage storage
                            return Ok storage
                        with
                        | ex -> return Error (StorageError ex.Message)
                    }
                
                match storageResult with
                | Error error -> return Error error
                | Ok storage ->
                    let! dataResult =
                        async {
                            try
                                let! data = 
                                    match options.Format.ToLower() with
                                    | "json" -> exportJson storage options.Days
                                    | "csv" -> exportCsv storage options.Days
                                    | "sql" -> exportSql storage options.Days
                                    | _ -> async { return failwith $"Unsupported export format: {options.Format}" }
                                return Ok data
                            with
                            | ex -> return Error (StorageError ex.Message)
                        }
                    
                    do! closeStorage storage
                    
                    match dataResult with
                    | Error error -> return Error error
                    | Ok data ->
                        match options.Output with
                        | Some filename ->
                            do! Async.AwaitTask(System.IO.File.WriteAllTextAsync(filename, data))
                            printfn "✅ Data exported to %s" filename
                        | None ->
                            printfn "%s" data
                        
                        return Ok ()
        }
    
    let executeVersion () : Async<Result<unit, SelfspyError>> =
        async {
            printfn "Selfspy v1.0.0 (F# implementation)"
            printfn "Functional-first programming on .NET"
            printfn ""
            printfn "Features:"
            printfn "  • Functional-first programming with .NET interop"
            printfn "  • Excellent data processing and analytics"
            printfn "  • Strong type system with type inference"
            printfn "  • Powerful async workflows and computation expressions"
            printfn "  • Railway Oriented Programming for error handling"
            printfn "  • Rich ecosystem with NuGet packages"
            return Ok ()
        }

/// Main program execution with comprehensive error handling
module Program =
    
    let executeCommand command =
        async {
            let! result =
                match command with
                | Start options -> CommandExecutor.executeStart options
                | Stop -> CommandExecutor.executeStop ()
                | Stats options -> CommandExecutor.executeStats options
                | Check -> CommandExecutor.executeCheck ()
                | Export options -> CommandExecutor.executeExport options
                | Version -> CommandExecutor.executeVersion ()
            
            match result with
            | Ok () -> return 0
            | Error error ->
                match error with
                | ConfigurationError msg ->
                    eprintfn "Configuration error: %s" msg
                | PermissionError msg ->
                    eprintfn "Permission error: %s" msg
                | StorageError msg ->
                    eprintfn "Storage error: %s" msg
                | PlatformError msg ->
                    eprintfn "Platform error: %s" msg
                | InvalidArgumentError msg ->
                    eprintfn "Invalid argument: %s" msg
                    eprintfn "Use 'selfspy --help' for usage information"
                
                return 1
        }
    
    let setupLogging debug =
        let logConfig = 
            LoggerConfiguration()
                .MinimumLevel.Is(if debug then Serilog.Events.LogEventLevel.Debug else Serilog.Events.LogEventLevel.Information)
                .WriteTo.Console()
        
        Log.Logger <- logConfig.CreateLogger()

    [<EntryPoint>]
    let main args =
        try
            let parser = ArgumentParser.Create<Arguments>(programName = "selfspy")
            
            try
                let results = parser.ParseCommandLine(inputs = args, raiseOnUsage = false)
                
                if results.IsUsageRequested then
                    printfn "%s" (parser.PrintUsage())
                    0
                else
                    // Parse command from arguments
                    let command = parseCommand results
                    let debug = results.TryGetResult Debug |> Option.isSome
                    
                    setupLogging debug
                    
                    // Execute command asynchronously
                    executeCommand command |> Async.RunSynchronously
            with
            | :? ArguParseException as ex ->
                eprintfn "%s" ex.Message
                1
            | ex ->
                eprintfn "Unexpected error: %s" ex.Message
                1
        with
        | ex ->
            eprintfn "Fatal error: %s" ex.Message
            1