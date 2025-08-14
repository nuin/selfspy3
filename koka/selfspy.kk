// Selfspy - Modern Activity Monitoring in Koka
//
// A function-oriented language with effect types and algebraic effects,
// perfect for building reliable, composable systems with mathematical foundations.

import std/os/env
import std/os/file
import std/os/path
import std/num/int32
import std/text/parse
import std/time/duration
import std/time/instant
import std/async

// Core data structures with algebraic data types
struct config
  data-dir: string
  database-path: string
  capture-text: bool = True
  capture-mouse: bool = True
  capture-windows: bool = True
  update-interval-ms: int = 100
  encryption-enabled: bool = True
  debug: bool = False
  privacy-mode: bool = False
  exclude-applications: list<string> = []
  max-database-size-mb: int = 500

struct window-info
  title: string
  application: string
  bundle-id: string
  process-id: int
  x: int
  y: int
  width: int
  height: int
  timestamp: instant

struct key-event
  key: string
  application: string
  process-id: int
  count: int
  encrypted: bool
  timestamp: instant

struct mouse-event
  x: int
  y: int
  button: int
  event-type: string
  process-id: int
  timestamp: instant

struct activity-stats
  keystrokes: int
  clicks: int
  window-changes: int
  active-time-seconds: int
  top-apps: list<app-usage>

struct app-usage
  name: string
  percentage: float64
  duration: int
  events: int

struct permissions
  accessibility: bool
  input-monitoring: bool
  screen-recording: bool

struct system-info
  platform: string
  architecture: string
  koka-version: string
  hostname: string
  username: string

// Command line options with algebraic data types
struct start-options
  no-text: bool = False
  no-mouse: bool = False
  debug: bool = False

struct stats-options
  days: int = 7
  json: bool = False

struct export-options
  format: string = "json"
  output: maybe<string> = Nothing
  days: int = 30

// Effect types for system operations
effect io-effect
  fun print-line(msg: string): ()
  fun read-env(key: string): maybe<string>
  fun write-file(path: string, content: string): maybe<()>
  fun create-dir(path: string): maybe<()>
  fun file-exists(path: string): bool

// Error handling with algebraic effects
effect exn-effect
  fun error(msg: string): a

// Platform abstraction with pure functions
fun get-os(): div string
  val os = get-host-os()
  match os
    "windows" -> "windows"
    "linux" -> "linux"
    "macos" -> "darwin"
    _ -> "unknown"

fun get-home-dir(): <io-effect> maybe<string>
  read-env("HOME")

fun get-data-dir(): <io-effect> string
  val home = match get-home-dir()
    Just(h) -> h
    Nothing -> "/tmp"
  
  match get-os()
    "windows" -> 
      match read-env("APPDATA")
        Just(appdata) -> appdata ++ "/selfspy"
        Nothing -> home ++ "/selfspy"
    "darwin" -> home ++ "/Library/Application Support/selfspy"
    _ -> home ++ "/.local/share/selfspy"

fun default-config(): <io-effect> config
  val data-dir = get-data-dir()
  Config(
    data-dir = data-dir,
    database-path = data-dir ++ "/selfspy.db"
  )

// Command line parsing with pattern matching and effects
fun parse-start-options(args: list<string>): start-options
  args.foldl(Start-options()) fn(opts, arg)
    match arg
      "--no-text" -> opts(no-text = True)
      "--no-mouse" -> opts(no-mouse = True) 
      "--debug" -> opts(debug = True)
      _ -> opts

fun parse-stats-options(args: list<string>): start-options
  fun parse-helper(args: list<string>, opts: stats-options): stats-options
    match args
      [] -> opts
      ["--days", day-str] ++ rest ->
        val days = parse-int(day-str).default(7)
        parse-helper(rest, opts(days = days))
      ["--json"] ++ rest ->
        parse-helper(rest, opts(json = True))
      [_] ++ rest ->
        parse-helper(rest, opts)
  
  parse-helper(args, Stats-options())

fun parse-export-options(args: list<string>): export-options
  fun parse-helper(args: list<string>, opts: export-options): export-options
    match args
      [] -> opts
      ["--format", fmt] ++ rest ->
        parse-helper(rest, opts(format = fmt))
      ["--output", out] ++ rest ->
        parse-helper(rest, opts(output = Just(out)))
      ["--days", day-str] ++ rest ->
        val days = parse-int(day-str).default(30)
        parse-helper(rest, opts(days = days))
      [_] ++ rest ->
        parse-helper(rest, opts)
  
  parse-helper(args, Export-options())

// Platform abstraction with effect types
fun check-permissions(): <io-effect> permissions
  match get-os()
    "darwin" ->
      // macOS permission checking (placeholder)
      Permissions(
        accessibility = True,
        input-monitoring = True,
        screen-recording = False
      )
    "linux" ->
      // Check for display server
      val display = read-env("DISPLAY").is-just
      val wayland = read-env("WAYLAND_DISPLAY").is-just
      val has-display = display || wayland
      
      Permissions(
        accessibility = has-display,
        input-monitoring = has-display,
        screen-recording = has-display
      )
    "windows" ->
      Permissions(
        accessibility = True,
        input-monitoring = True,
        screen-recording = True
      )
    _ ->
      Permissions(
        accessibility = True,
        input-monitoring = True,
        screen-recording = False
      )

fun has-all-permissions(perms: permissions): bool
  perms.accessibility && perms.input-monitoring

fun request-permissions(): <io-effect> bool
  match get-os()
    "darwin" ->
      print-line("Please grant accessibility permissions in System Preferences")
      print-line("Security & Privacy > Privacy > Accessibility")
      True
    _ -> True

// System information with safe error handling
fun get-system-info(): <io-effect> system-info
  val hostname = read-env("HOSTNAME").default("localhost")
  val username = read-env("USER").or-else(fn() read-env("USERNAME")).default("unknown")
  
  System-info(
    platform = get-os(),
    architecture = "unknown", // Koka doesn't expose this directly
    koka-version = "2.4.2", // Current Koka version
    hostname = hostname,
    username = username
  )

// Activity monitoring with algebraic effects
effect monitor-effect
  fun start-monitor(config: config): ()
  fun stop-monitor(): ()
  fun is-running(): bool
  fun get-events-processed(): int

fun start-monitoring(options: start-options): <io-effect,exn-effect,monitor-effect> ()
  print-line("🚀 Starting Selfspy monitoring (Koka implementation)")
  
  val config = default-config()
  val updated-config = config(
    capture-text = config.capture-text && !options.no-text,
    capture-mouse = config.capture-mouse && !options.no-mouse,
    debug = config.debug || options.debug
  )
  
  // Check permissions
  val perms = check-permissions()
  if !has-all-permissions(perms) then
    print-line("❌ Insufficient permissions for monitoring")
    print-line("Missing permissions:")
    
    if !perms.accessibility then
      print-line("   - Accessibility permission required")
    
    if !perms.input-monitoring then
      print-line("   - Input monitoring permission required")
    
    print-line("")
    print-line("Attempting to request permissions...")
    
    if !request-permissions() then
      error("Failed to obtain required permissions")
  
  // Create data directory if needed
  if !file-exists(updated-config.data-dir) then
    match create-dir(updated-config.data-dir)
      Nothing -> error("Failed to create data directory")
      Just(()) -> ()
  
  print-line("✅ Selfspy monitoring started successfully")
  print-line("📊 Press Ctrl+C to stop monitoring")
  
  // Start monitoring with effect handler
  start-monitor(updated-config)
  
  // Monitoring loop with cooperative effects
  fun monitoring-loop(): <monitor-effect> ()
    if is-running() then
      // Simulate event processing
      val _ = get-events-processed()
      monitoring-loop()
  
  monitoring-loop()

fun stop-monitoring(): <io-effect,monitor-effect> ()
  print-line("🛑 Stopping Selfspy monitoring...")
  stop-monitor()
  print-line("✅ Stop signal sent")

// Statistics with functional data processing
fun get-stats(days: int): activity-stats
  // Placeholder: Would query actual database
  val top-apps = [
    App-usage(name = "Code Editor", percentage = 45.2, duration = 6683, events = 5234),
    App-usage(name = "Web Browser", percentage = 32.1, duration = 4736, events = 3892),
    App-usage(name = "Terminal", percentage = 15.7, duration = 2318, events = 2156)
  ]
  
  Activity-stats(
    keystrokes = 12547,
    clicks = 3821,
    window-changes = 342,
    active-time-seconds = 14760,
    top-apps = top-apps
  )

fun show-stats(options: stats-options): <io-effect> ()
  val stats = get-stats(options.days)
  
  if options.json then
    // JSON output (simplified)
    print-line("{")
    print-line("  \"keystrokes\": " ++ show(stats.keystrokes) ++ ",")
    print-line("  \"clicks\": " ++ show(stats.clicks) ++ ",")
    print-line("  \"window_changes\": " ++ show(stats.window-changes) ++ ",")
    print-line("  \"active_time_seconds\": " ++ show(stats.active-time-seconds))
    print-line("}")
  else
    print-formatted-stats(stats, options.days)

// Data export with effect-based file operations
fun export-data(options: export-options): <io-effect,exn-effect> ()
  print-line("📤 Exporting " ++ show(options.days) ++ " days of data in " ++ options.format ++ " format...")
  
  val stats = get-stats(options.days)
  
  val data = match options.format
    "json" ->
      "{" ++
      "\"keystrokes\":" ++ show(stats.keystrokes) ++ "," ++
      "\"clicks\":" ++ show(stats.clicks) ++ "," ++
      "\"window_changes\":" ++ show(stats.window-changes) ++ "," ++
      "\"active_time_seconds\":" ++ show(stats.active-time-seconds) ++
      "}"
    "csv" ->
      "metric,value\n" ++
      "keystrokes," ++ show(stats.keystrokes) ++ "\n" ++
      "clicks," ++ show(stats.clicks) ++ "\n" ++
      "window_changes," ++ show(stats.window-changes) ++ "\n" ++
      "active_time_seconds," ++ show(stats.active-time-seconds)
    "sql" ->
      "-- Selfspy Activity Export\n" ++
      "CREATE TABLE stats (metric TEXT, value INTEGER);\n" ++
      "INSERT INTO stats VALUES ('keystrokes', " ++ show(stats.keystrokes) ++ ");\n" ++
      "INSERT INTO stats VALUES ('clicks', " ++ show(stats.clicks) ++ ");\n" ++
      "INSERT INTO stats VALUES ('window_changes', " ++ show(stats.window-changes) ++ ");\n" ++
      "INSERT INTO stats VALUES ('active_time_seconds', " ++ show(stats.active-time-seconds) ++ ");"
    _ ->
      error("Unsupported export format: " ++ options.format)
  
  match options.output
    Just(output-path) ->
      match write-file(output-path, data)
        Nothing -> error("Failed to write to file: " ++ output-path)
        Just(()) -> print-line("✅ Data exported to " ++ output-path)
    Nothing ->
      print-line(data)

fun check-system(): <io-effect> ()
  print-line("🔍 Checking Selfspy permissions...")
  print-line("===================================")
  print-line("")
  
  val perms = check-permissions()
  
  if has-all-permissions(perms) then
    print-line("✅ All permissions granted")
  else
    print-line("❌ Missing permissions:")
    
    if !perms.accessibility then
      print-line("   - Accessibility permission required")
    
    if !perms.input-monitoring then
      print-line("   - Input monitoring permission required")
  
  print-line("")
  print-line("📱 System Information:")
  val sys-info = get-system-info()
  print-line("   Platform: " ++ sys-info.platform)
  print-line("   Architecture: " ++ sys-info.architecture)
  print-line("   Koka Version: " ++ sys-info.koka-version)
  print-line("   Hostname: " ++ sys-info.hostname)
  print-line("   Username: " ++ sys-info.username)

fun show-version(): <io-effect> ()
  print-line("Selfspy v1.0.0 (Koka implementation)")
  print-line("Function-oriented language with effect types")
  print-line("")
  print-line("Features:")
  print-line("  • Algebraic effects and effect types")
  print-line("  • Mathematical foundations")
  print-line("  • Excellent performance")
  print-line("  • Safe concurrent programming")
  print-line("  • Functional programming with effects")
  print-line("  • Perfect for reliable system design")

// Utility functions with pure functional programming
fun format-number(num: int): string
  if num >= 1000000 then
    show(num / 1000000) ++ "M"
  elif num >= 1000 then
    show(num / 1000) ++ "K"
  else
    show(num)

fun format-duration(seconds: int): string
  val hours = seconds / 3600
  val minutes = (seconds % 3600) / 60
  
  if hours > 0 then
    show(hours) ++ "h " ++ show(minutes) ++ "m"
  else
    show(minutes) ++ "m"

fun print-formatted-stats(stats: activity-stats, days: int): <io-effect> ()
  print-line("")
  print-line("📊 Selfspy Activity Statistics (Last " ++ show(days) ++ " days)")
  print-line("==================================================")
  print-line("")
  print-line("⌨️  Keystrokes: " ++ format-number(stats.keystrokes))
  print-line("🖱️  Mouse clicks: " ++ format-number(stats.clicks))
  print-line("🪟  Window changes: " ++ format-number(stats.window-changes))
  print-line("⏰ Active time: " ++ format-duration(stats.active-time-seconds))
  
  if !stats.top-apps.is-empty then
    print-line("📱 Most used applications:")
    stats.top-apps.foldl-indexed(()) fn(i, _, app)
      print-line("   " ++ show(i + 1) ++ ". " ++ app.name ++ " (" ++ show(app.percentage) ++ "%)")
  
  print-line("")

fun print-help(): <io-effect> ()
  print-line("Selfspy - Modern Activity Monitoring in Koka")
  print-line("")
  print-line("USAGE:")
  print-line("    koka selfspy.kk [COMMAND] [OPTIONS]")
  print-line("")
  print-line("COMMANDS:")
  print-line("    start                 Start activity monitoring")
  print-line("    stop                  Stop running monitoring instance")
  print-line("    stats                 Show activity statistics")
  print-line("    check                 Check system permissions and setup")
  print-line("    export                Export data to various formats")
  print-line("    version               Show version information")
  print-line("    help                  Show this help message")
  print-line("")
  print-line("START OPTIONS:")
  print-line("    --no-text             Disable text capture for privacy")
  print-line("    --no-mouse            Disable mouse monitoring")
  print-line("    --debug               Enable debug logging")
  print-line("")
  print-line("STATS OPTIONS:")
  print-line("    --days <N>            Number of days to analyze (default: 7)")
  print-line("    --json                Output in JSON format")
  print-line("")
  print-line("EXPORT OPTIONS:")
  print-line("    --format <FORMAT>     Export format: json, csv, sql (default: json)")
  print-line("    --output <FILE>       Output file path")
  print-line("    --days <N>            Number of days to export (default: 30)")
  print-line("")
  print-line("EXAMPLES:")
  print-line("    koka selfspy.kk start")
  print-line("    koka selfspy.kk start --no-text --debug")
  print-line("    koka selfspy.kk stats --days 30 --json")
  print-line("    koka selfspy.kk export --format csv --output activity.csv")
  print-line("")
  print-line("Koka Implementation Features:")
  print-line("  • Algebraic effects for composable system programming")
  print-line("  • Effect types for safe resource management")
  print-line("  • Mathematical foundations with category theory")
  print-line("  • Excellent performance with zero-cost abstractions")
  print-line("  • Safe concurrent programming with effect isolation")
  print-line("  • Perfect for building reliable, composable systems")

// Command execution with effect composition
fun execute-command(command: string, args: list<string>): <io-effect,exn-effect,monitor-effect> ()
  match command
    "start" ->
      val options = parse-start-options(args)
      start-monitoring(options)
    "stop" ->
      stop-monitoring()
    "stats" ->
      val options = parse-stats-options(args)
      show-stats(options)
    "check" ->
      check-system()
    "export" ->
      val options = parse-export-options(args)
      export-data(options)
    "version" ->
      show-version()
    "help" ->
      print-help()
    _ ->
      print-line("Error: Unknown command: " ++ command)
      print-line("Use 'koka selfspy.kk help' for usage information")
      error("Invalid command")

// Effect handlers for system operations
val io-handler = handler
  fun print-line(msg) println(msg)
  fun read-env(key) get-env(key)
  fun write-file(path, content) try-write-text-file(path.path, content).maybe
  fun create-dir(path) try-ensure-dir(path.path).maybe
  fun file-exists(path) is-file(path.path)

val exn-handler = handler
  fun error(msg) throw(msg)

val monitor-handler = handler
  var running := False
  var events := 0
  
  fun start-monitor(config)
    running := True
    events := 0
  
  fun stop-monitor()
    running := False
  
  fun is-running()
    !running
  
  fun get-events-processed()
    events := events + 1
    events

// Main entry point with effect handling
fun main()
  val args = get-args()
  
  if args.is-empty then
    with io-handler
    print-help()
  else
    val command = args.head.default("help")
    val command-args = args.tail
    
    with io-handler
    with exn-handler
    with monitor-handler
    execute-command(command, command-args)