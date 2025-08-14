/// Platform abstraction for Selfspy F# implementation
namespace Selfspy.Platform

open System
open System.Runtime.InteropServices
open Selfspy.Types

let checkPermissions () : Async<Permissions> =
    async {
        match Platform.getCurrentPlatform() with
        | "darwin" ->
            // macOS permission checking (placeholder)
            return { Accessibility = true; InputMonitoring = true; ScreenRecording = false }
        | "linux" ->
            // Linux display server checking
            let hasDisplay = Environment.GetEnvironmentVariable("DISPLAY") <> null ||
                            Environment.GetEnvironmentVariable("WAYLAND_DISPLAY") <> null
            return { Accessibility = hasDisplay; InputMonitoring = hasDisplay; ScreenRecording = hasDisplay }
        | "windows" ->
            return { Accessibility = true; InputMonitoring = true; ScreenRecording = true }
        | _ ->
            return { Accessibility = true; InputMonitoring = true; ScreenRecording = false }
    }

let hasAllPermissions (permissions: Permissions) : bool =
    permissions.Accessibility && permissions.InputMonitoring

let requestPermissions () : Async<bool> =
    async {
        match Platform.getCurrentPlatform() with
        | "darwin" ->
            printfn "Please grant permissions in System Preferences > Security & Privacy > Privacy"
            return true
        | _ ->
            return true
    }

let getSystemInfo () : SystemInfo =
    {
        Platform = Platform.getCurrentPlatform()
        Architecture = RuntimeInformation.OSArchitecture.ToString()
        DotNetVersion = RuntimeInformation.FrameworkDescription
        FSharpVersion = typeof<Microsoft.FSharp.Core.FSharpOption<_>>.Assembly.GetName().Version.ToString()
        Hostname = Environment.MachineName
        Username = Environment.UserName
    }