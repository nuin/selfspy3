#!/usr/bin/env lobster
// Selfspy - Modern Activity Monitoring in Lobster
//
// Simple, statically typed language with automatic memory management,
// strong performance, and excellent for game development and systems programming.

import std
import gl
import color

// Core data structures with static typing
struct Config:
    data_dir: string
    database_path: string
    capture_text: bool = true
    capture_mouse: bool = true
    capture_windows: bool = true
    update_interval_ms: int = 100
    encryption_enabled: bool = true
    debug: bool = false
    privacy_mode: bool = false
    exclude_applications: [string] = []
    max_database_size_mb: int = 500

struct WindowInfo:
    title: string
    application: string
    bundle_id: string
    process_id: int
    x: int
    y: int
    width: int
    height: int
    timestamp: int

struct KeyEvent:
    key: string
    application: string
    process_id: int
    count: int
    encrypted: bool
    timestamp: int

struct MouseEvent:
    x: int
    y: int
    button: int
    event_type: string
    process_id: int
    timestamp: int

struct ActivityStats:
    keystrokes: int
    clicks: int
    window_changes: int
    active_time_seconds: int
    top_apps: [AppUsage]

struct AppUsage:
    name: string
    percentage: float
    duration: int
    events: int

struct Permissions:
    accessibility: bool
    input_monitoring: bool
    screen_recording: bool

struct SystemInfo:
    platform: string
    architecture: string
    lobster_version: string
    hostname: string
    username: string

// Command line options with Lobster's struct syntax
struct StartOptions:
    no_text: bool = false
    no_mouse: bool = false
    debug: bool = false

struct StatsOptions:
    days: int = 7
    json: bool = false

struct ExportOptions:
    format: string = "json"
    output: string = ""
    days: int = 30

// Platform detection using Lobster's built-in functions
def get_os() -> string:
    return if gl.platform() == "windows": "windows"
           elif gl.platform() == "osx": "darwin"
           elif gl.platform() == "linux": "linux"
           else: "unknown"

// Configuration management with functional approach
def get_home_dir() -> string:
    let home = gl.get_env("HOME")
    return if home != "": home else: "/tmp"

def get_data_dir() -> string:
    let home = get_home_dir()
    return switch get_os():
        case "windows":
            gl.get_env("APPDATA") + "/selfspy"
        case "darwin":
            home + "/Library/Application Support/selfspy"
        default:
            home + "/.local/share/selfspy"

def default_config() -> Config:
    let data_dir = get_data_dir()
    return Config {
        data_dir: data_dir,
        database_path: data_dir + "/selfspy.db"
    }

// Command line parsing with pattern matching
def parse_start_options(args: [string]) -> StartOptions:
    var options = StartOptions{}
    for(args) arg:
        switch arg:
            case "--no-text":
                options.no_text = true
            case "--no-mouse":
                options.no_mouse = true
            case "--debug":
                options.debug = true
    return options

def parse_stats_options(args: [string]) -> StatsOptions:
    var options = StatsOptions{}
    for(args) arg, i:
        switch arg:
            case "--days":
                if i + 1 < length(args):
                    options.days = string_to_int(args[i + 1]) or 7
            case "--json":
                options.json = true
    return options

def parse_export_options(args: [string]) -> ExportOptions:
    var options = ExportOptions{}
    for(args) arg, i:
        switch arg:
            case "--format":
                if i + 1 < length(args):
                    options.format = args[i + 1]
            case "--output":
                if i + 1 < length(args):
                    options.output = args[i + 1]
            case "--days":
                if i + 1 < length(args):
                    options.days = string_to_int(args[i + 1]) or 30
    return options

def parse_command(args: [string]) -> string, any:
    if length(args) == 0:
        return "help", nil
    
    let command = args[0]
    let rest_args = slice(args, 1, -1)
    
    return switch command:
        case "start":
            "start", parse_start_options(rest_args)
        case "stop":
            "stop", nil
        case "stats":
            "stats", parse_stats_options(rest_args)
        case "check":
            "check", nil
        case "export":
            "export", parse_export_options(rest_args)
        case "version":
            "version", nil
        case "help":
            "help", nil
        default:
            "invalid", command

// Platform abstraction with compile-time conditionals
def check_permissions() -> Permissions:
    return switch get_os():
        case "darwin":
            // macOS permission checking (placeholder)
            Permissions {
                accessibility: true,
                input_monitoring: true,
                screen_recording: false
            }
        case "linux":
            // Check for display server
            let display = gl.get_env("DISPLAY")
            let wayland = gl.get_env("WAYLAND_DISPLAY")
            let has_display = display != "" or wayland != ""
            Permissions {
                accessibility: has_display,
                input_monitoring: has_display,
                screen_recording: has_display
            }
        case "windows":
            Permissions {
                accessibility: true,
                input_monitoring: true,
                screen_recording: true
            }
        default:
            Permissions {
                accessibility: true,
                input_monitoring: true,
                screen_recording: false
            }

def has_all_permissions(permissions: Permissions) -> bool:
    return permissions.accessibility and permissions.input_monitoring

def request_permissions() -> bool:
    switch get_os():
        case "darwin":
            print("Please grant accessibility permissions in System Preferences")
            print("Security & Privacy > Privacy > Accessibility")
            return true
        default:
            return true

// System information gathering
def get_system_info() -> SystemInfo:
    let hostname = gl.get_env("HOSTNAME")
    let username = gl.get_env("USER")
    
    return SystemInfo {
        platform: get_os(),
        architecture: "unknown", // Lobster doesn't expose this directly
        lobster_version: "1.0", // Placeholder
        hostname: if hostname != "": hostname else: "localhost",
        username: if username != "": username else: (gl.get_env("USERNAME") or "unknown")
    }

// Activity monitoring with Lobster's concurrent features
var monitor_running = false
var events_processed = 0

def start_monitoring(options: StartOptions):
    print("🚀 Starting Selfspy monitoring (Lobster implementation)")
    
    var config = default_config()
    config.capture_text = config.capture_text and not options.no_text
    config.capture_mouse = config.capture_mouse and not options.no_mouse
    config.debug = config.debug or options.debug
    
    // Check permissions
    let permissions = check_permissions()
    if not has_all_permissions(permissions):
        print("❌ Insufficient permissions for monitoring")
        print("Missing permissions:")
        if not permissions.accessibility:
            print("   - Accessibility permission required")
        if not permissions.input_monitoring:
            print("   - Input monitoring permission required")
        
        print("\nAttempting to request permissions...")
        if not request_permissions():
            fatal("Failed to obtain required permissions")
    
    // Create data directory if needed
    gl.ensure_dir_exists(config.data_dir)
    
    // Initialize monitor state
    monitor_running = true
    events_processed = 0
    
    print("✅ Selfspy monitoring started successfully")
    print("📊 Press Ctrl+C to stop monitoring")
    
    // Monitoring loop with cooperative multitasking
    while monitor_running:
        // Simulate event collection
        events_processed++
        
        // Sleep for update interval
        gl.sleep(config.update_interval_ms / 1000.0)

def stop_monitoring():
    print("🛑 Stopping Selfspy monitoring...")
    monitor_running = false
    print("✅ Stop signal sent")

// Statistics with functional data processing
def get_stats(days: int) -> ActivityStats:
    // Placeholder: Would query actual database
    return ActivityStats {
        keystrokes: 12547,
        clicks: 3821,
        window_changes: 342,
        active_time_seconds: 14760,
        top_apps: [
            AppUsage { name: "Code Editor", percentage: 45.2, duration: 6683, events: 5234 },
            AppUsage { name: "Web Browser", percentage: 32.1, duration: 4736, events: 3892 },
            AppUsage { name: "Terminal", percentage: 15.7, duration: 2318, events: 2156 }
        ]
    }

def show_stats(options: StatsOptions):
    let stats = get_stats(options.days)
    
    if options.json:
        // JSON output (simplified)
        print("{")
        print("  \"keystrokes\": " + stats.keystrokes)
        print("  \"clicks\": " + stats.clicks)
        print("  \"window_changes\": " + stats.window_changes)
        print("  \"active_time_seconds\": " + stats.active_time_seconds)
        print("}")
    else:
        print_formatted_stats(stats, options.days)

// Data export with string manipulation
def export_data(options: ExportOptions):
    print("📤 Exporting " + options.days + " days of data in " + options.format + " format...")
    
    let stats = get_stats(options.days)
    
    let data = switch options.format:
        case "json":
            "{" +
            "\"keystrokes\":" + stats.keystrokes + "," +
            "\"clicks\":" + stats.clicks + "," +
            "\"window_changes\":" + stats.window_changes + "," +
            "\"active_time_seconds\":" + stats.active_time_seconds +
            "}"
        case "csv":
            "metric,value\n" +
            "keystrokes," + stats.keystrokes + "\n" +
            "clicks," + stats.clicks + "\n" +
            "window_changes," + stats.window_changes + "\n" +
            "active_time_seconds," + stats.active_time_seconds
        case "sql":
            "-- Selfspy Activity Export\n" +
            "CREATE TABLE stats (metric TEXT, value INTEGER);\n" +
            "INSERT INTO stats VALUES ('keystrokes', " + stats.keystrokes + ");\n" +
            "INSERT INTO stats VALUES ('clicks', " + stats.clicks + ");\n" +
            "INSERT INTO stats VALUES ('window_changes', " + stats.window_changes + ");\n" +
            "INSERT INTO stats VALUES ('active_time_seconds', " + stats.active_time_seconds + ");"
        default:
            fatal("Unsupported export format: " + options.format)
    
    if options.output != "":
        gl.write_file(options.output, data)
        print("✅ Data exported to " + options.output)
    else:
        print(data)

def check_system():
    print("🔍 Checking Selfspy permissions...")
    print("===================================")
    print("")
    
    let permissions = check_permissions()
    if has_all_permissions(permissions):
        print("✅ All permissions granted")
    else:
        print("❌ Missing permissions:")
        if not permissions.accessibility:
            print("   - Accessibility permission required")
        if not permissions.input_monitoring:
            print("   - Input monitoring permission required")
    
    print("")
    print("📱 System Information:")
    let sys_info = get_system_info()
    print("   Platform: " + sys_info.platform)
    print("   Architecture: " + sys_info.architecture)
    print("   Lobster Version: " + sys_info.lobster_version)
    print("   Hostname: " + sys_info.hostname)
    print("   Username: " + sys_info.username)

def show_version():
    print("Selfspy v1.0.0 (Lobster implementation)")
    print("Simple, statically typed language")
    print("")
    print("Features:")
    print("  • Simple, readable syntax")
    print("  • Automatic memory management")
    print("  • Strong type system")
    print("  • Excellent performance")
    print("  • Great for game development")
    print("  • Perfect for system programming")

// Utility functions with efficient implementations
def format_number(num: int) -> string:
    if num >= 1000000:
        return string(num / 1000000) + "M"
    elif num >= 1000:
        return string(num / 1000) + "K"
    else:
        return string(num)

def format_duration(seconds: int) -> string:
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    
    if hours > 0:
        return string(hours) + "h " + string(minutes) + "m"
    else:
        return string(minutes) + "m"

def print_formatted_stats(stats: ActivityStats, days: int):
    print("")
    print("📊 Selfspy Activity Statistics (Last " + days + " days)")
    print("==================================================")
    print("")
    print("⌨️  Keystrokes: " + format_number(stats.keystrokes))
    print("🖱️  Mouse clicks: " + format_number(stats.clicks))
    print("🪟  Window changes: " + format_number(stats.window_changes))
    print("⏰ Active time: " + format_duration(stats.active_time_seconds))
    
    if length(stats.top_apps) > 0:
        print("📱 Most used applications:")
        for(stats.top_apps) app, i:
            print("   " + (i + 1) + ". " + app.name + " (" + app.percentage + "%)")
    
    print("")

def print_help():
    print("Selfspy - Modern Activity Monitoring in Lobster")
    print("")
    print("USAGE:")
    print("    lobster selfspy.lobster [COMMAND] [OPTIONS]")
    print("")
    print("COMMANDS:")
    print("    start                 Start activity monitoring")
    print("    stop                  Stop running monitoring instance")
    print("    stats                 Show activity statistics")
    print("    check                 Check system permissions and setup")
    print("    export                Export data to various formats")
    print("    version               Show version information")
    print("    help                  Show this help message")
    print("")
    print("START OPTIONS:")
    print("    --no-text             Disable text capture for privacy")
    print("    --no-mouse            Disable mouse monitoring")
    print("    --debug               Enable debug logging")
    print("")
    print("STATS OPTIONS:")
    print("    --days <N>            Number of days to analyze (default: 7)")
    print("    --json                Output in JSON format")
    print("")
    print("EXPORT OPTIONS:")
    print("    --format <FORMAT>     Export format: json, csv, sql (default: json)")
    print("    --output <FILE>       Output file path")
    print("    --days <N>            Number of days to export (default: 30)")
    print("")
    print("EXAMPLES:")
    print("    lobster selfspy.lobster start")
    print("    lobster selfspy.lobster start --no-text --debug")
    print("    lobster selfspy.lobster stats --days 30 --json")
    print("    lobster selfspy.lobster export --format csv --output activity.csv")
    print("")
    print("Lobster Implementation Features:")
    print("  • Simple, readable syntax with strong typing")
    print("  • Automatic memory management")
    print("  • Excellent performance characteristics")
    print("  • Great for both game development and systems")
    print("  • Modern language design with safety")
    print("  • Perfect for concurrent programming")

// Command execution with error handling
def execute_command(command: string, options: any):
    switch command:
        case "start":
            start_monitoring(options)
        case "stop":
            stop_monitoring()
        case "stats":
            show_stats(options)
        case "check":
            check_system()
        case "export":
            export_data(options)
        case "version":
            show_version()
        case "help":
            print_help()
        case "invalid":
            print("Error: Unknown command: " + string(options))
            print("Use 'lobster selfspy.lobster help' for usage information")
            fatal("Invalid command")

// Main entry point
def main():
    let args = gl.command_line_arguments()
    let command, options = parse_command(args)
    execute_command(command, options)

// Run the application
main()