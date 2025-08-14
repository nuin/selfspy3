## Database storage for activity events
## Uses SQLite for efficient local storage

import std/[asyncdispatch, times, json, strutils, sequtils]
import chronicles, sqliter
import platform

type
  ActivityStorage* = ref object
    db: Database
    path: string
    
  ActivityStats* = object
    keystrokes*: int
    clicks*: int
    windowChanges*: int
    activeTime*: Duration
    topApps*: seq[AppUsage]
    
  AppUsage* = object
    name*: string
    percentage*: float

proc newActivityStorage*(dbPath: string): ActivityStorage =
  """Create new activity storage."""
  result = ActivityStorage(path: dbPath)

proc initialize*(storage: ActivityStorage) {.async.} =
  """Initialize database with required tables."""
  info "Initializing database", path=storage.path
  
  storage.db = open(storage.path)
  
  # Create tables if they don't exist
  storage.db.exec("""
    CREATE TABLE IF NOT EXISTS processes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      bundle_id TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  """)
  
  storage.db.exec("""
    CREATE TABLE IF NOT EXISTS windows (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      process_id INTEGER,
      title TEXT,
      x INTEGER, y INTEGER,
      width INTEGER, height INTEGER,
      screen INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (process_id) REFERENCES processes (id)
    )
  """)
  
  storage.db.exec("""
    CREATE TABLE IF NOT EXISTS keys (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      process_id INTEGER,
      keys TEXT,  -- Encrypted keystroke data
      count INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (process_id) REFERENCES processes (id)
    )
  """)
  
  storage.db.exec("""
    CREATE TABLE IF NOT EXISTS clicks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      process_id INTEGER,
      x INTEGER, y INTEGER,
      button INTEGER,
      event_type TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (process_id) REFERENCES processes (id)
    )
  """)
  
  storage.db.exec("""
    CREATE TABLE IF NOT EXISTS terminal_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shell_type TEXT,
      working_directory TEXT,
      git_branch TEXT,
      project_type TEXT,
      started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      ended_at DATETIME
    )
  """)
  
  storage.db.exec("""
    CREATE TABLE IF NOT EXISTS terminal_commands (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER,
      command TEXT,
      exit_code INTEGER,
      duration_ms INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (session_id) REFERENCES terminal_sessions (id)
    )
  """)
  
  # Create indexes for performance
  storage.db.exec("CREATE INDEX IF NOT EXISTS idx_keys_created_at ON keys (created_at)")
  storage.db.exec("CREATE INDEX IF NOT EXISTS idx_clicks_created_at ON clicks (created_at)")
  storage.db.exec("CREATE INDEX IF NOT EXISTS idx_windows_created_at ON windows (created_at)")
  
  info "Database initialized successfully"

proc getOrCreateProcess(storage: ActivityStorage, name: string, bundleId: string = ""): int =
  """Get existing process ID or create new one."""
  let existing = storage.db.value("SELECT id FROM processes WHERE name = ? AND bundle_id = ?", 
                                  name, bundleId)
  
  if existing.kind != sqliteNull:
    return existing.intVal.int
  
  storage.db.exec("INSERT INTO processes (name, bundle_id) VALUES (?, ?)", name, bundleId)
  return storage.db.lastInsertRowId.int

proc storeKeyEvents*(storage: ActivityStorage, events: seq[KeyEvent]) {.async.} =
  """Store keyboard events to database."""
  if events.len == 0:
    return
    
  # Group events by application for efficiency
  var grouped: seq[(string, seq[string])]
  var currentApp = ""
  var currentKeys: seq[string] = @[]
  
  for event in events:
    if event.application != currentApp:
      if currentKeys.len > 0:
        grouped.add((currentApp, currentKeys))
      currentApp = event.application
      currentKeys = @[event.key]
    else:
      currentKeys.add(event.key)
  
  if currentKeys.len > 0:
    grouped.add((currentApp, currentKeys))
  
  # Store grouped events
  for (app, keys) in grouped:
    let processId = storage.getOrCreateProcess(app)
    let keysText = keys.join("")
    
    storage.db.exec("""
      INSERT INTO keys (process_id, keys, count, created_at) 
      VALUES (?, ?, ?, datetime('now'))
    """, processId, keysText, keys.len)
  
  debug "Stored key events", count=events.len, groups=grouped.len

proc storeMouseEvents*(storage: ActivityStorage, events: seq[MouseEvent]) {.async.} =
  """Store mouse events to database."""
  if events.len == 0:
    return
    
  for event in events:
    # For now, store without application context
    # Could be enhanced to link to current window
    storage.db.exec("""
      INSERT INTO clicks (x, y, button, event_type, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
    """, event.x, event.y, event.button, event.eventType)
  
  debug "Stored mouse events", count=events.len

proc storeWindowEvent*(storage: ActivityStorage, window: WindowInfo) {.async.} =
  """Store window change event."""
  let processId = storage.getOrCreateProcess(window.application, window.bundleId)
  
  storage.db.exec("""
    INSERT INTO windows (process_id, title, x, y, width, height, screen, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
  """, processId, window.title, window.x, window.y, 
      window.width, window.height, window.screen)
  
  debug "Stored window event", app=window.application, title=window.title

proc getStats*(storage: ActivityStorage, days: int): Future[ActivityStats] {.async.} =
  """Get activity statistics for the specified number of days."""
  let startDate = now() - initDuration(days = days)
  let startDateStr = startDate.format("yyyy-MM-dd HH:mm:ss")
  
  # Get keystroke count
  let keystrokes = storage.db.value("""
    SELECT COALESCE(SUM(count), 0) FROM keys 
    WHERE created_at >= ?
  """, startDateStr).intVal.int
  
  # Get click count  
  let clicks = storage.db.value("""
    SELECT COUNT(*) FROM clicks 
    WHERE created_at >= ?
  """, startDateStr).intVal.int
  
  # Get window changes
  let windowChanges = storage.db.value("""
    SELECT COUNT(*) FROM windows 
    WHERE created_at >= ?
  """, startDateStr).intVal.int
  
  # Calculate active time (rough estimate based on events)
  let totalEvents = keystrokes + clicks
  let activeMinutes = totalEvents div 60  # Rough estimate: 1 event per second = active
  let activeTime = initDuration(minutes = activeMinutes)
  
  # Get top applications
  var topApps: seq[AppUsage] = @[]
  for row in storage.db.iterate("""
    SELECT p.name, COUNT(*) as usage_count
    FROM processes p
    JOIN keys k ON p.id = k.process_id
    WHERE k.created_at >= ?
    GROUP BY p.name
    ORDER BY usage_count DESC
    LIMIT 5
  """, startDateStr):
    let name = row[0].stringVal
    let count = row[1].intVal.int
    let percentage = if keystrokes > 0: (count.float / keystrokes.float) * 100.0 else: 0.0
    
    topApps.add(AppUsage(name: name, percentage: percentage))
  
  result = ActivityStats(
    keystrokes: keystrokes,
    clicks: clicks,
    windowChanges: windowChanges,
    activeTime: activeTime,
    topApps: topApps
  )

proc close*(storage: ActivityStorage) {.async.} =
  """Close database connection."""
  if not storage.db.isNil:
    storage.db.close()
    info "Database connection closed"