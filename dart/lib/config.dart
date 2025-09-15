/// Configuration management for Selfspy Dart implementation
///
/// Leverages Dart's modern features for type-safe configuration handling

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Main configuration class with immutable design
class SelfspyConfig {
  final String databasePath;
  final bool captureText;
  final bool captureMouse;
  final bool captureWindows;
  final EncryptionConfig encryption;
  final PrivacyConfig privacy;
  final DatabaseConfig database;
  final Map<String, dynamic> platformSpecific;

  const SelfspyConfig({
    required this.databasePath,
    this.captureText = true,
    this.captureMouse = true,
    this.captureWindows = true,
    required this.encryption,
    required this.privacy,
    required this.database,
    this.platformSpecific = const {},
  });

  /// Create copy with modified values (functional approach)
  SelfspyConfig copyWith({
    String? databasePath,
    bool? captureText,
    bool? captureMouse,
    bool? captureWindows,
    EncryptionConfig? encryption,
    PrivacyConfig? privacy,
    DatabaseConfig? database,
    Map<String, dynamic>? platformSpecific,
  }) {
    return SelfspyConfig(
      databasePath: databasePath ?? this.databasePath,
      captureText: captureText ?? this.captureText,
      captureMouse: captureMouse ?? this.captureMouse,
      captureWindows: captureWindows ?? this.captureWindows,
      encryption: encryption ?? this.encryption,
      privacy: privacy ?? this.privacy,
      database: database ?? this.database,
      platformSpecific: platformSpecific ?? this.platformSpecific,
    );
  }

  /// Load configuration with async file operations
  static Future<SelfspyConfig> load() async {
    final configPath = _getConfigPath();

    try {
      final file = File(configPath);
      if (!await file.exists()) {
        final defaultConfig = _createDefault();
        await defaultConfig.save();
        return defaultConfig;
      }

      final content = await file.readAsString();
      final yamlMap = loadYaml(content) as Map<String, dynamic>;
      return SelfspyConfig.fromMap(yamlMap);
    } catch (e) {
      // Return default config on error
      return _createDefault();
    }
  }

  /// Save configuration to file
  Future<void> save() async {
    final configPath = _getConfigPath();
    final configDir = path.dirname(configPath);

    // Ensure directory exists
    await Directory(configDir).create(recursive: true);

    final file = File(configPath);
    final yamlContent = _toYaml();
    await file.writeAsString(yamlContent);
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'database_path': databasePath,
      'monitoring': {
        'capture_text': captureText,
        'capture_mouse': captureMouse,
        'capture_windows': captureWindows,
      },
      'encryption': encryption.toMap(),
      'privacy': privacy.toMap(),
      'database': database.toMap(),
      'platform_specific': platformSpecific,
    };
  }

  /// Create from Map with null safety
  factory SelfspyConfig.fromMap(Map<String, dynamic> map) {
    final monitoring = map['monitoring'] as Map<String, dynamic>? ?? {};

    return SelfspyConfig(
      databasePath: map['database_path'] as String? ?? _getDefaultDatabasePath(),
      captureText: monitoring['capture_text'] as bool? ?? true,
      captureMouse: monitoring['capture_mouse'] as bool? ?? true,
      captureWindows: monitoring['capture_windows'] as bool? ?? true,
      encryption: EncryptionConfig.fromMap(
        map['encryption'] as Map<String, dynamic>? ?? {}
      ),
      privacy: PrivacyConfig.fromMap(
        map['privacy'] as Map<String, dynamic>? ?? {}
      ),
      database: DatabaseConfig.fromMap(
        map['database'] as Map<String, dynamic>? ?? {}
      ),
      platformSpecific: map['platform_specific'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON for export
  String toJson() => jsonEncode(toMap());

  /// Convert to YAML format
  String _toYaml() {
    final map = toMap();
    final buffer = StringBuffer();

    buffer.writeln('# Selfspy Configuration (Dart Implementation)');
    buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    _writeYamlMap(buffer, map, 0);

    return buffer.toString();
  }

  /// Write YAML map with proper indentation
  void _writeYamlMap(StringBuffer buffer, Map<String, dynamic> map, int indent) {
    final spaces = '  ' * indent;

    for (final entry in map.entries) {
      if (entry.value is Map) {
        buffer.writeln('$spaces${entry.key}:');
        _writeYamlMap(buffer, entry.value as Map<String, dynamic>, indent + 1);
      } else if (entry.value is List) {
        buffer.writeln('$spaces${entry.key}:');
        for (final item in entry.value as List) {
          buffer.writeln('$spaces  - $item');
        }
      } else {
        buffer.writeln('$spaces${entry.key}: ${entry.value}');
      }
    }
  }

  /// Create default configuration
  static SelfspyConfig _createDefault() {
    return SelfspyConfig(
      databasePath: _getDefaultDatabasePath(),
      encryption: const EncryptionConfig(),
      privacy: const PrivacyConfig(),
      database: const DatabaseConfig(),
    );
  }

  /// Get platform-specific config path
  static String _getConfigPath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';

    if (Platform.isMacOS) {
      return path.join(home, 'Library', 'Application Support', 'selfspy', 'config.yaml');
    } else if (Platform.isLinux) {
      final configHome = Platform.environment['XDG_CONFIG_HOME'] ??
          path.join(home, '.config');
      return path.join(configHome, 'selfspy', 'config.yaml');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? home;
      return path.join(appData, 'selfspy', 'config.yaml');
    } else {
      return path.join(home, '.selfspy', 'config.yaml');
    }
  }

  /// Get platform-specific database path
  static String _getDefaultDatabasePath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';

    if (Platform.isMacOS) {
      return path.join(home, 'Library', 'Application Support', 'selfspy', 'selfspy.db');
    } else if (Platform.isLinux) {
      final dataHome = Platform.environment['XDG_DATA_HOME'] ??
          path.join(home, '.local', 'share');
      return path.join(dataHome, 'selfspy', 'selfspy.db');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? home;
      return path.join(appData, 'selfspy', 'selfspy.db');
    } else {
      return path.join(home, '.selfspy', 'selfspy.db');
    }
  }
}

/// Encryption configuration with modern security practices
class EncryptionConfig {
  final bool enabled;
  final String algorithm;
  final String keyDerivation;
  final int iterations;

  const EncryptionConfig({
    this.enabled = true,
    this.algorithm = 'AES-256-GCM',
    this.keyDerivation = 'PBKDF2',
    this.iterations = 100000,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'algorithm': algorithm,
      'key_derivation': keyDerivation,
      'iterations': iterations,
    };
  }

  factory EncryptionConfig.fromMap(Map<String, dynamic> map) {
    return EncryptionConfig(
      enabled: map['enabled'] as bool? ?? true,
      algorithm: map['algorithm'] as String? ?? 'AES-256-GCM',
      keyDerivation: map['key_derivation'] as String? ?? 'PBKDF2',
      iterations: map['iterations'] as int? ?? 100000,
    );
  }
}

/// Privacy configuration with comprehensive controls
class PrivacyConfig {
  final bool privateMode;
  final List<String> excludedApps;
  final bool passwordProtection;
  final bool anonymizeData;
  final List<String> sensitiveKeywords;

  const PrivacyConfig({
    this.privateMode = false,
    this.excludedApps = const [],
    this.passwordProtection = true,
    this.anonymizeData = false,
    this.sensitiveKeywords = const [
      'password',
      'passwd',
      'secret',
      'token',
      'key',
      'credential',
    ],
  });

  Map<String, dynamic> toMap() {
    return {
      'private_mode': privateMode,
      'excluded_apps': excludedApps,
      'password_protection': passwordProtection,
      'anonymize_data': anonymizeData,
      'sensitive_keywords': sensitiveKeywords,
    };
  }

  factory PrivacyConfig.fromMap(Map<String, dynamic> map) {
    return PrivacyConfig(
      privateMode: map['private_mode'] as bool? ?? false,
      excludedApps: List<String>.from(map['excluded_apps'] as List? ?? []),
      passwordProtection: map['password_protection'] as bool? ?? true,
      anonymizeData: map['anonymize_data'] as bool? ?? false,
      sensitiveKeywords: List<String>.from(map['sensitive_keywords'] as List? ?? [
        'password',
        'passwd',
        'secret',
        'token',
        'key',
        'credential',
      ]),
    );
  }
}

/// Database configuration with performance tuning
class DatabaseConfig {
  final int backupIntervalHours;
  final int cleanupDays;
  final bool enableWal;
  final int cacheSize;
  final int bufferSize;

  const DatabaseConfig({
    this.backupIntervalHours = 168, // 1 week
    this.cleanupDays = 90,
    this.enableWal = true,
    this.cacheSize = 10000,
    this.bufferSize = 100,
  });

  Map<String, dynamic> toMap() {
    return {
      'backup_interval_hours': backupIntervalHours,
      'cleanup_days': cleanupDays,
      'enable_wal': enableWal,
      'cache_size': cacheSize,
      'buffer_size': bufferSize,
    };
  }

  factory DatabaseConfig.fromMap(Map<String, dynamic> map) {
    return DatabaseConfig(
      backupIntervalHours: map['backup_interval_hours'] as int? ?? 168,
      cleanupDays: map['cleanup_days'] as int? ?? 90,
      enableWal: map['enable_wal'] as bool? ?? true,
      cacheSize: map['cache_size'] as int? ?? 10000,
      bufferSize: map['buffer_size'] as int? ?? 100,
    );
  }
}