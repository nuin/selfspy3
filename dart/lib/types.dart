/// Core type definitions for Selfspy Dart implementation
///
/// Leverages Dart's strong typing and null safety for robust data modeling

import 'dart:convert';

/// System permission status with null safety
class PermissionStatus {
  final bool accessibility;
  final bool inputMonitoring;
  final bool screenRecording;

  const PermissionStatus({
    required this.accessibility,
    required this.inputMonitoring,
    required this.screenRecording,
  });

  bool get hasAllPermissions => accessibility && inputMonitoring;

  Map<String, dynamic> toJson() => {
    'accessibility': accessibility,
    'inputMonitoring': inputMonitoring,
    'screenRecording': screenRecording,
    'hasAllPermissions': hasAllPermissions,
  };
}

/// System information with immutable design
class SystemInfo {
  final String platform;
  final String architecture;
  final String version;
  final Map<String, String> environment;

  const SystemInfo({
    required this.platform,
    required this.architecture,
    required this.version,
    required this.environment,
  });

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'architecture': architecture,
    'version': version,
    'environment': environment,
  };
}

/// Keystroke event with privacy-aware design
class KeystrokeEvent {
  final DateTime timestamp;
  final String key;
  final List<String> modifiers;
  final int? windowId;
  final bool encrypted;

  const KeystrokeEvent({
    required this.timestamp,
    required this.key,
    required this.modifiers,
    this.windowId,
    this.encrypted = false,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'key': key,
    'modifiers': modifiers,
    'windowId': windowId,
    'encrypted': encrypted,
  };

  factory KeystrokeEvent.fromJson(Map<String, dynamic> json) {
    return KeystrokeEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      key: json['key'] as String,
      modifiers: List<String>.from(json['modifiers'] as List),
      windowId: json['windowId'] as int?,
      encrypted: json['encrypted'] as bool? ?? false,
    );
  }
}

/// Mouse event with coordinate tracking
class MouseEvent {
  final DateTime timestamp;
  final MouseEventType type;
  final int x;
  final int y;
  final String? button;
  final int? windowId;

  const MouseEvent({
    required this.timestamp,
    required this.type,
    required this.x,
    required this.y,
    this.button,
    this.windowId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'type': type.name,
    'x': x,
    'y': y,
    'button': button,
    'windowId': windowId,
  };

  factory MouseEvent.fromJson(Map<String, dynamic> json) {
    return MouseEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      type: MouseEventType.values.byName(json['type'] as String),
      x: json['x'] as int,
      y: json['y'] as int,
      button: json['button'] as String?,
      windowId: json['windowId'] as int?,
    );
  }
}

/// Mouse event types with enumeration
enum MouseEventType {
  click,
  move,
  scroll,
  drag;

  @override
  String toString() => name;
}

/// Window event with application context
class WindowEvent {
  final DateTime timestamp;
  final String title;
  final String appName;
  final String? bundleId;
  final int pid;
  final WindowGeometry? geometry;

  const WindowEvent({
    required this.timestamp,
    required this.title,
    required this.appName,
    this.bundleId,
    required this.pid,
    this.geometry,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'title': title,
    'appName': appName,
    'bundleId': bundleId,
    'pid': pid,
    'geometry': geometry?.toJson(),
  };

  factory WindowEvent.fromJson(Map<String, dynamic> json) {
    return WindowEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      title: json['title'] as String,
      appName: json['appName'] as String,
      bundleId: json['bundleId'] as String?,
      pid: json['pid'] as int,
      geometry: json['geometry'] != null
          ? WindowGeometry.fromJson(json['geometry'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Window geometry information
class WindowGeometry {
  final int x;
  final int y;
  final int width;
  final int height;

  const WindowGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory WindowGeometry.fromJson(Map<String, dynamic> json) {
    return WindowGeometry(
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}

/// Activity statistics with computed properties
class ActivityStats {
  final int keystrokes;
  final int clicks;
  final int windowChanges;
  final int activeTimeSeconds;
  final List<AppUsage> topApps;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ActivityStats({
    required this.keystrokes,
    required this.clicks,
    required this.windowChanges,
    required this.activeTimeSeconds,
    required this.topApps,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Calculate total events
  int get totalEvents => keystrokes + clicks + windowChanges;

  /// Calculate productivity score (0-10)
  double get productivityScore {
    final dailyKeystrokes = keystrokes / periodDays;
    final dailyActiveHours = (activeTimeSeconds / periodDays) / 3600.0;

    final keystrokeScore = (dailyKeystrokes / 2000.0).clamp(0.0, 1.0) * 4;
    final timeScore = (dailyActiveHours / 8.0).clamp(0.0, 1.0) * 6;

    return (keystrokeScore + timeScore).clamp(0.0, 10.0);
  }

  /// Get period duration in days
  double get periodDays {
    final diff = periodEnd.difference(periodStart);
    return diff.inDays + (diff.inHours % 24) / 24.0;
  }

  Map<String, dynamic> toJson() => {
    'keystrokes': keystrokes,
    'clicks': clicks,
    'windowChanges': windowChanges,
    'activeTimeSeconds': activeTimeSeconds,
    'topApps': topApps.map((app) => app.toJson()).toList(),
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'totalEvents': totalEvents,
    'productivityScore': productivityScore,
    'periodDays': periodDays,
  };

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      keystrokes: json['keystrokes'] as int,
      clicks: json['clicks'] as int,
      windowChanges: json['windowChanges'] as int,
      activeTimeSeconds: json['activeTimeSeconds'] as int,
      topApps: (json['topApps'] as List)
          .map((app) => AppUsage.fromJson(app as Map<String, dynamic>))
          .toList(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );
  }
}

/// Application usage statistics
class AppUsage {
  final String name;
  final int usageCount;
  final int totalTimeSeconds;
  final double percentage;
  final String? bundleId;

  const AppUsage({
    required this.name,
    required this.usageCount,
    required this.totalTimeSeconds,
    required this.percentage,
    this.bundleId,
  });

  /// Format duration as human-readable string
  String get formattedDuration {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'usageCount': usageCount,
    'totalTimeSeconds': totalTimeSeconds,
    'percentage': percentage,
    'bundleId': bundleId,
    'formattedDuration': formattedDuration,
  };

  factory AppUsage.fromJson(Map<String, dynamic> json) {
    return AppUsage(
      name: json['name'] as String,
      usageCount: json['usageCount'] as int,
      totalTimeSeconds: json['totalTimeSeconds'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      bundleId: json['bundleId'] as String?,
    );
  }
}

/// Session information for monitoring periods
class SessionInfo {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> metadata;

  const SessionInfo({
    required this.id,
    required this.startTime,
    this.endTime,
    this.metadata = const {},
  });

  /// Calculate session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Check if session is currently active
  bool get isActive => endTime == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'metadata': metadata,
    'duration': duration.inSeconds,
    'isActive': isActive,
  };

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Export format enumeration
enum ExportFormat {
  json,
  csv,
  sql;

  @override
  String toString() => name;

  /// Get file extension for format
  String get extension {
    switch (this) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.sql:
        return 'sql';
    }
  }

  /// Get MIME type for format
  String get mimeType {
    switch (this) {
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.sql:
        return 'application/sql';
    }
  }
}

/// Monitoring status with comprehensive information
class MonitoringStatus {
  final bool isRunning;
  final DateTime? startTime;
  final int? sessionId;
  final Map<String, bool> componentStatus;
  final List<String> errors;

  const MonitoringStatus({
    required this.isRunning,
    this.startTime,
    this.sessionId,
    this.componentStatus = const {},
    this.errors = const [],
  });

  /// Get uptime duration
  Duration? get uptime {
    if (startTime == null) return null;
    return DateTime.now().difference(startTime!);
  }

  /// Check if all components are healthy
  bool get isHealthy => isRunning && errors.isEmpty;

  Map<String, dynamic> toJson() => {
    'isRunning': isRunning,
    'startTime': startTime?.toIso8601String(),
    'sessionId': sessionId,
    'componentStatus': componentStatus,
    'errors': errors,
    'uptime': uptime?.inSeconds,
    'isHealthy': isHealthy,
  };

  factory MonitoringStatus.fromJson(Map<String, dynamic> json) {
    return MonitoringStatus(
      isRunning: json['isRunning'] as bool,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      sessionId: json['sessionId'] as int?,
      componentStatus: Map<String, bool>.from(
        json['componentStatus'] as Map<String, dynamic>? ?? {}
      ),
      errors: List<String>.from(json['errors'] as List? ?? []),
    );
  }
}