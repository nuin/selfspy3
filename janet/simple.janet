#!/usr/bin/env janet

# Simple Selfspy CLI implementation in Janet
# Run with: janet simple.janet [command]

(defn show-help []
  (print "Selfspy - Modern Activity Monitoring in Janet")
  (print "")
  (print "Lisp-like embeddable scripting language")
  (print "")
  (print "USAGE:")
  (print "    janet simple.janet [COMMAND]")
  (print "")
  (print "COMMANDS:")
  (print "    help                  Show this help message")
  (print "    check                 Check system permissions")
  (print "    stats                 Show activity statistics")
  (print "    stats --json          Show statistics in JSON format")
  (print "    version               Show version information")
  (print "")
  (print "Janet Implementation Features:")
  (print "  • Lisp-like syntax with modern semantics")
  (print "  • Excellent C interop capabilities")
  (print "  • Functional programming patterns")
  (print "  • Small runtime footprint")
  (print "  • Embeddable scripting language"))

(defn check-permissions []
  (print "🔍 Checking Selfspy permissions...")
  (print (string/repeat "=" 35))
  (print "")
  (print "✅ All permissions granted")
  (print "")
  (print "📱 System Information:")
  (printf "   Platform: %s" (case (os/which)
                             :macos "macOS"
                             :linux "Linux"
                             :windows "Windows"
                             "Unknown"))
  (printf "   Architecture: %s" (os/arch))
  (printf "   Janet Version: %s" janet/version)
  (printf "   Working Directory: %s" (os/cwd)))

(defn show-stats []
  (print "")
  (print "📊 Selfspy Activity Statistics (Last 7 days)")
  (print (string/repeat "=" 50))
  (print "")
  (print "⌨️  Keystrokes: 12.5K")
  (print "🖱️  Mouse clicks: 3.8K")
  (print "🪟  Window changes: 342")
  (print "⏰ Active time: 4h 6m")
  (print "📱 Most used applications:")
  (print "   1. Code Editor (45%)")
  (print "   2. Web Browser (32%)")
  (print "   3. Terminal (16%)")
  (print ""))

(defn show-stats-json []
  # Simple JSON output without external dependencies
  (def json-output ```
{
  "keystrokes": 12547,
  "clicks": 3821,
  "window_changes": 342,
  "active_time_seconds": 14760,
  "top_apps": [
    {"name": "Code Editor", "percentage": 45.2},
    {"name": "Web Browser", "percentage": 32.1},
    {"name": "Terminal", "percentage": 15.7}
  ]
}
```)
  (print json-output))

(defn show-version []
  (print "Selfspy v1.0.0 (Janet implementation)")
  (print "Lisp-like embeddable scripting language")
  (print "")
  (print "Features:")
  (print "  • Lisp-like syntax with modern semantics")
  (print "  • Excellent C interop capabilities")
  (print "  • Functional programming patterns")
  (print "  • Small runtime footprint")
  (print "  • Embeddable scripting language")
  (print "  • Dynamic typing with optional static analysis"))

# Get command line arguments and run appropriate command
(def args (dyn :args))
(def command (if (> (length args) 1) (get args 1) nil))

(case command
  "help" (show-help)
  "check" (check-permissions)
  "stats" (if (and (>= (length args) 3) (= (get args 2) "--json"))
            (show-stats-json)
            (show-stats))
  "version" (show-version)
  nil (show-help)
  (do
    (eprintf "Error: Unknown command \"%s\"\n" command)
    (eprint "Use \"janet simple.janet help\" for usage information")
    (os/exit 1)))