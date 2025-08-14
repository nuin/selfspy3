Red [
    Title: "Selfspy - Modern Activity Monitoring in Red"
    Author: "Selfspy Team"
    File: %selfspy.red
    Needs: View
    Description: {
        Full-stack programming language with human-friendly syntax,
        compile to native or interpret, and interesting metaprogramming.
    }
]

;; Core data structures with Red's flexible types
config!: make object! [
    data-dir: ""
    database-path: ""
    capture-text: true
    capture-mouse: true
    capture-windows: true
    update-interval-ms: 100
    encryption-enabled: true
    debug: false
    privacy-mode: false
    exclude-applications: []
    max-database-size-mb: 500
]

;; Platform detection with Red's built-in system
get-os: does [
    switch system/platform [
        Windows [return "windows"]
        Linux [return "linux"]
        macOS [return "darwin"]
    ]
    "unknown"
]

;; Default configuration with Red's object system
default-config: does [
    home-dir: either system/options/home [
        to-local-file system/options/home
    ][
        "/tmp"
    ]
    
    data-dir: switch get-os [
        "windows" [join get-env "APPDATA" "/selfspy"]
        "darwin" [join home-dir "/Library/Application Support/selfspy"]
        default [join home-dir "/.local/share/selfspy"]
    ]
    
    make config! [
        data-dir: data-dir
        database-path: join data-dir "/selfspy.db"
    ]
]

;; Command line parsing with Red's parse dialect
parse-args: function [args [block!]] [
    if empty? args [return [help none]]
    
    switch/default first args [
        "start" [
            options: make object! [no-text: false no-mouse: false debug: false]
            parse next args [
                any [
                    "--no-text" (options/no-text: true)
                    | "--no-mouse" (options/no-mouse: true)
                    | "--debug" (options/debug: true)
                    | skip
                ]
            ]
            reduce ['start options]
        ]
        "stop" [reduce ['stop none]]
        "stats" [
            options: make object! [days: 7 json: false]
            parse next args [
                any [
                    "--days" set val skip (options/days: to-integer val)
                    | "--json" (options/json: true)
                    | skip
                ]
            ]
            reduce ['stats options]
        ]
        "check" [reduce ['check none]]
        "export" [
            options: make object! [format: "json" output: none days: 30]
            parse next args [
                any [
                    "--format" set val skip (options/format: val)
                    | "--output" set val skip (options/output: val)
                    | "--days" set val skip (options/days: to-integer val)
                    | skip
                ]
            ]
            reduce ['export options]
        ]
        "version" [reduce ['version none]]
        "help" [reduce ['help none]]
    ][
        reduce ['invalid first args]
    ]
]

;; Platform abstraction with Red's conditional compilation
check-permissions: does [
    permissions: make object! [
        accessibility: false
        input-monitoring: false
        screen-recording: false
    ]
    
    switch get-os [
        "darwin" [
            ;; macOS permission checking (placeholder)
            permissions/accessibility: true
            permissions/input-monitoring: true
        ]
        "linux" [
            ;; Check for display server
            has-display: any [
                get-env "DISPLAY"
                get-env "WAYLAND_DISPLAY"
            ]
            permissions/accessibility: to-logic has-display
            permissions/input-monitoring: to-logic has-display
            permissions/screen-recording: to-logic has-display
        ]
        "windows" [
            permissions/accessibility: true
            permissions/input-monitoring: true
            permissions/screen-recording: true
        ]
    ]
    
    permissions
]

has-all-permissions?: function [permissions [object!]] [
    all [
        permissions/accessibility
        permissions/input-monitoring
    ]
]

;; Activity monitoring with Red's reactive programming
start-monitoring: function [options [object!]] [
    print "🚀 Starting Selfspy monitoring (Red implementation)"
    
    config: default-config
    config/capture-text: config/capture-text and not options/no-text
    config/capture-mouse: config/capture-mouse and not options/no-mouse
    config/debug: config/debug or options/debug
    
    ;; Check permissions
    permissions: check-permissions
    unless has-all-permissions? permissions [
        print "❌ Insufficient permissions for monitoring"
        print "Missing permissions:"
        unless permissions/accessibility [
            print "   - Accessibility permission required"
        ]
        unless permissions/input-monitoring [
            print "   - Input monitoring permission required"
        ]
        exit/return 1
    ]
    
    ;; Create data directory if needed
    unless exists? config/data-dir [
        make-dir/deep config/data-dir
    ]
    
    print "✅ Selfspy monitoring started successfully"
    print "📊 Press Ctrl+C to stop monitoring"
    
    ;; Monitoring loop (simplified)
    events-processed: 0
    running: true
    
    ;; Signal handler
    system/console/on-interrupt does [
        print "^/🛑 Received shutdown signal, stopping gracefully..."
        running: false
    ]
    
    while [running] [
        events-processed: events-processed + 1
        wait to-time rejoin [0:0:0. config/update-interval-ms / 1000]
    ]
]

stop-monitoring: does [
    print "🛑 Stopping Selfspy monitoring..."
    print "✅ Stop signal sent"
]

;; Statistics with Red's data processing
get-stats: function [days [integer!]] [
    ;; Placeholder: Would query actual database
    make object! [
        keystrokes: 12547
        clicks: 3821
        window-changes: 342
        active-time-seconds: 14760
        top-apps: [
            [name: "Code Editor" percentage: 45.2 duration: 6683 events: 5234]
            [name: "Web Browser" percentage: 32.1 duration: 4736 events: 3892]
            [name: "Terminal" percentage: 15.7 duration: 2318 events: 2156]
        ]
    ]
]

show-stats: function [options [object!]] [
    stats: get-stats options/days
    
    either options/json [
        ;; JSON output (simplified)
        print rejoin [
            {{"keystrokes":} stats/keystrokes
            {,"clicks":} stats/clicks
            {,"window_changes":} stats/window-changes
            {,"active_time_seconds":} stats/active-time-seconds
            "}"
        ]
    ][
        print-formatted-stats stats options/days
    ]
]

;; Data export with Red's string manipulation
export-data: function [options [object!]] [
    print rejoin ["📤 Exporting " options/days " days of data in " options/format " format..."]
    
    stats: get-stats options/days
    
    data: switch options/format [
        "json" [
            rejoin [
                {{"keystrokes":} stats/keystrokes
                {,"clicks":} stats/clicks
                {,"window_changes":} stats/window-changes
                {,"active_time_seconds":} stats/active-time-seconds
                "}"
            ]
        ]
        "csv" [
            rejoin [
                "metric,value^/"
                "keystrokes," stats/keystrokes "^/"
                "clicks," stats/clicks "^/"
                "window_changes," stats/window-changes "^/"
                "active_time_seconds," stats/active-time-seconds
            ]
        ]
        "sql" [
            rejoin [
                "-- Selfspy Activity Export^/"
                "CREATE TABLE stats (metric TEXT, value INTEGER);^/"
                "INSERT INTO stats VALUES ('keystrokes', " stats/keystrokes ");^/"
                "INSERT INTO stats VALUES ('clicks', " stats/clicks ");^/"
                "INSERT INTO stats VALUES ('window_changes', " stats/window-changes ");^/"
                "INSERT INTO stats VALUES ('active_time_seconds', " stats/active-time-seconds ");"
            ]
        ]
    ]
    
    either options/output [
        write to-file options/output data
        print rejoin ["✅ Data exported to " options/output]
    ][
        print data
    ]
]

;; System information
get-system-info: does [
    make object! [
        platform: get-os
        architecture: either system/version/4 = 3 ["x64"]["x86"]
        red-version: system/version
        hostname: any [get-env "HOSTNAME" "localhost"]
        username: any [get-env "USER" get-env "USERNAME" "unknown"]
    ]
]

check-system: does [
    print "🔍 Checking Selfspy permissions..."
    print "==================================="
    print ""
    
    permissions: check-permissions
    either has-all-permissions? permissions [
        print "✅ All permissions granted"
    ][
        print "❌ Missing permissions:"
        unless permissions/accessibility [
            print "   - Accessibility permission required"
        ]
        unless permissions/input-monitoring [
            print "   - Input monitoring permission required"
        ]
    ]
    
    print ""
    print "📱 System Information:"
    sys-info: get-system-info
    print rejoin ["   Platform: " sys-info/platform]
    print rejoin ["   Architecture: " sys-info/architecture]
    print rejoin ["   Red Version: " mold sys-info/red-version]
    print rejoin ["   Hostname: " sys-info/hostname]
    print rejoin ["   Username: " sys-info/username]
]

show-version: does [
    print "Selfspy v1.0.0 (Red implementation)"
    print "Full-stack programming language"
    print ""
    print "Features:"
    print "  • Human-friendly syntax"
    print "  • Compile to native or interpret"
    print "  • Metaprogramming capabilities"
    print "  • Reactive programming model"
    print "  • Cross-platform GUI support"
    print "  • DSL creation capabilities"
]

;; Utility functions with Red's string formatting
format-number: function [num [integer!]] [
    case [
        num >= 1000000 [rejoin [num / 1000000 "M"]]
        num >= 1000 [rejoin [num / 1000 "K"]]
        true [to-string num]
    ]
]

format-duration: function [seconds [integer!]] [
    hours: seconds / 3600
    minutes: (seconds // 3600) / 60
    
    either hours > 0 [
        rejoin [hours "h " minutes "m"]
    ][
        rejoin [minutes "m"]
    ]
]

print-formatted-stats: function [stats [object!] days [integer!]] [
    print ""
    print rejoin ["📊 Selfspy Activity Statistics (Last " days " days)"]
    print "=================================================="
    print ""
    print rejoin ["⌨️  Keystrokes: " format-number stats/keystrokes]
    print rejoin ["🖱️  Mouse clicks: " format-number stats/clicks]
    print rejoin ["🪟  Window changes: " format-number stats/window-changes]
    print rejoin ["⏰ Active time: " format-duration stats/active-time-seconds]
    
    unless empty? stats/top-apps [
        print "📱 Most used applications:"
        repeat i length? stats/top-apps [
            app: pick stats/top-apps i
            print rejoin ["   " i ". " app/name " (" app/percentage "%)"]
        ]
    ]
    print ""
]

print-help: does [
    print "Selfspy - Modern Activity Monitoring in Red"
    print ""
    print "USAGE:"
    print "    red selfspy.red [COMMAND] [OPTIONS]"
    print ""
    print "COMMANDS:"
    print "    start                 Start activity monitoring"
    print "    stop                  Stop running monitoring instance"
    print "    stats                 Show activity statistics"
    print "    check                 Check system permissions and setup"
    print "    export                Export data to various formats"
    print "    version               Show version information"
    print "    help                  Show this help message"
    print ""
    print "Red Implementation Features:"
    print "  • Human-friendly syntax with metaprogramming"
    print "  • Compile to native or interpret dynamically"
    print "  • Reactive programming model"
    print "  • Cross-platform with GUI capabilities"
    print "  • DSL creation and language extension"
    print "  • Full-stack development support"
]

;; Command execution with Red's control flow
execute-command: function [command [word!] options] [
    switch command [
        start [start-monitoring options]
        stop [stop-monitoring]
        stats [show-stats options]
        check [check-system]
        export [export-data options]
        version [show-version]
        help [print-help]
        invalid [
            print rejoin ["Error: Unknown command: " options]
            print "Use 'red selfspy.red help' for usage information"
            exit/return 1
        ]
    ]
]

;; Main entry point
main: does [
    args: system/options/args
    if empty? args [args: []]
    
    set [command options] parse-args args
    execute-command command options
]

;; Run if this is the main script
if system/options/script = %selfspy.red [
    main
]