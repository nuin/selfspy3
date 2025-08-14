/// Activity monitoring for Selfspy F# implementation
namespace Selfspy.Monitor

open System
open System.Threading
open Selfspy.Types
open Selfspy.Storage

type Monitor = {
    Config: Config
    Storage: Storage
    mutable State: MonitorState
    mutable EventsProcessed: int64
    CancellationTokenSource: CancellationTokenSource
}

let createMonitor (config: Config) (storage: Storage) : Monitor =
    {
        Config = config
        Storage = storage
        State = Stopped
        EventsProcessed = 0L
        CancellationTokenSource = new CancellationTokenSource()
    }

let startMonitor (monitor: Monitor) : Async<unit> =
    async {
        monitor.State <- Starting
        
        // Start monitoring loop
        let monitoringLoop = async {
            monitor.State <- Running
            
            while not monitor.CancellationTokenSource.Token.IsCancellationRequested do
                try
                    // Simulate event collection
                    monitor.EventsProcessed <- monitor.EventsProcessed + 1L
                    
                    // Sleep for update interval
                    do! Async.Sleep(monitor.Config.UpdateIntervalMs)
                with
                | :? OperationCanceledException -> ()
                | ex -> 
                    eprintfn "Monitoring error: %s" ex.Message
            
            monitor.State <- Stopped
        }
        
        // Start monitoring in background
        Async.Start(monitoringLoop, monitor.CancellationTokenSource.Token)
    }

let stopMonitor (monitor: Monitor) : Async<unit> =
    async {
        monitor.State <- Stopping
        monitor.CancellationTokenSource.Cancel()
        // Wait a bit for graceful shutdown
        do! Async.Sleep(100)
        monitor.State <- Stopped
    }