## Selfspy - Modern Activity Monitoring in Nim
## 
## Fast, efficient, cross-platform activity monitoring with encrypted storage.
## Monitors keystrokes, mouse activity, window changes, and terminal commands.

import std/[asyncdispatch, os, strutils, json, times, logging]
import chronicles, argparse, sqliter
import config, monitor, storage, platform, encryption

# Configure logging
chronicles.setLogLevel(LogLevel.INFO)

type
  SelfspyApp = ref object
    config: Config
    monitor: ActivityMonitor
    storage: ActivityStorage
    running: bool

proc newSelfspyApp(): SelfspyApp =
  result = SelfspyApp(
    config: loadConfig(),
    running: false
  )
  result.storage = newActivityStorage(result.config.database.path)
  result.monitor = newActivityMonitor(result.config, result.storage)

proc start(app: SelfspyApp) {.async.} =
  """Start monitoring activity."""
  info "Starting Selfspy monitoring..."
  
  # Initialize storage
  await app.storage.initialize()
  
  # Start monitoring
  app.running = true
  await app.monitor.start()
  
  # Main loop
  while app.running:
    await sleepAsync(1000)  # Check every second
    
    # Handle shutdown signals gracefully
    if not app.monitor.isRunning():
      warn "Monitor stopped unexpectedly"
      break
  
  info "Selfspy monitoring stopped"

proc stop(app: SelfspyApp) {.async.} =
  """Stop monitoring gracefully."""
  info "Stopping Selfspy..."
  app.running = false
  await app.monitor.stop()
  await app.storage.close()

proc stats(app: SelfspyApp, days: int = 7) {.async.} =
  """Show activity statistics."""
  let stats = await app.storage.getStats(days)
  
  echo "\n📊 Selfspy Activity Statistics (Last $1 days)" % $days
  echo "=" & "=".repeat(45)
  echo ""
  echo "⌨️  Keystrokes: $1" % $stats.keystrokes
  echo "🖱️  Mouse clicks: $1" % $stats.clicks  
  echo "🪟  Window changes: $1" % $stats.windowChanges
  echo "⏰ Active time: $1" % formatDuration(stats.activeTime)
  echo "📱 Top applications:"
  
  for i, app in stats.topApps:
    echo "   $1. $2 ($3%)" % [$(i+1), app.name, $app.percentage]

proc handleShutdown() {.noconv.} =
  """Handle Ctrl+C gracefully."""
  echo "\nShutting down gracefully..."
  quit(0)

proc main() =
  """Main entry point with command line parsing."""
  let parser = newParser("selfspy"):
    help("Modern activity monitoring - fast, secure, cross-platform")
    
    command("start"):
      help("Start activity monitoring")
      flag("--no-text", help="Disable text capture for privacy")
      flag("--no-mouse", help="Disable mouse monitoring")  
      flag("--debug", help="Enable debug logging")
      
    command("stop"):
      help("Stop running monitoring instance")
      
    command("stats"):
      help("Show activity statistics")
      option("--days", default="7", help="Number of days to analyze")
      flag("--json", help="Output in JSON format")
      
    command("check"):
      help("Check system permissions and setup")
      
    command("export"):
      help("Export data to various formats")
      option("--format", default="json", help="Export format (json, csv, sql)")
      option("--output", help="Output file path")
      option("--days", default="30", help="Number of days to export")

  try:
    let opts = parser.parse()
    let app = newSelfspyApp()
    
    # Set up signal handling
    setControlCHook(handleShutdown)
    
    case opts.command:
    of "start":
      if opts.debug:
        chronicles.setLogLevel(LogLevel.DEBUG)
      
      # Update config based on flags
      if opts.no_text:
        app.config.monitoring.captureText = false
      if opts.no_mouse:
        app.config.monitoring.captureMouse = false
        
      waitFor app.start()
      
    of "stop":
      # Send stop signal to running instance
      echo "Stopping Selfspy..."
      # Implementation would send signal to running process
      
    of "stats":
      let days = parseInt(opts.days)
      waitFor app.stats(days)
      
    of "check":
      # Check permissions and system setup
      echo "🔍 Checking Selfspy setup..."
      let perms = checkPermissions()
      
      if perms.hasAllPermissions:
        echo "✅ All permissions granted"
      else:
        echo "❌ Missing permissions:"
        if not perms.accessibility:
          echo "   - Accessibility permission required"
        if not perms.screenRecording:
          echo "   - Screen recording permission (optional)"
      
    of "export":
      echo "Exporting data..."
      # Implementation for data export
      
    else:
      echo parser.help
      
  except ShortCircuit as e:
    if e.flag == "help":
      echo parser.help
    quit(1)
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

when isMainModule:
  main()