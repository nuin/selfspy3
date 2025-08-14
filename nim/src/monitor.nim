## Activity monitoring orchestrator
## Coordinates keyboard, mouse, and window monitoring

import std/[asyncdispatch, times, json, tables, sequtils]
import chronicles
import config, platform, storage, encryption

type
  ActivityMonitor* = ref object
    config: Config
    storage: ActivityStorage
    running: bool
    keyboardTask: Future[void]
    mouseTask: Future[void]
    windowTask: Future[void]
    statsTask: Future[void]
    
    # Buffers for batching events
    keyBuffer: seq[KeyEvent]
    mouseBuffer: seq[MouseEvent]
    currentWindow: WindowInfo
    lastWindowCheck: DateTime
    
    # Statistics
    stats: Table[string, int]

proc newActivityMonitor*(config: Config, storage: ActivityStorage): ActivityMonitor =
  """Create new activity monitor."""
  result = ActivityMonitor(
    config: config,
    storage: storage,
    running: false,
    keyBuffer: @[],
    mouseBuffer: @[],
    lastWindowCheck: now(),
    stats: initTable[string, int]()
  )

proc flushBuffers(monitor: ActivityMonitor) {.async.} =
  """Flush event buffers to storage."""
  if monitor.keyBuffer.len > 0:
    await monitor.storage.storeKeyEvents(monitor.keyBuffer)
    monitor.keyBuffer.setLen(0)
    debug "Flushed key events", count=monitor.keyBuffer.len
    
  if monitor.mouseBuffer.len > 0:
    await monitor.storage.storeMouseEvents(monitor.mouseBuffer)
    monitor.mouseBuffer.setLen(0)
    debug "Flushed mouse events", count=monitor.mouseBuffer.len

proc updateStats(monitor: ActivityMonitor, eventType: string) =
  """Update internal statistics."""
  if eventType in monitor.stats:
    monitor.stats[eventType].inc()
  else:
    monitor.stats[eventType] = 1

proc onKeyEvent(monitor: ActivityMonitor, event: KeyEvent) {.async.} =
  """Handle keyboard events."""
  if not monitor.config.monitoring.captureText:
    return
    
  # Encrypt keystroke if encryption is enabled
  var processedEvent = event
  if monitor.config.encryption.enabled:
    processedEvent.key = encrypt(event.key, monitor.config.encryption)
  
  monitor.keyBuffer.add(processedEvent)
  monitor.updateStats("keystrokes")
  
  # Flush buffer if it gets too large
  if monitor.keyBuffer.len >= 100:
    await monitor.flushBuffers()

proc onMouseEvent(monitor: ActivityMonitor, event: MouseEvent) {.async.} =
  """Handle mouse events."""
  if not monitor.config.monitoring.captureMouse:
    return
    
  monitor.mouseBuffer.add(event)
  monitor.updateStats("mouse_events")
  
  # Flush buffer if it gets too large
  if monitor.mouseBuffer.len >= 50:
    await monitor.flushBuffers()

proc checkWindow(monitor: ActivityMonitor) {.async.} =
  """Check for window changes."""
  if not monitor.config.monitoring.captureWindows:
    return
    
  let now = now()
  if now - monitor.lastWindowCheck < initDuration(seconds = 1):
    return  # Don't check too frequently
    
  let window = await getCurrentWindow()
  
  # Check if window changed
  if window.title != monitor.currentWindow.title or 
     window.application != monitor.currentWindow.application:
    
    info "Window changed", 
         from=monitor.currentWindow.application, 
         to=window.application,
         title=window.title
    
    await monitor.storage.storeWindowEvent(window)
    monitor.currentWindow = window
    monitor.updateStats("window_changes")
  
  monitor.lastWindowCheck = now

proc startKeyboardMonitoring(monitor: ActivityMonitor) {.async.} =
  """Start keyboard monitoring task."""
  try:
    await startKeyboardMonitoring(proc(event: KeyEvent): Future[void] {.async.} =
      await monitor.onKeyEvent(event)
    )
  except Exception as e:
    error "Keyboard monitoring failed", error=e.msg

proc startMouseMonitoring(monitor: ActivityMonitor) {.async.} =
  """Start mouse monitoring task.""" 
  try:
    await startMouseMonitoring(proc(event: MouseEvent): Future[void] {.async.} =
      await monitor.onMouseEvent(event)
    )
  except Exception as e:
    error "Mouse monitoring failed", error=e.msg

proc startWindowMonitoring(monitor: ActivityMonitor) {.async.} =
  """Start window monitoring task."""
  while monitor.running:
    try:
      await monitor.checkWindow()
      await sleepAsync(monitor.config.monitoring.updateInterval)
    except Exception as e:
      error "Window monitoring error", error=e.msg
      await sleepAsync(5000)  # Wait before retrying

proc startStatsReporting(monitor: ActivityMonitor) {.async.} =
  """Periodic statistics reporting and buffer flushing."""
  var lastReport = now()
  
  while monitor.running:
    await sleepAsync(10000)  # Every 10 seconds
    
    # Flush buffers periodically
    await monitor.flushBuffers()
    
    # Report stats every 5 minutes
    if now() - lastReport > initDuration(minutes = 5):
      info "Activity stats", stats=monitor.stats
      lastReport = now()

proc start*(monitor: ActivityMonitor) {.async.} =
  """Start all monitoring tasks."""
  if monitor.running:
    warn "Monitor already running"
    return
    
  info "Starting activity monitoring"
  
  # Check permissions first
  let perms = checkPermissions()
  if not perms.hasAllPermissions:
    error "Insufficient permissions for monitoring"
    if not await requestPermissions():
      raise newException(Exception, "Failed to obtain required permissions")
  
  monitor.running = true
  
  # Start monitoring tasks
  monitor.keyboardTask = monitor.startKeyboardMonitoring()
  monitor.mouseTask = monitor.startMouseMonitoring()
  monitor.windowTask = monitor.startWindowMonitoring()
  monitor.statsTask = monitor.startStatsReporting()
  
  # Get initial window state
  monitor.currentWindow = await getCurrentWindow()
  await monitor.storage.storeWindowEvent(monitor.currentWindow)
  
  info "Activity monitoring started successfully"

proc stop*(monitor: ActivityMonitor) {.async.} =
  """Stop all monitoring gracefully."""
  if not monitor.running:
    return
    
  info "Stopping activity monitoring"
  monitor.running = false
  
  # Cancel tasks if they exist
  if not monitor.keyboardTask.isNil and not monitor.keyboardTask.finished:
    monitor.keyboardTask.cancel()
  if not monitor.mouseTask.isNil and not monitor.mouseTask.finished:
    monitor.mouseTask.cancel()
  if not monitor.windowTask.isNil and not monitor.windowTask.finished:
    monitor.windowTask.cancel()
  if not monitor.statsTask.isNil and not monitor.statsTask.finished:
    monitor.statsTask.cancel()
  
  # Flush any remaining events
  await monitor.flushBuffers()
  
  info "Activity monitoring stopped"

proc isRunning*(monitor: ActivityMonitor): bool =
  """Check if monitoring is active."""
  result = monitor.running

proc getStats*(monitor: ActivityMonitor): Table[string, int] =
  """Get current statistics."""
  result = monitor.stats