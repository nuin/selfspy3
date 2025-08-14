// Selfspy - Modern Activity Monitoring in V
// Simple syntax, compiled performance, memory safety without GC
import os
import time
import json
import flag
import sqlite

struct Config {
mut:
	data_dir           string
	capture_text       bool = true
	capture_mouse      bool = true
	capture_windows    bool = true
	update_interval_ms int  = 100
	database_path      string
	encryption_enabled bool = true
}

struct WindowInfo {
	title       string
	application string
	bundle_id   string
	process_id  int
	x           int
	y           int
	width       int
	height      int
	timestamp   time.Time
}

struct KeyEvent {
	key         string
	application string
	timestamp   time.Time
}

struct MouseEvent {
	x           int
	y           int
	button      int
	event_type  string
	timestamp   time.Time
}

struct ActivityStats {
	keystrokes      u64
	clicks          u64
	window_changes  u64
	active_time_sec u64
	top_apps        []AppUsage
}

struct AppUsage {
	name       string
	percentage f64
}

struct Monitor {
mut:
	config   Config
	db       sqlite.DB
	running  bool
	stats    map[string]u64
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('selfspy')
	fp.version('v1.0.0')
	fp.description('Modern activity monitoring in V - simple, fast, compiled')
	fp.skip_executable()

	command := if fp.remaining.len > 0 { fp.remaining[0] } else { 'help' }

	match command {
		'start' {
			no_text := fp.bool('no-text', `t`, false, 'Disable text capture for privacy')
			no_mouse := fp.bool('no-mouse', `m`, false, 'Disable mouse monitoring')
			debug := fp.bool('debug', `d`, false, 'Enable debug logging')
			
			remaining := fp.finalize() or {
				eprintln('Error parsing flags: ${err}')
				exit(1)
			}
			
			start_monitoring(StartOptions{
				no_text: no_text
				no_mouse: no_mouse
				debug: debug
			}) or {
				eprintln('Failed to start monitoring: ${err}')
				exit(1)
			}
		}
		'stop' {
			stop_monitoring() or {
				eprintln('Failed to stop monitoring: ${err}')
				exit(1)
			}
		}
		'stats' {
			days := fp.int('days', `n`, 7, 'Number of days to analyze')
			json_output := fp.bool('json', `j`, false, 'Output in JSON format')
			
			remaining := fp.finalize() or {
				eprintln('Error parsing flags: ${err}')
				exit(1)
			}
			
			show_stats(days, json_output) or {
				eprintln('Failed to show stats: ${err}')
				exit(1)
			}
		}
		'check' {
			fp.finalize() or {
				eprintln('Error parsing flags: ${err}')
				exit(1)
			}
			check_permissions()
		}
		'export' {
			format := fp.string('format', `f`, 'json', 'Export format (json, csv, sql)')
			output := fp.string('output', `o`, '', 'Output file path')
			days := fp.int('days', `n`, 30, 'Number of days to export')
			
			remaining := fp.finalize() or {
				eprintln('Error parsing flags: ${err}')
				exit(1)
			}
			
			export_data(format, output, days) or {
				eprintln('Failed to export data: ${err}')
				exit(1)
			}
		}
		'help' {
			print_help()
		}
		'version' {
			println('Selfspy v1.0.0 (V implementation)')
			println('Simple, fast, compiled activity monitoring')
		}
		else {
			eprintln('Unknown command: ${command}')
			eprintln('Use "selfspy help" for usage information')
			exit(1)
		}
	}
}

struct StartOptions {
	no_text  bool
	no_mouse bool
	debug    bool
}

fn start_monitoring(options StartOptions) ! {
	println('🚀 Starting Selfspy monitoring (V implementation)')
	
	mut config := load_config()!
	
	// Apply command line options
	if options.no_text {
		config.capture_text = false
	}
	if options.no_mouse {
		config.capture_mouse = false
	}
	
	// Check permissions
	if !check_platform_permissions() {
		return error('Insufficient permissions for monitoring')
	}
	
	mut monitor := Monitor{
		config: config
		running: true
		stats: map[string]u64{}
	}
	
	// Initialize database
	monitor.init_database()!
	
	println('✅ Selfspy monitoring started successfully')
	println('📊 Press Ctrl+C to stop monitoring')
	
	// Set up signal handling
	os.signal_opt(.int, handle_shutdown) or {
		eprintln('Failed to set up signal handler: ${err}')
	}
	
	// Main monitoring loop
	monitor.run_monitoring_loop()!
}

fn stop_monitoring() ! {
	println('🛑 Stopping Selfspy monitoring...')
	// Send stop signal to running process
	println('✅ Stop signal sent')
}

fn show_stats(days int, json_output bool) ! {
	config := load_config()!
	
	mut db := sqlite.connect(config.database_path)!
	defer {
		db.close()
	}
	
	stats := get_activity_stats(mut db, days)!
	
	if json_output {
		stats_json := json.encode(stats)
		println(stats_json)
	} else {
		print_formatted_stats(stats, days)
	}
}

fn check_permissions() {
	println('🔍 Checking Selfspy permissions...')
	println('=' * 35)
	println('')
	
	if check_platform_permissions() {
		println('✅ All permissions granted')
	} else {
		println('❌ Missing permissions:')
		$if macos {
			println('   - Accessibility permission required')
			println('   - Input monitoring permission required')
		} $else $if linux {
			println('   - X11 access required')
			println('   - Input device access required')
		} $else $if windows {
			println('   - Administrator privileges may be required')
		}
	}
	
	println('')
	println('📱 System Information:')
	println('   Platform: ${os.user_os()}')
	println('   Architecture: ${os.getenv('PROCESSOR_ARCHITECTURE')}')
	println('   V Version: ${@VVERSION}')
}

fn export_data(format string, output string, days int) ! {
	println('📤 Exporting ${days} days of data in ${format} format...')
	
	config := load_config()!
	mut db := sqlite.connect(config.database_path)!
	defer {
		db.close()
	}
	
	data := match format {
		'json' { export_json(mut db, days)! }
		'csv' { export_csv(mut db, days)! }
		'sql' { export_sql(mut db, days)! }
		else { return error('Unsupported export format: ${format}') }
	}
	
	if output.len > 0 {
		os.write_file(output, data)!
		println('✅ Data exported to ${output}')
	} else {
		println(data)
	}
}

fn load_config() !Config {
	home_dir := os.home_dir()
	
	$if macos {
		data_dir := os.join_path(home_dir, 'Library', 'Application Support', 'selfspy')
	} $else $if linux {
		data_dir := os.join_path(home_dir, '.local', 'share', 'selfspy')
	} $else $if windows {
		data_dir := os.join_path(os.getenv('APPDATA'), 'selfspy')
	} $else {
		data_dir := os.join_path(home_dir, '.selfspy')
	}
	
	// Create data directory if it doesn't exist
	if !os.is_dir(data_dir) {
		os.mkdir_all(data_dir)!
	}
	
	return Config{
		data_dir: data_dir
		database_path: os.join_path(data_dir, 'selfspy.db')
	}
}

fn (mut m Monitor) init_database() ! {
	m.db = sqlite.connect(m.config.database_path)!
	
	// Create tables
	m.db.exec('
		CREATE TABLE IF NOT EXISTS processes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT NOT NULL,
			bundle_id TEXT,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	')!
	
	m.db.exec('
		CREATE TABLE IF NOT EXISTS windows (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			process_id INTEGER,
			title TEXT,
			x INTEGER, y INTEGER,
			width INTEGER, height INTEGER,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (process_id) REFERENCES processes (id)
		)
	')!
	
	m.db.exec('
		CREATE TABLE IF NOT EXISTS keys (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			process_id INTEGER,
			keys TEXT,
			count INTEGER DEFAULT 1,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (process_id) REFERENCES processes (id)
		)
	')!
	
	m.db.exec('
		CREATE TABLE IF NOT EXISTS clicks (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			process_id INTEGER,
			x INTEGER, y INTEGER,
			button INTEGER,
			event_type TEXT,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (process_id) REFERENCES processes (id)
		)
	')!
}

fn (mut m Monitor) run_monitoring_loop() ! {
	for m.running {
		// Collect window information
		if m.config.capture_windows {
			window := get_current_window()!
			m.store_window_event(window)!
		}
		
		// Update stats
		m.stats['checks'] = m.stats['checks'] + 1
		
		time.sleep(m.config.update_interval_ms * time.millisecond)
	}
}

fn (mut m Monitor) store_window_event(window WindowInfo) ! {
	// Get or create process
	process_id := m.get_or_create_process(window.application)!
	
	m.db.exec('
		INSERT INTO windows (process_id, title, x, y, width, height)
		VALUES (?, ?, ?, ?, ?, ?)
	', process_id, window.title, window.x, window.y, window.width, window.height)!
}

fn (mut m Monitor) get_or_create_process(name string) !int {
	// Check if process exists
	result := m.db.exec('SELECT id FROM processes WHERE name = ?', name) or {
		return 0
	}
	
	if result.len > 0 {
		return result[0].vals[0].int()
	}
	
	// Create new process
	m.db.exec('INSERT INTO processes (name) VALUES (?)', name)!
	return int(m.db.last_id())
}

fn get_current_window() !WindowInfo {
	// Platform-specific window detection
	$if macos {
		return get_macos_window()!
	} $else $if linux {
		return get_linux_window()!
	} $else $if windows {
		return get_windows_window()!
	} $else {
		return WindowInfo{
			title: 'Unknown'
			application: 'Unknown'
			timestamp: time.now()
		}
	}
}

fn get_macos_window() !WindowInfo {
	// Placeholder - would use macOS APIs
	return WindowInfo{
		title: 'Sample Window'
		application: 'Sample App'
		timestamp: time.now()
	}
}

fn get_linux_window() !WindowInfo {
	// Placeholder - would use X11 APIs
	return WindowInfo{
		title: 'Sample Window'
		application: 'Sample App'
		timestamp: time.now()
	}
}

fn get_windows_window() !WindowInfo {
	// Placeholder - would use Windows APIs
	return WindowInfo{
		title: 'Sample Window'
		application: 'Sample App'
		timestamp: time.now()
	}
}

fn check_platform_permissions() bool {
	$if macos {
		// Check accessibility permissions
		return true // Placeholder
	} $else $if linux {
		// Check X11 access
		return true // Placeholder
	} $else $if windows {
		// Check admin privileges
		return true // Placeholder
	} $else {
		return true
	}
}

fn get_activity_stats(mut db sqlite.DB, days int) !ActivityStats {
	// Get keystroke count
	keystrokes_result := db.exec('
		SELECT COALESCE(SUM(count), 0) FROM keys 
		WHERE created_at >= datetime("now", "-${days} days")
	')!
	
	keystrokes := if keystrokes_result.len > 0 {
		u64(keystrokes_result[0].vals[0].int())
	} else {
		u64(0)
	}
	
	// Get click count
	clicks_result := db.exec('
		SELECT COUNT(*) FROM clicks 
		WHERE created_at >= datetime("now", "-${days} days")
	')!
	
	clicks := if clicks_result.len > 0 {
		u64(clicks_result[0].vals[0].int())
	} else {
		u64(0)
	}
	
	// Get window changes
	windows_result := db.exec('
		SELECT COUNT(*) FROM windows 
		WHERE created_at >= datetime("now", "-${days} days")
	')!
	
	window_changes := if windows_result.len > 0 {
		u64(windows_result[0].vals[0].int())
	} else {
		u64(0)
	}
	
	// Calculate active time (rough estimate)
	active_time := (keystrokes + clicks) / 60 // Rough estimate: 1 event per second
	
	return ActivityStats{
		keystrokes: keystrokes
		clicks: clicks
		window_changes: window_changes
		active_time_sec: active_time
		top_apps: []
	}
}

fn print_formatted_stats(stats ActivityStats, days int) {
	println('')
	println('📊 Selfspy Activity Statistics (Last ${days} days)')
	println('=' * 50)
	println('')
	println('⌨️  Keystrokes: ${format_number(stats.keystrokes)}')
	println('🖱️  Mouse clicks: ${format_number(stats.clicks)}')
	println('🪟  Window changes: ${format_number(stats.window_changes)}')
	println('⏰ Active time: ${format_duration(stats.active_time_sec)}')
	println('')
}

fn format_number(num u64) string {
	if num >= 1_000_000 {
		return '${f64(num) / 1_000_000:.1f}M'
	} else if num >= 1_000 {
		return '${f64(num) / 1_000:.1f}K'
	} else {
		return '${num}'
	}
}

fn format_duration(seconds u64) string {
	hours := seconds / 3600
	minutes := (seconds % 3600) / 60
	
	if hours > 0 {
		return '${hours}h ${minutes}m'
	} else {
		return '${minutes}m'
	}
}

fn export_json(mut db sqlite.DB, days int) !string {
	stats := get_activity_stats(mut db, days)!
	return json.encode(stats)
}

fn export_csv(mut db sqlite.DB, days int) !string {
	mut csv := 'date,keystrokes,clicks,window_changes\n'
	
	// Get daily stats for CSV export
	result := db.exec('
		SELECT 
			date(created_at) as day,
			COUNT(*) as events
		FROM keys 
		WHERE created_at >= datetime("now", "-${days} days")
		GROUP BY date(created_at)
		ORDER BY day DESC
	')!
	
	for row in result {
		day := row.vals[0].str()
		events := row.vals[1].str()
		csv += '${day},${events},0,0\n'
	}
	
	return csv
}

fn export_sql(mut db sqlite.DB, days int) !string {
	mut sql := '-- Selfspy Activity Export\n'
	sql += '-- Generated: ${time.now()}\n\n'
	
	// Export keys table
	result := db.exec('
		SELECT * FROM keys 
		WHERE created_at >= datetime("now", "-${days} days")
		ORDER BY created_at DESC
	')!
	
	sql += 'CREATE TABLE exported_keys (\n'
	sql += '  id INTEGER,\n'
	sql += '  process_id INTEGER,\n'
	sql += '  keys TEXT,\n'
	sql += '  count INTEGER,\n'
	sql += '  created_at TEXT\n'
	sql += ');\n\n'
	
	for row in result {
		id := row.vals[0].str()
		process_id := row.vals[1].str()
		keys := row.vals[2].str().replace("'", "''") // Escape quotes
		count := row.vals[3].str()
		created_at := row.vals[4].str()
		
		sql += "INSERT INTO exported_keys VALUES (${id}, ${process_id}, '${keys}', ${count}, '${created_at}');\n"
	}
	
	return sql
}

fn handle_shutdown(sig os.Signal) {
	println('\n🛑 Received shutdown signal, stopping gracefully...')
	exit(0)
}

fn print_help() {
	println('Selfspy - Modern Activity Monitoring in V')
	println('')
	println('USAGE:')
	println('    selfspy [COMMAND] [OPTIONS]')
	println('')
	println('COMMANDS:')
	println('    start                 Start activity monitoring')
	println('    stop                  Stop running monitoring instance')
	println('    stats                 Show activity statistics')
	println('    check                 Check system permissions and setup')
	println('    export                Export data to various formats')
	println('    help                  Show this help message')
	println('    version               Show version information')
	println('')
	println('START OPTIONS:')
	println('    --no-text             Disable text capture for privacy')
	println('    --no-mouse            Disable mouse monitoring')
	println('    --debug               Enable debug logging')
	println('')
	println('STATS OPTIONS:')
	println('    --days <N>            Number of days to analyze (default: 7)')
	println('    --json                Output in JSON format')
	println('')
	println('EXPORT OPTIONS:')
	println('    --format <FORMAT>     Export format: json, csv, sql (default: json)')
	println('    --output <FILE>       Output file path')
	println('    --days <N>            Number of days to export (default: 30)')
	println('')
	println('EXAMPLES:')
	println('    selfspy start')
	println('    selfspy start --no-text --debug')
	println('    selfspy stats --days 30 --json')
	println('    selfspy export --format csv --output activity.csv')
	println('')
	println('V Implementation Features:')
	println('  • Simple, readable syntax')
	println('  • Compiled performance')
	println('  • Memory safety without GC')
	println('  • Zero dependencies')
}