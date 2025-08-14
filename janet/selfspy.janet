#!/usr/bin/env janet
# Selfspy - Modern Activity Monitoring in Janet
#
# Lisp-like embeddable scripting language with excellent C interop,
# perfect for configuration, extensibility, and system integration.

(import json)
(import sqlite3)
(import os)

# Core data structures using Janet's flexible data types
(def config-defaults
  {:data-dir ""
   :database-path ""
   :capture-text true
   :capture-mouse true
   :capture-windows true
   :update-interval-ms 100
   :encryption-enabled true
   :debug false
   :privacy-mode false
   :exclude-applications @[]
   :max-database-size-mb 500})

# Platform detection with functional approach
(defn get-os []
  (case (os/which)
    :windows "windows"
    :macos "darwin"
    :linux "linux"
    "unknown"))

# Configuration management with Janet's flexible syntax
(defn get-data-dir []
  (def home-dir (os/getenv "HOME" "/tmp"))
  (case (get-os)
    "windows" (string (os/getenv "APPDATA") "/selfspy")
    "darwin" (string home-dir "/Library/Application Support/selfspy")
    (string home-dir "/.local/share/selfspy")))

(defn default-config []
  (def data-dir (get-data-dir))
  (-> config-defaults
      (put :data-dir data-dir)
      (put :database-path (string data-dir "/selfspy.db"))))

# Command line argument parsing with pattern matching
(defn parse-start-options [args]
  {:no-text (has-value? args "--no-text")
   :no-mouse (has-value? args "--no-mouse")
   :debug (has-value? args "--debug")})

(defn parse-stats-options [args]
  (def days-idx (find-index |(= $ "--days") args))
  (def days (if days-idx
              (scan-number (get args (inc days-idx)) 7)
              7))
  {:days days
   :json (has-value? args "--json")})

(defn parse-export-options [args]
  (def format-idx (find-index |(= $ "--format") args))
  (def format (if format-idx
                (get args (inc format-idx))
                "json"))
  (def output-idx (find-index |(= $ "--output") args))
  (def output (if output-idx
                (get args (inc output-idx))
                nil))
  (def days-idx (find-index |(= $ "--days") args))
  (def days (if days-idx
              (scan-number (get args (inc days-idx)) 30)
              30))
  {:format format
   :output output
   :days days})

(defn parse-command [args]
  (if (empty? args)
    [:help nil]
    (case (first args)
      "start" [:start (parse-start-options (slice args 1))]
      "stop" [:stop nil]
      "stats" [:stats (parse-stats-options (slice args 1))]
      "check" [:check nil]
      "export" [:export (parse-export-options (slice args 1))]
      "version" [:version nil]
      "help" [:help nil]
      [:invalid (first args)])))

# Platform abstraction with Lisp macros
(defmacro when-os [os-name & body]
  ~(if (= (get-os) ,os-name)
     (do ,;body)))

(defn check-permissions []
  (def permissions @{:accessibility false
                     :input-monitoring false
                     :screen-recording false})
  
  (when-os "darwin"
    # macOS permission checking (placeholder)
    (put permissions :accessibility true)
    (put permissions :input-monitoring true))
  
  (when-os "linux"
    # Check for display server
    (def has-display (or (os/getenv "DISPLAY")
                         (os/getenv "WAYLAND_DISPLAY")))
    (put permissions :accessibility (truthy? has-display))
    (put permissions :input-monitoring (truthy? has-display))
    (put permissions :screen-recording (truthy? has-display)))
  
  (when-os "windows"
    (put permissions :accessibility true)
    (put permissions :input-monitoring true)
    (put permissions :screen-recording true))
  
  permissions)

(defn has-all-permissions? [permissions]
  (and (permissions :accessibility)
       (permissions :input-monitoring)))

(defn request-permissions []
  (when-os "darwin"
    (print "Please grant accessibility permissions in System Preferences")
    (print "Security & Privacy > Privacy > Accessibility"))
  true)

# System information gathering
(defn get-system-info []
  {:platform (get-os)
   :architecture (case (os/arch)
                   :x64 "x64"
                   :arm64 "arm64"
                   :x86 "x86"
                   "unknown")
   :janet-version janet/version
   :hostname (os/getenv "HOSTNAME" "localhost")
   :username (or (os/getenv "USER")
                 (os/getenv "USERNAME")
                 "unknown")})

# Activity monitoring with functional composition
(def monitor-state @{:running false
                     :events-processed 0
                     :config nil})

(defn start-monitoring [options]
  (print "🚀 Starting Selfspy monitoring (Janet implementation)")
  
  (def config (default-config))
  (put config :capture-text (and (config :capture-text)
                                  (not (options :no-text))))
  (put config :capture-mouse (and (config :capture-mouse)
                                   (not (options :no-mouse))))
  (put config :debug (or (config :debug)
                         (options :debug)))
  
  # Check permissions
  (def permissions (check-permissions))
  (unless (has-all-permissions? permissions)
    (print "❌ Insufficient permissions for monitoring")
    (print "Missing permissions:")
    (unless (permissions :accessibility)
      (print "   - Accessibility permission required"))
    (unless (permissions :input-monitoring)
      (print "   - Input monitoring permission required"))
    
    (print "\nAttempting to request permissions...")
    (unless (request-permissions)
      (error "Failed to obtain required permissions")))
  
  # Create data directory if needed
  (unless (os/stat (config :data-dir))
    (os/mkdir (config :data-dir)))
  
  # Initialize storage
  (def db (sqlite3/open (config :database-path)))
  (sqlite3/eval db `
    CREATE TABLE IF NOT EXISTS processes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      bundle_id TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`)
  
  (sqlite3/eval db `
    CREATE TABLE IF NOT EXISTS keys (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      process_id INTEGER,
      keys TEXT,
      count INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (process_id) REFERENCES processes (id)
    )`)
  
  (sqlite3/close db)
  
  # Update monitor state
  (put monitor-state :running true)
  (put monitor-state :config config)
  
  (print "✅ Selfspy monitoring started successfully")
  (print "📊 Press Ctrl+C to stop monitoring")
  
  # Monitoring loop with cooperative multitasking
  (defn monitoring-loop []
    (while (monitor-state :running)
      # Simulate event collection
      (++ (monitor-state :events-processed))
      
      # Sleep for update interval
      (os/sleep (/ (get-in monitor-state [:config :update-interval-ms]) 1000))))
  
  # Set up signal handling
  (defn signal-handler [sig]
    (print "\n🛑 Received shutdown signal, stopping gracefully...")
    (put monitor-state :running false))
  
  # Start monitoring (simplified)
  (monitoring-loop))

(defn stop-monitoring []
  (print "🛑 Stopping Selfspy monitoring...")
  (put monitor-state :running false)
  (print "✅ Stop signal sent"))

# Statistics with functional data processing
(defn get-stats [days]
  # Placeholder: Would query actual database
  {:keystrokes 12547
   :clicks 3821
   :window-changes 342
   :active-time-seconds 14760
   :top-apps [{:name "Code Editor" :percentage 45.2 :duration 6683 :events 5234}
              {:name "Web Browser" :percentage 32.1 :duration 4736 :events 3892}
              {:name "Terminal" :percentage 15.7 :duration 2318 :events 2156}]})

(defn show-stats [options]
  (def stats (get-stats (options :days)))
  
  (if (options :json)
    (print (json/encode stats))
    (print-formatted-stats stats (options :days))))

# Data export with polymorphic dispatch
(defmulti export-data (fn [format stats] format))

(defmethod export-data "json" [format stats]
  (json/encode stats))

(defmethod export-data "csv" [format stats]
  (string/format "metric,value\nkeystrokes,%d\nclicks,%d\nwindow_changes,%d\nactive_time_seconds,%d"
                 (stats :keystrokes)
                 (stats :clicks)
                 (stats :window-changes)
                 (stats :active-time-seconds)))

(defmethod export-data "sql" [format stats]
  (string/format `-- Selfspy Activity Export
CREATE TABLE stats (metric TEXT, value INTEGER);
INSERT INTO stats VALUES ('keystrokes', %d);
INSERT INTO stats VALUES ('clicks', %d);
INSERT INTO stats VALUES ('window_changes', %d);
INSERT INTO stats VALUES ('active_time_seconds', %d);`
                 (stats :keystrokes)
                 (stats :clicks)
                 (stats :window-changes)
                 (stats :active-time-seconds)))

(defn export-command [options]
  (printf "📤 Exporting %d days of data in %s format..." (options :days) (options :format))
  
  (def stats (get-stats (options :days)))
  
  (try
    (def data (export-data (options :format) stats))
    
    (if (options :output)
      (do
        (spit (options :output) data)
        (printf "✅ Data exported to %s" (options :output)))
      (print data))
    
    ([err] (eprintf "Export failed: %s" err))))

(defn check-system []
  (print "🔍 Checking Selfspy permissions...")
  (print "===================================")
  (print "")
  
  (def permissions (check-permissions))
  (if (has-all-permissions? permissions)
    (print "✅ All permissions granted")
    (do
      (print "❌ Missing permissions:")
      (unless (permissions :accessibility)
        (print "   - Accessibility permission required"))
      (unless (permissions :input-monitoring)
        (print "   - Input monitoring permission required"))))
  
  (print "")
  (print "📱 System Information:")
  (def sys-info (get-system-info))
  (printf "   Platform: %s" (sys-info :platform))
  (printf "   Architecture: %s" (sys-info :architecture))
  (printf "   Janet Version: %s" (sys-info :janet-version))
  (printf "   Hostname: %s" (sys-info :hostname))
  (printf "   Username: %s" (sys-info :username)))

(defn show-version []
  (print "Selfspy v1.0.0 (Janet implementation)")
  (print "Lisp-like embeddable scripting language")
  (print "")
  (print "Features:")
  (print "  • Lisp-like syntax with powerful macros")
  (print "  • Excellent C interop and FFI capabilities")
  (print "  • Embeddable and extensible")
  (print "  • Functional programming with immutable data")
  (print "  • Dynamic typing with optional type annotations")
  (print "  • Perfect for configuration and scripting"))

# Utility functions with functional programming
(defn format-number [num]
  (cond
    (>= num 1000000) (string/format "%.1fM" (/ num 1000000))
    (>= num 1000) (string/format "%.1fK" (/ num 1000))
    (string num)))

(defn format-duration [seconds]
  (def hours (div seconds 3600))
  (def minutes (div (mod seconds 3600) 60))
  
  (if (> hours 0)
    (string/format "%dh %dm" hours minutes)
    (string/format "%dm" minutes)))

(defn print-formatted-stats [stats days]
  (print "")
  (printf "📊 Selfspy Activity Statistics (Last %d days)" days)
  (print "==================================================")
  (print "")
  (printf "⌨️  Keystrokes: %s" (format-number (stats :keystrokes)))
  (printf "🖱️  Mouse clicks: %s" (format-number (stats :clicks)))
  (printf "🪟  Window changes: %s" (format-number (stats :window-changes)))
  (printf "⏰ Active time: %s" (format-duration (stats :active-time-seconds)))
  
  (unless (empty? (stats :top-apps))
    (print "📱 Most used applications:")
    (eachp [i app] (stats :top-apps)
      (printf "   %d. %s (%.1f%%)" (inc i) (app :name) (app :percentage))))
  
  (print ""))

(defn print-help []
  (print "Selfspy - Modern Activity Monitoring in Janet")
  (print "")
  (print "USAGE:")
  (print "    janet selfspy.janet [COMMAND] [OPTIONS]")
  (print "")
  (print "COMMANDS:")
  (print "    start                 Start activity monitoring")
  (print "    stop                  Stop running monitoring instance")
  (print "    stats                 Show activity statistics")
  (print "    check                 Check system permissions and setup")
  (print "    export                Export data to various formats")
  (print "    version               Show version information")
  (print "    help                  Show this help message")
  (print "")
  (print "START OPTIONS:")
  (print "    --no-text             Disable text capture for privacy")
  (print "    --no-mouse            Disable mouse monitoring")
  (print "    --debug               Enable debug logging")
  (print "")
  (print "STATS OPTIONS:")
  (print "    --days <N>            Number of days to analyze (default: 7)")
  (print "    --json                Output in JSON format")
  (print "")
  (print "EXPORT OPTIONS:")
  (print "    --format <FORMAT>     Export format: json, csv, sql (default: json)")
  (print "    --output <FILE>       Output file path")
  (print "    --days <N>            Number of days to export (default: 30)")
  (print "")
  (print "EXAMPLES:")
  (print "    janet selfspy.janet start")
  (print "    janet selfspy.janet start --no-text --debug")
  (print "    janet selfspy.janet stats --days 30 --json")
  (print "    janet selfspy.janet export --format csv --output activity.csv")
  (print "")
  (print "Janet Implementation Features:")
  (print "  • Lisp-like syntax with powerful macros")
  (print "  • Excellent C interop and embedding capabilities")
  (print "  • Functional programming with immutable data")
  (print "  • Dynamic typing with flexibility")
  (print "  • Perfect for configuration and extensibility")
  (print "  • Lightweight and fast execution"))

# Command execution with functional dispatch
(defn execute-command [command options]
  (try
    (case command
      :start (start-monitoring options)
      :stop (stop-monitoring)
      :stats (show-stats options)
      :check (check-system)
      :export (export-command options)
      :version (show-version)
      :help (print-help)
      :invalid (do
                 (eprintf "Error: Unknown command: %s" options)
                 (print "Use 'janet selfspy.janet help' for usage information")
                 (os/exit 1)))
    
    ([err]
     (eprintf "Error: %s" err)
     (os/exit 1))))

# Main entry point with Lisp-style programming
(defn main [& args]
  (def [command options] (parse-command args))
  (execute-command command options))

# Run if this is the main script
(if (= (dyn :current-file) (dyn :source))
  (main ;(slice (dyn :args) 1)))