/// Statistics and visualization for Selfspy F# implementation
namespace Selfspy.Stats

open System
open Newtonsoft.Json
open Selfspy.Types

let printFormattedStats (stats: ActivityStats) (days: int) : unit =
    printfn ""
    printfn "📊 Selfspy Activity Statistics (Last %d days)" days
    printfn "=================================================="
    printfn ""
    printfn "⌨️  Keystrokes: %s" (Utils.formatNumber stats.Keystrokes)
    printfn "🖱️  Mouse clicks: %s" (Utils.formatNumber stats.Clicks)
    printfn "🪟  Window changes: %s" (Utils.formatNumber stats.WindowChanges)
    printfn "⏰ Active time: %s" (Utils.formatDuration stats.ActiveTimeSeconds)
    
    if not (List.isEmpty stats.TopApps) then
        printfn "📱 Most used applications:"
        stats.TopApps
        |> List.iteri (fun i app ->
            printfn "   %d. %s (%.1f%%)" (i + 1) app.Name app.Percentage)
    
    printfn ""

let statsToJson (stats: ActivityStats) : string =
    JsonConvert.SerializeObject(stats, Formatting.Indented)