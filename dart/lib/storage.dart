/// Storage layer for Selfspy Dart implementation
///
/// Modern async database operations with strong typing and null safety

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'types.dart';

/// Activity storage with async operations and connection pooling
class ActivityStorage {
  final String databasePath;
  Database? _database;
  bool _isInitialized = false;

  ActivityStorage(this.databasePath);

  /// Initialize database with async file operations
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Ensure directory exists
    final dbDir = path.dirname(databasePath);
    await Directory(dbDir).create(recursive: true);

    // Open database
    _database = sqlite3.open(databasePath);

    // Configure SQLite for performance and reliability
    _database!.execute('PRAGMA journal_mode = WAL');
    _database!.execute('PRAGMA synchronous = NORMAL');
    _database!.execute('PRAGMA cache_size = 10000');
    _database!.execute('PRAGMA temp_store = MEMORY');
    _database!.execute('PRAGMA foreign_keys = ON');

    // Create tables
    await _createTables();
    _isInitialized = true;
  }

  /// Close database connection
  Future<void> close() async {
    _database?.dispose();
    _database = null;
    _isInitialized = false;
  }

  /// Insert session start with async operations
  Future<int> insertSessionStart() async {
    _ensureInitialized();

    final stmt = _database!.prepare('''
      INSERT INTO sessions (start_time, end_time)
      VALUES (?, NULL)
    ''');

    try {
      stmt.execute([DateTime.now().millisecondsSinceEpoch]);
      return _database!.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  /// Update session end time
  Future<void> updateSessionEnd(int sessionId) async {
    _ensureInitialized();

    final stmt = _database!.prepare('''
      UPDATE sessions
      SET end_time = ?
      WHERE id = ?
    ''');

    try {
      stmt.execute([DateTime.now().millisecondsSinceEpoch, sessionId]);
    } finally {
      stmt.dispose();
    }
  }

  /// Insert keystroke with encryption support
  Future<void> insertKeystroke(KeystrokeEvent event) async {
    _ensureInitialized();

    final stmt = _database!.prepare('''
      INSERT INTO keystrokes (timestamp, key_data, modifiers, window_id, encrypted)
      VALUES (?, ?, ?, ?, ?)
    ''');

    try {
      stmt.execute([
        event.timestamp.millisecondsSinceEpoch,
        event.key,
        event.modifiers.join(','),
        event.windowId,
        event.encrypted ? 1 : 0,
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Insert mouse event with coordinate tracking
  Future<void> insertMouseEvent(MouseEvent event) async {
    _ensureInitialized();

    final stmt = _database!.prepare('''
      INSERT INTO mouse_events (timestamp, event_type, x, y, button, window_id)
      VALUES (?, ?, ?, ?, ?, ?)
    ''');

    try {
      stmt.execute([
        event.timestamp.millisecondsSinceEpoch,
        event.type.name,
        event.x,
        event.y,
        event.button,
        event.windowId,
      ]);
    } finally {
      stmt.dispose();
    }
  }

  /// Insert window event with deduplication
  Future<int> insertWindowEvent(WindowEvent event) async {
    _ensureInitialized();

    // Check if window already exists
    final existingStmt = _database!.prepare('''
      SELECT id FROM windows
      WHERE title = ? AND app_name = ? AND pid = ?
    ''');

    try {
      final result = existingStmt.select([event.title, event.appName, event.pid]);

      if (result.isNotEmpty) {
        final windowId = result.first['id'] as int;

        // Update last seen timestamp
        final updateStmt = _database!.prepare('''
          UPDATE windows
          SET last_seen = ?
          WHERE id = ?
        ''');

        try {
          updateStmt.execute([event.timestamp.millisecondsSinceEpoch, windowId]);
          return windowId;
        } finally {
          updateStmt.dispose();
        }
      } else {
        // Insert new window
        final insertStmt = _database!.prepare('''
          INSERT INTO windows (title, app_name, bundle_id, pid, first_seen, last_seen)
          VALUES (?, ?, ?, ?, ?, ?)
        ''');

        try {
          insertStmt.execute([
            event.title,
            event.appName,
            event.bundleId,
            event.pid,
            event.timestamp.millisecondsSinceEpoch,
            event.timestamp.millisecondsSinceEpoch,
          ]);
          return _database!.lastInsertRowId;
        } finally {
          insertStmt.dispose();
        }
      }
    } finally {
      existingStmt.dispose();
    }
  }

  /// Get activity statistics with computed metrics
  Future<ActivityStats> getStats(int days) async {
    _ensureInitialized();

    final since = DateTime.now().subtract(Duration(days: days));
    final sinceMs = since.millisecondsSinceEpoch;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Count keystrokes
    final keystrokeStmt = _database!.prepare('''
      SELECT COUNT(*) as count
      FROM keystrokes
      WHERE timestamp > ?
    ''');

    final keystrokes = keystrokeStmt.select([sinceMs]).first['count'] as int;
    keystrokeStmt.dispose();

    // Count mouse clicks
    final clickStmt = _database!.prepare('''
      SELECT COUNT(*) as count
      FROM mouse_events
      WHERE timestamp > ? AND event_type = 'click'
    ''');

    final clicks = clickStmt.select([sinceMs]).first['count'] as int;
    clickStmt.dispose();

    // Count window changes
    final windowStmt = _database!.prepare('''
      SELECT COUNT(*) as count
      FROM windows
      WHERE first_seen > ?
    ''');

    final windowChanges = windowStmt.select([sinceMs]).first['count'] as int;
    windowStmt.dispose();

    // Calculate active time from sessions
    final sessionStmt = _database!.prepare('''
      SELECT COALESCE(SUM(COALESCE(end_time, ?) - start_time), 0) as total
      FROM sessions
      WHERE start_time > ?
    ''');

    final activeTimeMs = sessionStmt.select([nowMs, sinceMs]).first['total'] as int;
    final activeTimeSeconds = activeTimeMs ~/ 1000;
    sessionStmt.dispose();

    // Get top applications
    final topApps = await _getTopApplications(days);

    return ActivityStats(
      keystrokes: keystrokes,
      clicks: clicks,
      windowChanges: windowChanges,
      activeTimeSeconds: activeTimeSeconds,
      topApps: topApps,
      periodStart: since,
      periodEnd: DateTime.now(),
    );
  }

  /// Get top applications with usage statistics
  Future<List<AppUsage>> _getTopApplications(int days, {int limit = 10}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final sinceMs = since.millisecondsSinceEpoch;

    final stmt = _database!.prepare('''
      SELECT
        app_name,
        COUNT(*) as usage_count,
        SUM(last_seen - first_seen) as total_time,
        bundle_id
      FROM windows
      WHERE first_seen > ?
      GROUP BY app_name
      ORDER BY usage_count DESC
      LIMIT ?
    ''');

    final results = stmt.select([sinceMs, limit]);
    final apps = <AppUsage>[];

    // Calculate total usage for percentage computation
    final totalUsage = results.fold<int>(0, (sum, row) => sum + (row['usage_count'] as int));

    for (final row in results) {
      final usageCount = row['usage_count'] as int;
      final totalTime = (row['total_time'] as int) ~/ 1000; // Convert to seconds
      final percentage = totalUsage > 0 ? (usageCount / totalUsage) * 100 : 0.0;

      apps.add(AppUsage(
        name: row['app_name'] as String,
        usageCount: usageCount,
        totalTimeSeconds: totalTime,
        percentage: percentage,
        bundleId: row['bundle_id'] as String?,
      ));
    }

    stmt.dispose();
    return apps;
  }

  /// Export data as JSON with comprehensive serialization
  Future<String> exportJson(int days) async {
    _ensureInitialized();

    final since = DateTime.now().subtract(Duration(days: days));
    final sinceMs = since.millisecondsSinceEpoch;

    final data = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'days': days,
      'stats': (await getStats(days)).toJson(),
      'keystrokes': await _getKeystrokeData(sinceMs),
      'mouse_events': await _getMouseData(sinceMs),
      'windows': await _getWindowData(sinceMs),
      'sessions': await _getSessionData(sinceMs),
    };

    return jsonEncode(data);
  }

  /// Export data as CSV format
  Future<String> exportCsv(int days) async {
    _ensureInitialized();

    final since = DateTime.now().subtract(Duration(days: days));
    final sinceMs = since.millisecondsSinceEpoch;
    final buffer = StringBuffer();

    // Export keystrokes
    buffer.writeln('# Keystrokes');
    buffer.writeln('timestamp,key_data,modifiers,window_id,encrypted');

    final keystrokeStmt = _database!.prepare('''
      SELECT timestamp, key_data, modifiers, window_id, encrypted
      FROM keystrokes
      WHERE timestamp > ?
      ORDER BY timestamp
    ''');

    for (final row in keystrokeStmt.select([sinceMs])) {
      buffer.writeln('${row['timestamp']},"${row['key_data']}","${row['modifiers']}",${row['window_id']},${row['encrypted']}');
    }
    keystrokeStmt.dispose();

    // Export mouse events
    buffer.writeln('\n# Mouse Events');
    buffer.writeln('timestamp,event_type,x,y,button,window_id');

    final mouseStmt = _database!.prepare('''
      SELECT timestamp, event_type, x, y, button, window_id
      FROM mouse_events
      WHERE timestamp > ?
      ORDER BY timestamp
    ''');

    for (final row in mouseStmt.select([sinceMs])) {
      buffer.writeln('${row['timestamp']},${row['event_type']},${row['x']},${row['y']},${row['button']},${row['window_id']}');
    }
    mouseStmt.dispose();

    return buffer.toString();
  }

  /// Export data as SQL statements
  Future<String> exportSql(int days) async {
    _ensureInitialized();

    final since = DateTime.now().subtract(Duration(days: days));
    final sinceMs = since.millisecondsSinceEpoch;
    final buffer = StringBuffer();

    buffer.writeln('-- Selfspy Export SQL (Dart Implementation)');
    buffer.writeln('-- Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('-- Days: $days');
    buffer.writeln();

    // Include table definitions
    buffer.writeln(_getTableDefinitions());
    buffer.writeln();

    // Export table data
    await _exportTableData(buffer, 'sessions', sinceMs);
    await _exportTableData(buffer, 'windows', sinceMs);
    await _exportTableData(buffer, 'keystrokes', sinceMs);
    await _exportTableData(buffer, 'mouse_events', sinceMs);

    return buffer.toString();
  }

  /// Cleanup old data beyond retention period
  Future<void> cleanupOldData(int days) async {
    _ensureInitialized();

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffMs = cutoff.millisecondsSinceEpoch;

    // Delete old keystrokes
    final keystrokeStmt = _database!.prepare('DELETE FROM keystrokes WHERE timestamp < ?');
    keystrokeStmt.execute([cutoffMs]);
    final deletedKeystrokes = _database!.getUpdatedRows();
    keystrokeStmt.dispose();

    // Delete old mouse events
    final mouseStmt = _database!.prepare('DELETE FROM mouse_events WHERE timestamp < ?');
    mouseStmt.execute([cutoffMs]);
    final deletedMouse = _database!.getUpdatedRows();
    mouseStmt.dispose();

    // Delete old windows
    final windowStmt = _database!.prepare('DELETE FROM windows WHERE last_seen < ?');
    windowStmt.execute([cutoffMs]);
    final deletedWindows = _database!.getUpdatedRows();
    windowStmt.dispose();

    // Delete old sessions
    final sessionStmt = _database!.prepare('DELETE FROM sessions WHERE start_time < ?');
    sessionStmt.execute([cutoffMs]);
    final deletedSessions = _database!.getUpdatedRows();
    sessionStmt.dispose();

    print('Cleaned up old data: $deletedKeystrokes keystrokes, $deletedMouse mouse events, $deletedWindows windows, $deletedSessions sessions');

    // Vacuum database to reclaim space
    _database!.execute('VACUUM');
  }

  /// Create database tables with proper indexing
  Future<void> _createTables() async {
    // Sessions table
    _database!.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER
      )
    ''');

    // Windows table
    _database!.execute('''
      CREATE TABLE IF NOT EXISTS windows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        app_name TEXT NOT NULL,
        bundle_id TEXT,
        pid INTEGER NOT NULL,
        first_seen INTEGER NOT NULL,
        last_seen INTEGER NOT NULL
      )
    ''');

    // Keystrokes table
    _database!.execute('''
      CREATE TABLE IF NOT EXISTS keystrokes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        key_data TEXT NOT NULL,
        modifiers TEXT,
        window_id INTEGER,
        encrypted INTEGER DEFAULT 0,
        FOREIGN KEY (window_id) REFERENCES windows (id)
      )
    ''');

    // Mouse events table
    _database!.execute('''
      CREATE TABLE IF NOT EXISTS mouse_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        button TEXT,
        window_id INTEGER,
        FOREIGN KEY (window_id) REFERENCES windows (id)
      )
    ''');

    // Create performance indexes
    _createIndexes();
  }

  /// Create indexes for query performance
  void _createIndexes() {
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_keystrokes_timestamp ON keystrokes (timestamp)');
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_keystrokes_window_id ON keystrokes (window_id)');
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_mouse_events_timestamp ON mouse_events (timestamp)');
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_mouse_events_window_id ON mouse_events (window_id)');
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_windows_app_name ON windows (app_name)');
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_windows_first_seen ON windows (first_seen)');
    _database!.execute('CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON sessions (start_time)');
  }

  /// Get keystroke data for export
  Future<List<Map<String, dynamic>>> _getKeystrokeData(int sinceMs) async {
    final stmt = _database!.prepare('''
      SELECT timestamp, key_data, modifiers, window_id, encrypted
      FROM keystrokes
      WHERE timestamp > ?
      ORDER BY timestamp
    ''');

    final data = <Map<String, dynamic>>[];
    for (final row in stmt.select([sinceMs])) {
      data.add({
        'timestamp': row['timestamp'],
        'key_data': row['key_data'],
        'modifiers': row['modifiers'],
        'window_id': row['window_id'],
        'encrypted': row['encrypted'] == 1,
      });
    }

    stmt.dispose();
    return data;
  }

  /// Get mouse data for export
  Future<List<Map<String, dynamic>>> _getMouseData(int sinceMs) async {
    final stmt = _database!.prepare('''
      SELECT timestamp, event_type, x, y, button, window_id
      FROM mouse_events
      WHERE timestamp > ?
      ORDER BY timestamp
    ''');

    final data = <Map<String, dynamic>>[];
    for (final row in stmt.select([sinceMs])) {
      data.add({
        'timestamp': row['timestamp'],
        'event_type': row['event_type'],
        'x': row['x'],
        'y': row['y'],
        'button': row['button'],
        'window_id': row['window_id'],
      });
    }

    stmt.dispose();
    return data;
  }

  /// Get window data for export
  Future<List<Map<String, dynamic>>> _getWindowData(int sinceMs) async {
    final stmt = _database!.prepare('''
      SELECT id, title, app_name, bundle_id, pid, first_seen, last_seen
      FROM windows
      WHERE first_seen > ?
      ORDER BY first_seen
    ''');

    final data = <Map<String, dynamic>>[];
    for (final row in stmt.select([sinceMs])) {
      data.add({
        'id': row['id'],
        'title': row['title'],
        'app_name': row['app_name'],
        'bundle_id': row['bundle_id'],
        'pid': row['pid'],
        'first_seen': row['first_seen'],
        'last_seen': row['last_seen'],
      });
    }

    stmt.dispose();
    return data;
  }

  /// Get session data for export
  Future<List<Map<String, dynamic>>> _getSessionData(int sinceMs) async {
    final stmt = _database!.prepare('''
      SELECT id, start_time, end_time
      FROM sessions
      WHERE start_time > ?
      ORDER BY start_time
    ''');

    final data = <Map<String, dynamic>>[];
    for (final row in stmt.select([sinceMs])) {
      data.add({
        'id': row['id'],
        'start_time': row['start_time'],
        'end_time': row['end_time'],
      });
    }

    stmt.dispose();
    return data;
  }

  /// Get table definitions for SQL export
  String _getTableDefinitions() {
    final buffer = StringBuffer();

    final stmt = _database!.prepare('''
      SELECT sql FROM sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
    ''');

    for (final row in stmt.select([])) {
      buffer.writeln('${row['sql']};');
    }

    stmt.dispose();
    return buffer.toString();
  }

  /// Export table data as SQL inserts
  Future<void> _exportTableData(StringBuffer buffer, String tableName, int sinceMs) async {
    buffer.writeln('-- $tableName data');

    final condition = tableName == 'windows'
        ? 'WHERE first_seen > $sinceMs'
        : tableName == 'sessions'
            ? 'WHERE start_time > $sinceMs'
            : 'WHERE timestamp > $sinceMs';

    final stmt = _database!.prepare('SELECT * FROM $tableName $condition');

    for (final row in stmt.select([])) {
      final values = <String>[];
      for (final key in row.keys) {
        final value = row[key];
        if (value == null) {
          values.add('NULL');
        } else if (value is String) {
          values.add("'${value.replaceAll("'", "''")}'");
        } else {
          values.add(value.toString());
        }
      }
      buffer.writeln('INSERT INTO $tableName VALUES (${values.join(', ')});');
    }

    stmt.dispose();
    buffer.writeln();
  }

  /// Ensure database is initialized
  void _ensureInitialized() {
    if (!_isInitialized || _database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
  }
}