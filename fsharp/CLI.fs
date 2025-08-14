/// Command-line interface for Selfspy F# implementation
/// Using Argu for type-safe command line parsing

namespace Selfspy.CLI

open Argu
open Selfspy.Types

/// Command line arguments with Argu attributes
type Arguments =
    | [<CliPrefix(CliPrefix.None)>] Start of ParseResults<StartArgs>
    | [<CliPrefix(CliPrefix.None)>] Stop
    | [<CliPrefix(CliPrefix.None)>] Stats of ParseResults<StatsArgs>
    | [<CliPrefix(CliPrefix.None)>] Check
    | [<CliPrefix(CliPrefix.None)>] Export of ParseResults<ExportArgs>
    | [<CliPrefix(CliPrefix.None)>] Version
    | [<AltCommandLine("-d")>] Debug

    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | Start _ -> "Start activity monitoring"
            | Stop -> "Stop running monitoring instance"  
            | Stats _ -> "Show activity statistics"
            | Check -> "Check system permissions and setup"
            | Export _ -> "Export data to various formats"
            | Version -> "Show version information"
            | Debug -> "Enable debug logging"

and StartArgs =
    | [<AltCommandLine("--no-text")>] No_Text
    | [<AltCommandLine("--no-mouse")>] No_Mouse
    | [<AltCommandLine("--debug")>] Debug

    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | No_Text -> "Disable text capture for privacy"
            | No_Mouse -> "Disable mouse monitoring"
            | Debug -> "Enable debug logging"

and StatsArgs =
    | [<AltCommandLine("-d")>] Days of int
    | [<AltCommandLine("-j")>] Json

    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | Days _ -> "Number of days to analyze (default: 7)"
            | Json -> "Output in JSON format"

and ExportArgs =
    | [<AltCommandLine("-f")>] Format of string
    | [<AltCommandLine("-o")>] Output of string
    | [<AltCommandLine("-d")>] Days of int

    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | Format _ -> "Export format: json, csv, sql (default: json)"
            | Output _ -> "Output file path"
            | Days _ -> "Number of days to export (default: 30)"

/// Command parsing with functional composition
module CommandParser =
    
    let parseStartOptions (results: ParseResults<StartArgs>) : StartOptions =
        {
            NoText = results.Contains No_Text
            NoMouse = results.Contains No_Mouse
            Debug = results.Contains StartArgs.Debug
        }
    
    let parseStatsOptions (results: ParseResults<StatsArgs>) : StatsOptions =
        {
            Days = results.GetResult(Days, defaultValue = 7)
            Json = results.Contains Json
        }
    
    let parseExportOptions (results: ParseResults<ExportArgs>) : ExportOptions =
        {
            Format = results.GetResult(Format, defaultValue = "json")
            Output = results.TryGetResult Output
            Days = results.GetResult(ExportArgs.Days, defaultValue = 30)
        }
    
    let parseCommand (results: ParseResults<Arguments>) : Command =
        match results.GetAllResults() with
        | [Start startResults] -> 
            Start (parseStartOptions startResults)
        | [Stop] -> 
            Stop
        | [Stats statsResults] -> 
            Stats (parseStatsOptions statsResults)
        | [Check] -> 
            Check
        | [Export exportResults] -> 
            Export (parseExportOptions exportResults)
        | [Version] -> 
            Version
        | [] -> 
            // Default to help if no command specified
            failwith "No command specified. Use --help for usage information."
        | _ -> 
            failwith "Multiple commands specified. Please specify only one command."

/// Help and usage information
module Help =
    
    let printUsage () =
        printfn "Selfspy - Modern Activity Monitoring in F#"
        printfn ""
        printfn "USAGE:"
        printfn "    selfspy [COMMAND] [OPTIONS]"
        printfn ""
        printfn "COMMANDS:"
        printfn "    start                 Start activity monitoring"
        printfn "    stop                  Stop running monitoring instance"
        printfn "    stats                 Show activity statistics"
        printfn "    check                 Check system permissions and setup"
        printfn "    export                Export data to various formats"
        printfn "    version               Show version information"
        printfn ""
        printfn "GLOBAL OPTIONS:"
        printfn "    --debug, -d           Enable debug logging"
        printfn ""
        printfn "START OPTIONS:"
        printfn "    --no-text             Disable text capture for privacy"
        printfn "    --no-mouse            Disable mouse monitoring"
        printfn "    --debug               Enable debug logging"
        printfn ""
        printfn "STATS OPTIONS:"
        printfn "    --days <N>, -d <N>    Number of days to analyze (default: 7)"
        printfn "    --json, -j            Output in JSON format"
        printfn ""
        printfn "EXPORT OPTIONS:"
        printfn "    --format <FORMAT>, -f Export format: json, csv, sql (default: json)"
        printfn "    --output <FILE>, -o   Output file path"
        printfn "    --days <N>, -d <N>    Number of days to export (default: 30)"
        printfn ""
        printfn "EXAMPLES:"
        printfn "    selfspy start"
        printfn "    selfspy start --no-text --debug"
        printfn "    selfspy stats --days 30 --json"
        printfn "    selfspy export --format csv --output activity.csv"
        printfn ""
        printfn "F# Implementation Features:"
        printfn "  • Functional-first programming with .NET interop"
        printfn "  • Excellent data processing and analytics capabilities"
        printfn "  • Strong type system with type inference"
        printfn "  • Powerful async workflows and computation expressions"
        printfn "  • Railway Oriented Programming for error handling"
        printfn "  • Rich ecosystem with NuGet packages"
    
    let printVersion () =
        printfn "Selfspy v1.0.0 (F# implementation)"
        printfn "Functional-first programming on .NET"
        printfn ""
        printfn "Runtime Information:"
        printfn "  • .NET Version: %s" (System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription)
        printfn "  • F# Compiler Version: %s" (typeof<Microsoft.FSharp.Core.FSharpOption<_>>.Assembly.GetName().Version.ToString())
        printfn "  • Platform: %s" (System.Runtime.InteropServices.RuntimeInformation.OSDescription)
        printfn "  • Architecture: %s" (System.Runtime.InteropServices.RuntimeInformation.OSArchitecture.ToString())
    
    let printExamples () =
        printfn "F# Selfspy Usage Examples:"
        printfn "=========================="
        printfn ""
        printfn "Basic monitoring:"
        printfn "  selfspy start"
        printfn ""
        printfn "Privacy-focused monitoring:"
        printfn "  selfspy start --no-text --no-mouse"
        printfn ""
        printfn "Debug mode:"
        printfn "  selfspy start --debug"
        printfn ""
        printfn "View statistics:"
        printfn "  selfspy stats"
        printfn "  selfspy stats --days 14"
        printfn "  selfspy stats --json"
        printfn ""
        printfn "Export data:"
        printfn "  selfspy export"
        printfn "  selfspy export --format csv"
        printfn "  selfspy export --format sql --output backup.sql"
        printfn "  selfspy export --days 90 --format json --output analysis.json"
        printfn ""
        printfn "System diagnostics:"
        printfn "  selfspy check"
        printfn "  selfspy version"