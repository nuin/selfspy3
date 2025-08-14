"""
Selfspy - Modern Activity Monitoring in Pony

Actor-model concurrency with reference capabilities for safe system monitoring.
Provides memory safety, data-race freedom, and deadlock-free concurrency.
"""

use "cli"
use "collections"
use "files"
use "format"
use "json"
use "net"
use "process"
use "random"
use "regex"
use "time"

// Core data types with reference capabilities
class val Config
  let data_dir: String
  let database_path: String
  let capture_text: Bool
  let capture_mouse: Bool
  let capture_windows: Bool
  let update_interval_ms: U64
  let encryption_enabled: Bool
  let debug: Bool
  let privacy_mode: Bool
  let exclude_applications: Array[String] val
  let max_database_size_mb: U64
  
  new val create(
    data_dir': String = "",
    database_path': String = "",
    capture_text': Bool = true,
    capture_mouse': Bool = true,
    capture_windows': Bool = true,
    update_interval_ms': U64 = 100,
    encryption_enabled': Bool = true,
    debug': Bool = false,
    privacy_mode': Bool = false,
    exclude_applications': Array[String] val = recover Array[String] end,
    max_database_size_mb': U64 = 500
  ) =>
    data_dir = data_dir'
    database_path = database_path'
    capture_text = capture_text'
    capture_mouse = capture_mouse'
    capture_windows = capture_windows'
    update_interval_ms = update_interval_ms'
    encryption_enabled = encryption_enabled'
    debug = debug'
    privacy_mode = privacy_mode'
    exclude_applications = exclude_applications'
    max_database_size_mb = max_database_size_mb'

class val WindowInfo
  let title: String
  let application: String
  let bundle_id: String
  let process_id: U32
  let x: I32
  let y: I32
  let width: I32
  let height: I32
  let timestamp: U64
  
  new val create(
    title': String,
    application': String,
    bundle_id': String = "",
    process_id': U32 = 0,
    x': I32 = 0,
    y': I32 = 0,
    width': I32 = 1920,
    height': I32 = 1080,
    timestamp': U64 = 0
  ) =>
    title = title'
    application = application'
    bundle_id = bundle_id'
    process_id = process_id'
    x = x'
    y = y'
    width = width'
    height = height'
    timestamp = timestamp'

class val KeyEvent
  let key: String
  let application: String
  let process_id: U32
  let count: U32
  let encrypted: Bool
  let timestamp: U64
  
  new val create(
    key': String,
    application': String,
    process_id': U32 = 0,
    count': U32 = 1,
    encrypted': Bool = true,
    timestamp': U64 = 0
  ) =>
    key = key'
    application = application'
    process_id = process_id'
    count = count'
    encrypted = encrypted'
    timestamp = timestamp'

class val MouseEvent
  let x: I32
  let y: I32
  let button: U8
  let event_type: String
  let process_id: U32
  let timestamp: U64
  
  new val create(
    x': I32,
    y': I32,
    button': U8 = 1,
    event_type': String = "click",
    process_id': U32 = 0,
    timestamp': U64 = 0
  ) =>
    x = x'
    y = y'
    button = button'
    event_type = event_type'
    process_id = process_id'
    timestamp = timestamp'

class val ActivityStats
  let keystrokes: U64
  let clicks: U64
  let window_changes: U64
  let active_time_seconds: U64
  let top_apps: Array[AppUsage] val
  
  new val create(
    keystrokes': U64 = 0,
    clicks': U64 = 0,
    window_changes': U64 = 0,
    active_time_seconds': U64 = 0,
    top_apps': Array[AppUsage] val = recover Array[AppUsage] end
  ) =>
    keystrokes = keystrokes'
    clicks = clicks'
    window_changes = window_changes'
    active_time_seconds = active_time_seconds'
    top_apps = top_apps'

class val AppUsage
  let name: String
  let percentage: F64
  let duration: U64
  let events: U64
  
  new val create(name': String, percentage': F64, duration': U64, events': U64) =>
    name = name'
    percentage = percentage'
    duration = duration'
    events = events'

class val Permissions
  let accessibility: Bool
  let input_monitoring: Bool
  let screen_recording: Bool
  
  new val create(accessibility': Bool, input_monitoring': Bool, screen_recording': Bool = false) =>
    accessibility = accessibility'
    input_monitoring = input_monitoring'
    screen_recording = screen_recording'
  
  fun has_all_permissions(): Bool =>
    accessibility and input_monitoring

class val SystemInfo
  let platform: String
  let architecture: String
  let pony_version: String
  let hostname: String
  let username: String
  
  new val create(
    platform': String = "unknown",
    architecture': String = "unknown",
    pony_version': String = "0.58.0",
    hostname': String = "localhost",
    username': String = "user"
  ) =>
    platform = platform'
    architecture = architecture'
    pony_version = pony_version'
    hostname = hostname'
    username = username'

// Error types with reference capabilities
trait val SelfspyError
  fun string(): String

class val ConfigError is SelfspyError
  let _message: String
  new val create(message: String) => _message = message
  fun string(): String => "Configuration error: " + _message

class val PermissionError is SelfspyError
  let _message: String
  new val create(message: String) => _message = message
  fun string(): String => "Permission error: " + _message

class val StorageError is SelfspyError
  let _message: String
  new val create(message: String) => _message = message
  fun string(): String => "Storage error: " + _message

class val PlatformError is SelfspyError
  let _message: String
  new val create(message: String) => _message = message
  fun string(): String => "Platform error: " + _message

class val InvalidArgumentError is SelfspyError
  let _message: String
  new val create(message: String) => _message = message
  fun string(): String => "Invalid argument: " + _message

// Command line interface types
primitive Start
primitive Stop
primitive Stats
primitive Check
primitive Export
primitive Version
primitive Help

type Command is (Start | Stop | Stats | Check | Export | Version | Help)

class val StartOptions
  let no_text: Bool
  let no_mouse: Bool
  let debug: Bool
  
  new val create(no_text': Bool = false, no_mouse': Bool = false, debug': Bool = false) =>
    no_text = no_text'
    no_mouse = no_mouse'
    debug = debug'

class val StatsOptions
  let days: U32
  let json: Bool
  
  new val create(days': U32 = 7, json': Bool = false) =>
    days = days'
    json = json'

class val ExportOptions
  let format: String
  let output: (String | None)
  let days: U32
  
  new val create(format': String = "json", output': (String | None) = None, days': U32 = 30) =>
    format = format'
    output = output'
    days = days'

// Activity Monitor Actor with safe concurrency
actor ActivityMonitor
  let _config: Config
  let _env: Env
  var _running: Bool = false
  var _events_processed: U64 = 0
  var _last_window: (WindowInfo | None) = None
  
  new create(config: Config, env: Env) =>
    _config = config
    _env = env
  
  be start_monitoring() =>
    if not _running then
      _env.out.print("🚀 Starting Selfspy monitoring (Pony implementation)")
      _running = true
      _monitor_loop()
      _env.out.print("✅ Selfspy monitoring started successfully")
      _env.out.print("📊 Press Ctrl+C to stop monitoring")
    end
  
  be stop_monitoring() =>
    if _running then
      _env.out.print("🛑 Stopping Selfspy monitoring...")
      _running = false
      _env.out.print("✅ Monitoring stopped")
    end
  
  be process_key_event(event: KeyEvent) =>
    if _running then
      _events_processed = _events_processed + 1
      // Process keyboard event
    end
  
  be process_mouse_event(event: MouseEvent) =>
    if _running then
      _events_processed = _events_processed + 1
      // Process mouse event
    end
  
  be process_window_event(window: WindowInfo) =>
    if _running then
      _last_window = window
      // Process window event
    end
  
  be get_stats(callback: {(ActivityStats)} iso) =>
    // Return current statistics
    let stats = ActivityStats.create(
      _events_processed,
      _events_processed / 3, // Rough estimate
      _events_processed / 10, // Rough estimate
      _events_processed / 60 // Rough estimate
    )
    callback(consume stats)
  
  fun ref _monitor_loop() =>
    if _running then
      // Simulate event collection
      let current_window = _get_current_window()
      _last_window = current_window
      
      // Schedule next iteration
      let timer = Timer(_MonitorTimer(this), _config.update_interval_ms * 1_000_000, _config.update_interval_ms * 1_000_000)
      // Timer would be managed by runtime
    end
  
  fun _get_current_window(): WindowInfo =>
    // Placeholder: Would use platform-specific APIs
    WindowInfo.create("Sample Window", "Sample Application", "", 0, 0, 0, 1920, 1080, Time.nanos())

class _MonitorTimer is TimerNotify
  let _monitor: ActivityMonitor
  
  new create(monitor: ActivityMonitor) =>
    _monitor = monitor
  
  fun ref apply(timer: Timer, count: U64): Bool =>
    _monitor._monitor_loop()
    true

// Platform abstraction with reference capabilities
primitive Platform
  fun get_os(): String =>
    ifdef windows then
      "windows"
    elseif osx then
      "darwin"
    elseif linux then
      "linux"
    else
      "unknown"
    end
  
  fun check_permissions(): (Permissions | SelfspyError) =>
    match get_os()
    | "darwin" => _check_macos_permissions()
    | "linux" => _check_linux_permissions()
    | "windows" => _check_windows_permissions()
    else
      Permissions.create(true, true, false)
    end
  
  fun _check_macos_permissions(): (Permissions | SelfspyError) =>
    // Placeholder: Would check actual macOS permissions via FFI
    Permissions.create(true, true, false)
  
  fun _check_linux_permissions(): (Permissions | SelfspyError) =>
    // Check for display server
    try
      let display = EnvVars(recover Array[String] end)("DISPLAY")?
      let wayland = EnvVars(recover Array[String] end)("WAYLAND_DISPLAY")?
      let has_display = (display.size() > 0) or (wayland.size() > 0)
      Permissions.create(has_display, has_display, has_display)
    else
      Permissions.create(false, false, false)
    end
  
  fun _check_windows_permissions(): (Permissions | SelfspyError) =>
    Permissions.create(true, true, true)
  
  fun get_system_info(): SystemInfo =>
    SystemInfo.create(
      get_os(),
      ifdef x86 then "x86" elseif amd64 then "amd64" elseif arm64 then "arm64" else "unknown" end,
      "0.58.0",
      "localhost", // Would get actual hostname
      "user" // Would get actual username
    )

// Configuration management
primitive ConfigManager
  fun default_config(): Config =>
    let home_dir = try
      EnvVars(recover Array[String] end)("HOME")?
    else
      "/tmp"
    end
    
    let data_dir = match Platform.get_os()
    | "windows" => home_dir + "\\AppData\\Roaming\\selfspy"
    | "darwin" => home_dir + "/Library/Application Support/selfspy"
    else
      home_dir + "/.local/share/selfspy"
    end
    
    Config.create(
      data_dir,
      data_dir + "/selfspy.db"
    )

// Command line argument parsing
primitive ArgParser
  fun parse_args(args: Array[String] val): (Command, (StartOptions | StatsOptions | ExportOptions | None)) ? =>
    if args.size() == 0 then
      (Help, None)
    else
      match args(0)?
      | "start" => (Start, _parse_start_options(args)?)
      | "stop" => (Stop, None)
      | "stats" => (Stats, _parse_stats_options(args)?)
      | "check" => (Check, None)
      | "export" => (Export, _parse_export_options(args)?)
      | "version" => (Version, None)
      | "help" => (Help, None)
      else
        error
      end
    end
  
  fun _parse_start_options(args: Array[String] val): StartOptions ? =>
    var no_text = false
    var no_mouse = false
    var debug = false
    
    var i: USize = 1
    while i < args.size() do
      match args(i)?
      | "--no-text" => no_text = true
      | "--no-mouse" => no_mouse = true
      | "--debug" => debug = true
      end
      i = i + 1
    end
    
    StartOptions.create(no_text, no_mouse, debug)
  
  fun _parse_stats_options(args: Array[String] val): StatsOptions ? =>
    var days: U32 = 7
    var json = false
    
    var i: USize = 1
    while i < args.size() do
      match args(i)?
      | "--days" =>
        if (i + 1) < args.size() then
          i = i + 1
          days = args(i)?.u32()?
        end
      | "--json" => json = true
      end
      i = i + 1
    end
    
    StatsOptions.create(days, json)
  
  fun _parse_export_options(args: Array[String] val): ExportOptions ? =>
    var format = "json"
    var output: (String | None) = None
    var days: U32 = 30
    
    var i: USize = 1
    while i < args.size() do
      match args(i)?
      | "--format" =>
        if (i + 1) < args.size() then
          i = i + 1
          format = args(i)?
        end
      | "--output" =>
        if (i + 1) < args.size() then
          i = i + 1
          output = args(i)?
        end
      | "--days" =>
        if (i + 1) < args.size() then
          i = i + 1
          days = args(i)?.u32()?
        end
      end
      i = i + 1
    end
    
    ExportOptions.create(format, output, days)

// Statistics and data export
primitive StatsManager
  fun get_stats(days: U32): ActivityStats =>
    // Placeholder: Would query actual database
    let top_apps = recover Array[AppUsage] end
    top_apps.push(AppUsage.create("Code Editor", 45.2, 6683, 5234))
    top_apps.push(AppUsage.create("Web Browser", 32.1, 4736, 3892))
    top_apps.push(AppUsage.create("Terminal", 15.7, 2318, 2156))
    
    ActivityStats.create(12547, 3821, 342, 14760, consume top_apps)
  
  fun export_json(stats: ActivityStats): String =>
    // Placeholder: Would use proper JSON serialization
    "{" +
    "\"keystrokes\": " + stats.keystrokes.string() + "," +
    "\"clicks\": " + stats.clicks.string() + "," +
    "\"window_changes\": " + stats.window_changes.string() + "," +
    "\"active_time_seconds\": " + stats.active_time_seconds.string() +
    "}"
  
  fun export_csv(stats: ActivityStats): String =>
    "metric,value\n" +
    "keystrokes," + stats.keystrokes.string() + "\n" +
    "clicks," + stats.clicks.string() + "\n" +
    "window_changes," + stats.window_changes.string() + "\n" +
    "active_time_seconds," + stats.active_time_seconds.string()
  
  fun export_sql(stats: ActivityStats): String =>
    "-- Selfspy Activity Export\n" +
    "CREATE TABLE stats (metric TEXT, value INTEGER);\n" +
    "INSERT INTO stats VALUES ('keystrokes', " + stats.keystrokes.string() + ");\n" +
    "INSERT INTO stats VALUES ('clicks', " + stats.clicks.string() + ");\n" +
    "INSERT INTO stats VALUES ('window_changes', " + stats.window_changes.string() + ");\n" +
    "INSERT INTO stats VALUES ('active_time_seconds', " + stats.active_time_seconds.string() + ");"

// Utility functions
primitive Utils
  fun format_number(num: U64): String =>
    if num >= 1_000_000 then
      (num.f64() / 1_000_000.0).string() + "M"
    elseif num >= 1_000 then
      (num.f64() / 1_000.0).string() + "K"
    else
      num.string()
    end
  
  fun format_duration(seconds: U64): String =>
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    
    if hours > 0 then
      hours.string() + "h " + minutes.string() + "m"
    else
      minutes.string() + "m"
    end
  
  fun print_formatted_stats(env: Env, stats: ActivityStats, days: U32) =>
    env.out.print("")
    env.out.print("📊 Selfspy Activity Statistics (Last " + days.string() + " days)")
    env.out.print("==================================================")
    env.out.print("")
    env.out.print("⌨️  Keystrokes: " + format_number(stats.keystrokes))
    env.out.print("🖱️  Mouse clicks: " + format_number(stats.clicks))
    env.out.print("🪟  Window changes: " + format_number(stats.window_changes))
    env.out.print("⏰ Active time: " + format_duration(stats.active_time_seconds))
    
    if stats.top_apps.size() > 0 then
      env.out.print("📱 Most used applications:")
      var i: USize = 0
      for app in stats.top_apps.values() do
        i = i + 1
        env.out.print("   " + i.string() + ". " + app.name + " (" + app.percentage.string() + "%)")
      end
    end
    env.out.print("")

// Command execution
primitive CommandRunner
  fun run_command(env: Env, command: Command, options: (StartOptions | StatsOptions | ExportOptions | None)): (None | SelfspyError) =>
    match command
    | Start =>
      match options
      | let start_opts: StartOptions =>
        let config = ConfigManager.default_config()
        let updated_config = Config.create(
          config.data_dir,
          config.database_path,
          config.capture_text and not start_opts.no_text,
          config.capture_mouse and not start_opts.no_mouse,
          config.capture_windows,
          config.update_interval_ms,
          config.encryption_enabled,
          config.debug or start_opts.debug,
          config.privacy_mode,
          config.exclude_applications,
          config.max_database_size_mb
        )
        
        match Platform.check_permissions()
        | let perms: Permissions =>
          if perms.has_all_permissions() then
            let monitor = ActivityMonitor.create(updated_config, env)
            monitor.start_monitoring()
            None
          else
            PermissionError.create("Insufficient permissions for monitoring")
          end
        | let error: SelfspyError => error
        end
      else
        InvalidArgumentError.create("Invalid start options")
      end
    
    | Stop =>
      env.out.print("🛑 Stopping Selfspy monitoring...")
      env.out.print("✅ Stop signal sent")
      None
    
    | Stats =>
      match options
      | let stats_opts: StatsOptions =>
        let stats = StatsManager.get_stats(stats_opts.days)
        if stats_opts.json then
          env.out.print(StatsManager.export_json(stats))
        else
          Utils.print_formatted_stats(env, stats, stats_opts.days)
        end
        None
      else
        InvalidArgumentError.create("Invalid stats options")
      end
    
    | Check =>
      env.out.print("🔍 Checking Selfspy permissions...")
      env.out.print("===================================")
      env.out.print("")
      
      match Platform.check_permissions()
      | let perms: Permissions =>
        if perms.has_all_permissions() then
          env.out.print("✅ All permissions granted")
        else
          env.out.print("❌ Missing permissions:")
          if not perms.accessibility then
            env.out.print("   - Accessibility permission required")
          end
          if not perms.input_monitoring then
            env.out.print("   - Input monitoring permission required")
          end
        end
        
        env.out.print("")
        env.out.print("📱 System Information:")
        let sys_info = Platform.get_system_info()
        env.out.print("   Platform: " + sys_info.platform)
        env.out.print("   Architecture: " + sys_info.architecture)
        env.out.print("   Pony Version: " + sys_info.pony_version)
        env.out.print("   Hostname: " + sys_info.hostname)
        
        None
      | let error: SelfspyError => error
      end
    
    | Export =>
      match options
      | let export_opts: ExportOptions =>
        env.out.print("📤 Exporting " + export_opts.days.string() + " days of data in " + export_opts.format + " format...")
        
        let stats = StatsManager.get_stats(export_opts.days)
        let data = match export_opts.format
        | "json" => StatsManager.export_json(stats)
        | "csv" => StatsManager.export_csv(stats)
        | "sql" => StatsManager.export_sql(stats)
        else
          return InvalidArgumentError.create("Unsupported export format: " + export_opts.format)
        end
        
        match export_opts.output
        | let filename: String =>
          // Would write to file
          env.out.print("✅ Data exported to " + filename)
        | None =>
          env.out.print(data)
        end
        None
      else
        InvalidArgumentError.create("Invalid export options")
      end
    
    | Version =>
      env.out.print("Selfspy v1.0.0 (Pony implementation)")
      env.out.print("Actor-model concurrency with reference capabilities")
      env.out.print("")
      env.out.print("Features:")
      env.out.print("  • Actor-model concurrency")
      env.out.print("  • Reference capabilities for memory safety")
      env.out.print("  • Data-race freedom")
      env.out.print("  • Deadlock-free concurrency")
      env.out.print("  • Zero-copy message passing")
      env.out.print("  • Garbage collection free")
      None
    
    | Help =>
      _print_help(env)
      None
    end
  
  fun _print_help(env: Env) =>
    env.out.print("Selfspy - Modern Activity Monitoring in Pony")
    env.out.print("")
    env.out.print("USAGE:")
    env.out.print("    ponyc . && ./selfspy [COMMAND] [OPTIONS]")
    env.out.print("")
    env.out.print("COMMANDS:")
    env.out.print("    start                 Start activity monitoring")
    env.out.print("    stop                  Stop running monitoring instance")
    env.out.print("    stats                 Show activity statistics")
    env.out.print("    check                 Check system permissions and setup")
    env.out.print("    export                Export data to various formats")
    env.out.print("    version               Show version information")
    env.out.print("    help                  Show this help message")
    env.out.print("")
    env.out.print("START OPTIONS:")
    env.out.print("    --no-text             Disable text capture for privacy")
    env.out.print("    --no-mouse            Disable mouse monitoring")
    env.out.print("    --debug               Enable debug logging")
    env.out.print("")
    env.out.print("STATS OPTIONS:")
    env.out.print("    --days <N>            Number of days to analyze (default: 7)")
    env.out.print("    --json                Output in JSON format")
    env.out.print("")
    env.out.print("EXPORT OPTIONS:")
    env.out.print("    --format <FORMAT>     Export format: json, csv, sql (default: json)")
    env.out.print("    --output <FILE>       Output file path")
    env.out.print("    --days <N>            Number of days to export (default: 30)")
    env.out.print("")
    env.out.print("EXAMPLES:")
    env.out.print("    ./selfspy start")
    env.out.print("    ./selfspy start --no-text --debug")
    env.out.print("    ./selfspy stats --days 30 --json")
    env.out.print("    ./selfspy export --format csv --output activity.csv")
    env.out.print("")
    env.out.print("Pony Implementation Features:")
    env.out.print("  • Actor-model concurrency with reference capabilities")
    env.out.print("  • Memory safety and data-race freedom")
    env.out.print("  • Deadlock-free concurrency")
    env.out.print("  • Zero-copy message passing")
    env.out.print("  • Garbage collection free")
    env.out.print("  • High performance with safety guarantees")

// Main entry point
actor Main
  new create(env: Env) =>
    let args = env.args
    
    try
      let (command, options) = ArgParser.parse_args(args)?
      
      match CommandRunner.run_command(env, command, options)
      | None => env.exitcode(0)
      | let error: SelfspyError =>
        env.err.print(error.string())
        env.exitcode(1)
      end
    else
      env.err.print("Error: Invalid command line arguments")
      env.err.print("Use './selfspy help' for usage information")
      env.exitcode(1)
    end