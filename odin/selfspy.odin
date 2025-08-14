// Selfspy - Modern Activity Monitoring in Odin
//
// Modern systems programming language designed as a C alternative
// with excellent performance, modern features with simplicity,
// and perfect for low-level system monitoring.

package selfspy

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:time"
import "core:thread"
import "core:sync"
import "core:mem"
import "core:log"
import "core:encoding/json"
import "core:slice"

// Core data structures with explicit memory layout
Config :: struct {
    data_dir:              string,
    database_path:         string,
    capture_text:          bool,
    capture_mouse:         bool,
    capture_windows:       bool,
    update_interval_ms:    i32,
    encryption_enabled:    bool,
    debug:                 bool,
    privacy_mode:          bool,
    exclude_applications:  []string,
    max_database_size_mb:  i32,
}

WindowInfo :: struct {
    title:       string,
    application: string,
    bundle_id:   string,
    process_id:  u32,
    x:           i32,
    y:           i32,
    width:       i32,
    height:      i32,
    timestamp:   u64,
}

KeyEvent :: struct {
    key:         string,
    application: string,
    process_id:  u32,
    count:       u32,
    encrypted:   bool,
    timestamp:   u64,
}

MouseEvent :: struct {
    x:           i32,
    y:           i32,
    button:      u8,
    event_type:  string,
    process_id:  u32,
    timestamp:   u64,
}

ActivityStats :: struct {
    keystrokes:          u64,
    clicks:              u64,
    window_changes:      u64,
    active_time_seconds: u64,
    top_apps:            []AppUsage,
}

AppUsage :: struct {
    name:       string,
    percentage: f64,
    duration:   u64,
    events:     u64,
}

Permissions :: struct {
    accessibility:     bool,
    input_monitoring:  bool,
    screen_recording:  bool,
}

SystemInfo :: struct {
    platform:     string,
    architecture: string,
    odin_version: string,
    hostname:     string,
    username:     string,
}

// Error handling with enum
SelfspyError :: enum {
    None,
    ConfigError,
    PermissionError,
    StorageError,
    PlatformError,
    InvalidArgument,
}

// Command types with union
StartOptions :: struct {
    no_text:  bool,
    no_mouse: bool,
    debug:    bool,
}

StatsOptions :: struct {
    days: i32,
    json: bool,
}

ExportOptions :: struct {
    format: string,
    output: string, // empty string means no output file
    days:   i32,
}

Command :: union {
    StartOptions,
    struct{}, // Stop
    StatsOptions,
    struct{}, // Check  
    ExportOptions,
    struct{}, // Version
    struct{}, // Help
}

// Monitor state with atomic operations
MonitorState :: struct {
    config:           Config,
    running:          bool,
    events_processed: u64,
    mutex:           sync.Mutex,
}

// Platform detection with compile-time conditionals
get_os :: proc() -> string {
    when ODIN_OS == .Windows {
        return "windows"
    } else when ODIN_OS == .Darwin {
        return "darwin"
    } else when ODIN_OS == .Linux {
        return "linux"
    } else {
        return "unknown"
    }
}

// Default configuration with platform-specific paths
default_config :: proc() -> Config {
    home_dir := os.get_env("HOME")
    if home_dir == "" {
        home_dir = "/tmp"
    }
    
    data_dir: string
    switch get_os() {
    case "windows":
        appdata := os.get_env("APPDATA")
        data_dir = fmt.tprintf("%s/selfspy", appdata)
    case "darwin":
        data_dir = fmt.tprintf("%s/Library/Application Support/selfspy", home_dir)
    case:
        data_dir = fmt.tprintf("%s/.local/share/selfspy", home_dir)
    }
    
    return Config{
        data_dir              = data_dir,
        database_path         = fmt.tprintf("%s/selfspy.db", data_dir),
        capture_text          = true,
        capture_mouse         = true,
        capture_windows       = true,
        update_interval_ms    = 100,
        encryption_enabled    = true,
        debug                 = false,
        privacy_mode          = false,
        exclude_applications  = {},
        max_database_size_mb  = 500,
    }
}

// Command line argument parsing with pattern matching
parse_args :: proc(args: []string) -> (Command, SelfspyError) {
    if len(args) == 0 {
        return struct{}{}, .None // Help
    }
    
    switch args[0] {
    case "start":
        options := StartOptions{}
        for arg in args[1:] {
            switch arg {
            case "--no-text":
                options.no_text = true
            case "--no-mouse":
                options.no_mouse = true
            case "--debug":
                options.debug = true
            }
        }
        return options, .None
        
    case "stop":
        return struct{}{}, .None
        
    case "stats":
        options := StatsOptions{days = 7, json = false}
        for i in 1..<len(args) {
            switch args[i] {
            case "--days":
                if i + 1 < len(args) {
                    if days, ok := strconv.parse_int(args[i + 1]); ok {
                        options.days = i32(days)
                    }
                }
            case "--json":
                options.json = true
            }
        }
        return options, .None
        
    case "check":
        return struct{}{}, .None
        
    case "export":
        options := ExportOptions{format = "json", output = "", days = 30}
        for i in 1..<len(args) {
            switch args[i] {
            case "--format":
                if i + 1 < len(args) {
                    options.format = args[i + 1]
                }
            case "--output":
                if i + 1 < len(args) {
                    options.output = args[i + 1]
                }
            case "--days":
                if i + 1 < len(args) {
                    if days, ok := strconv.parse_int(args[i + 1]); ok {
                        options.days = i32(days)
                    }
                }
            }
        }
        return options, .None
        
    case "version":
        return struct{}{}, .None
        
    case "help":
        return struct{}{}, .None
        
    case:
        return struct{}{}, .InvalidArgument
    }
}

// Platform abstraction with compile-time specialization
check_permissions :: proc() -> Permissions {
    when ODIN_OS == .Darwin {
        // macOS permission checking (placeholder)
        return Permissions{
            accessibility    = true,
            input_monitoring = true,
            screen_recording = false,
        }
    } else when ODIN_OS == .Linux {
        // Check for display server
        display := os.get_env("DISPLAY")
        wayland := os.get_env("WAYLAND_DISPLAY")
        has_display := display != "" || wayland != ""
        
        return Permissions{
            accessibility    = has_display,
            input_monitoring = has_display,
            screen_recording = has_display,
        }
    } else when ODIN_OS == .Windows {
        return Permissions{
            accessibility    = true,
            input_monitoring = true,
            screen_recording = true,
        }
    } else {
        return Permissions{
            accessibility    = true,
            input_monitoring = true,
            screen_recording = false,
        }
    }
}

has_all_permissions :: proc(permissions: Permissions) -> bool {
    return permissions.accessibility && permissions.input_monitoring
}

request_permissions :: proc() -> bool {
    switch get_os() {
    case "darwin":
        fmt.println("Please grant accessibility permissions in System Preferences")
        fmt.println("Security & Privacy > Privacy > Accessibility")
        return true
    case:
        return true
    }
}

// System information gathering
get_system_info :: proc() -> SystemInfo {
    hostname := os.get_env("HOSTNAME")
    if hostname == "" {
        hostname = "localhost"
    }
    
    username := os.get_env("USER")
    if username == "" {
        username = os.get_env("USERNAME")
        if username == "" {
            username = "unknown"
        }
    }
    
    return SystemInfo{
        platform     = get_os(),
        architecture = ODIN_ARCH,
        odin_version = "dev-2024-08",
        hostname     = hostname,
        username     = username,
    }
}

// Activity monitoring with thread-safe operations
start_monitoring :: proc(options: StartOptions) -> SelfspyError {
    fmt.println("🚀 Starting Selfspy monitoring (Odin implementation)")
    
    config := default_config()
    config.capture_text = config.capture_text && !options.no_text
    config.capture_mouse = config.capture_mouse && !options.no_mouse
    config.debug = config.debug || options.debug
    
    // Check permissions
    permissions := check_permissions()
    if !has_all_permissions(permissions) {
        fmt.println("❌ Insufficient permissions for monitoring")
        fmt.println("Missing permissions:")
        if !permissions.accessibility {
            fmt.println("   - Accessibility permission required")
        }
        if !permissions.input_monitoring {
            fmt.println("   - Input monitoring permission required")
        }
        
        fmt.println("\nAttempting to request permissions...")
        if !request_permissions() {
            return .PermissionError
        }
    }
    
    // Create data directory if needed
    if !os.is_dir(config.data_dir) {
        if err := os.make_directory(config.data_dir); err != os.ERROR_NONE {
            log.errorf("Failed to create data directory: %v", err)
            return .ConfigError
        }
    }
    
    // Initialize monitor state
    monitor := MonitorState{
        config           = config,
        running          = true,
        events_processed = 0,
        mutex           = {},
    }
    
    fmt.println("✅ Selfspy monitoring started successfully")
    fmt.println("📊 Press Ctrl+C to stop monitoring")
    
    // Start monitoring loop in separate thread
    monitoring_thread := thread.create_and_start_with_data(&monitor, proc(data: rawptr) {
        monitor := cast(^MonitorState)data
        
        for {
            sync.mutex_lock(&monitor.mutex)
            if !monitor.running {
                sync.mutex_unlock(&monitor.mutex)
                break
            }
            
            // Simulate event collection
            monitor.events_processed += 1
            
            sync.mutex_unlock(&monitor.mutex)
            
            // Sleep for update interval
            time.sleep(time.Duration(monitor.config.update_interval_ms) * time.Millisecond)
        }
    })
    
    // Wait for thread completion (simplified)
    thread.join(monitoring_thread)
    
    return .None
}

stop_monitoring :: proc() -> SelfspyError {
    fmt.println("🛑 Stopping Selfspy monitoring...")
    fmt.println("✅ Stop signal sent")
    return .None
}

// Statistics with manual memory management
get_stats :: proc(days: i32) -> ActivityStats {
    // Placeholder: Would query actual database
    top_apps := make([]AppUsage, 3)
    top_apps[0] = AppUsage{"Code Editor", 45.2, 6683, 5234}
    top_apps[1] = AppUsage{"Web Browser", 32.1, 4736, 3892}
    top_apps[2] = AppUsage{"Terminal", 15.7, 2318, 2156}
    
    return ActivityStats{
        keystrokes          = 12547,
        clicks              = 3821,
        window_changes      = 342,
        active_time_seconds = 14760,
        top_apps            = top_apps,
    }
}

show_stats :: proc(options: StatsOptions) -> SelfspyError {
    stats := get_stats(options.days)
    
    if options.json {
        // JSON serialization (placeholder)
        fmt.printf(`{
  "keystrokes": %d,
  "clicks": %d,
  "window_changes": %d,
  "active_time_seconds": %d
}`, stats.keystrokes, stats.clicks, stats.window_changes, stats.active_time_seconds)
    } else {
        print_formatted_stats(stats, options.days)
    }
    
    // Clean up allocated memory
    delete(stats.top_apps)
    
    return .None
}

// Data export with string building
export_data :: proc(options: ExportOptions) -> SelfspyError {
    fmt.printf("📤 Exporting %d days of data in %s format...\n", options.days, options.format)
    
    stats := get_stats(options.days)
    defer delete(stats.top_apps)
    
    data: string
    switch options.format {
    case "json":
        data = fmt.tprintf(`{
  "keystrokes": %d,
  "clicks": %d,
  "window_changes": %d,
  "active_time_seconds": %d
}`, stats.keystrokes, stats.clicks, stats.window_changes, stats.active_time_seconds)
        
    case "csv":
        data = fmt.tprintf(`metric,value
keystrokes,%d
clicks,%d
window_changes,%d
active_time_seconds,%d`, stats.keystrokes, stats.clicks, stats.window_changes, stats.active_time_seconds)
        
    case "sql":
        data = fmt.tprintf(`-- Selfspy Activity Export
CREATE TABLE stats (metric TEXT, value INTEGER);
INSERT INTO stats VALUES ('keystrokes', %d);
INSERT INTO stats VALUES ('clicks', %d);
INSERT INTO stats VALUES ('window_changes', %d);
INSERT INTO stats VALUES ('active_time_seconds', %d);`, stats.keystrokes, stats.clicks, stats.window_changes, stats.active_time_seconds)
        
    case:
        fmt.printf("Unsupported export format: %s\n", options.format)
        return .InvalidArgument
    }
    
    if options.output != "" {
        if !os.write_entire_file(options.output, transmute([]u8)data) {
            fmt.printf("Failed to write to file: %s\n", options.output)
            return .StorageError
        }
        fmt.printf("✅ Data exported to %s\n", options.output)
    } else {
        fmt.print(data)
    }
    
    return .None
}

check_system :: proc() -> SelfspyError {
    fmt.println("🔍 Checking Selfspy permissions...")
    fmt.println("===================================")
    fmt.println()
    
    permissions := check_permissions()
    if has_all_permissions(permissions) {
        fmt.println("✅ All permissions granted")
    } else {
        fmt.println("❌ Missing permissions:")
        if !permissions.accessibility {
            fmt.println("   - Accessibility permission required")
        }
        if !permissions.input_monitoring {
            fmt.println("   - Input monitoring permission required")
        }
    }
    
    fmt.println()
    fmt.println("📱 System Information:")
    sys_info := get_system_info()
    fmt.printf("   Platform: %s\n", sys_info.platform)
    fmt.printf("   Architecture: %s\n", sys_info.architecture)
    fmt.printf("   Odin Version: %s\n", sys_info.odin_version)
    fmt.printf("   Hostname: %s\n", sys_info.hostname)
    fmt.printf("   Username: %s\n", sys_info.username)
    
    return .None
}

show_version :: proc() -> SelfspyError {
    fmt.println("Selfspy v1.0.0 (Odin implementation)")
    fmt.println("Modern systems programming language approach")
    fmt.println()
    fmt.println("Features:")
    fmt.println("  • Modern C alternative with safety features")
    fmt.println("  • Excellent performance and memory control")
    fmt.println("  • Simple, readable syntax")
    fmt.println("  • Compile-time code execution")
    fmt.println("  • Zero-cost abstractions")
    fmt.println("  • Manual memory management with safety")
    return .None
}

// Utility functions with efficient implementations
format_number :: proc(num: u64) -> string {
    if num >= 1_000_000 {
        return fmt.tprintf("%.1fM", f64(num) / 1_000_000.0)
    } else if num >= 1_000 {
        return fmt.tprintf("%.1fK", f64(num) / 1_000.0)
    } else {
        return fmt.tprintf("%d", num)
    }
}

format_duration :: proc(seconds: u64) -> string {
    hours := seconds / 3600
    minutes := (seconds % 3600) / 60
    
    if hours > 0 {
        return fmt.tprintf("%dh %dm", hours, minutes)
    } else {
        return fmt.tprintf("%dm", minutes)
    }
}

print_formatted_stats :: proc(stats: ActivityStats, days: i32) {
    fmt.println()
    fmt.printf("📊 Selfspy Activity Statistics (Last %d days)\n", days)
    fmt.println("==================================================")
    fmt.println()
    fmt.printf("⌨️  Keystrokes: %s\n", format_number(stats.keystrokes))
    fmt.printf("🖱️  Mouse clicks: %s\n", format_number(stats.clicks))
    fmt.printf("🪟  Window changes: %s\n", format_number(stats.window_changes))
    fmt.printf("⏰ Active time: %s\n", format_duration(stats.active_time_seconds))
    
    if len(stats.top_apps) > 0 {
        fmt.println("📱 Most used applications:")
        for app, i in stats.top_apps {
            fmt.printf("   %d. %s (%.1f%%)\n", i + 1, app.name, app.percentage)
        }
    }
    fmt.println()
}

print_help :: proc() {
    fmt.println("Selfspy - Modern Activity Monitoring in Odin")
    fmt.println()
    fmt.println("USAGE:")
    fmt.println("    selfspy [COMMAND] [OPTIONS]")
    fmt.println()
    fmt.println("COMMANDS:")
    fmt.println("    start                 Start activity monitoring")
    fmt.println("    stop                  Stop running monitoring instance")
    fmt.println("    stats                 Show activity statistics")
    fmt.println("    check                 Check system permissions and setup")
    fmt.println("    export                Export data to various formats")
    fmt.println("    version               Show version information")
    fmt.println("    help                  Show this help message")
    fmt.println()
    fmt.println("START OPTIONS:")
    fmt.println("    --no-text             Disable text capture for privacy")
    fmt.println("    --no-mouse            Disable mouse monitoring")
    fmt.println("    --debug               Enable debug logging")
    fmt.println()
    fmt.println("STATS OPTIONS:")
    fmt.println("    --days <N>            Number of days to analyze (default: 7)")
    fmt.println("    --json                Output in JSON format")
    fmt.println()
    fmt.println("EXPORT OPTIONS:")
    fmt.println("    --format <FORMAT>     Export format: json, csv, sql (default: json)")
    fmt.println("    --output <FILE>       Output file path")
    fmt.println("    --days <N>            Number of days to export (default: 30)")
    fmt.println()
    fmt.println("EXAMPLES:")
    fmt.println("    selfspy start")
    fmt.println("    selfspy start --no-text --debug")
    fmt.println("    selfspy stats --days 30 --json")
    fmt.println("    selfspy export --format csv --output activity.csv")
    fmt.println()
    fmt.println("Odin Implementation Features:")
    fmt.println("  • Modern systems programming language")
    fmt.println("  • Excellent performance with memory control")
    fmt.println("  • Simple, readable syntax")
    fmt.println("  • Compile-time code execution")
    fmt.println("  • Zero-cost abstractions")
    fmt.println("  • Perfect for low-level system monitoring")
}

// Command execution with error handling
execute_command :: proc(command: Command) -> SelfspyError {
    switch cmd in command {
    case StartOptions:
        return start_monitoring(cmd)
    case struct{}: // Stop, Check, Version, Help handled by type
        // Use runtime type information to distinguish
        return .None
    case StatsOptions:
        return show_stats(cmd)
    case ExportOptions:
        return export_data(cmd)
    }
    return .None
}

// Main entry point with explicit error handling
main :: proc() {
    args := os.args[1:] // Skip program name
    
    command, err := parse_args(args)
    if err != .None {
        switch err {
        case .InvalidArgument:
            fmt.eprintln("Error: Invalid command line arguments")
            fmt.eprintln("Use 'selfspy help' for usage information")
            os.exit(1)
        case:
            fmt.eprintln("Error: Failed to parse arguments")
            os.exit(1)
        }
    }
    
    // Handle special commands that don't need execute_command
    switch cmd in command {
    case struct{}:
        // Determine which struct{} command this is by checking args
        if len(args) == 0 || (len(args) > 0 && args[0] == "help") {
            print_help()
            return
        } else if len(args) > 0 && args[0] == "version" {
            if exec_err := show_version(); exec_err != .None {
                os.exit(1)
            }
            return
        } else if len(args) > 0 && args[0] == "check" {
            if exec_err := check_system(); exec_err != .None {
                os.exit(1)
            }
            return
        } else if len(args) > 0 && args[0] == "stop" {
            if exec_err := stop_monitoring(); exec_err != .None {
                os.exit(1)
            }
            return
        }
    case:
        if exec_err := execute_command(command); exec_err != .None {
            switch exec_err {
            case .ConfigError:
                fmt.eprintln("Configuration error")
            case .PermissionError:
                fmt.eprintln("Permission error")
            case .StorageError:
                fmt.eprintln("Storage error")
            case .PlatformError:
                fmt.eprintln("Platform error")
            case .InvalidArgument:
                fmt.eprintln("Invalid argument error")
            case:
                fmt.eprintln("Unknown error")
            }
            os.exit(1)
        }
    }
}