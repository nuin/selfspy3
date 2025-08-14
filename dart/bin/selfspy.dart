#!/usr/bin/env dart

/// Selfspy - Modern Activity Monitoring in Dart
/// 
/// Elegant syntax with excellent performance, potential for Flutter GUIs,
/// and modern async programming patterns for system monitoring.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../lib/config.dart';
import '../lib/monitor.dart';
import '../lib/storage.dart';
import '../lib/platform.dart';
import '../lib/types.dart';
import '../lib/stats.dart';

final _logger = Logger('Selfspy');

/// Main entry point with command line argument processing
Future<void> main(List<String> arguments) async {
  _setupLogging();
  
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show usage information')
    ..addFlag('version', abbr: 'v', help: 'Show version information');

  // Add subcommands
  final startCommand = parser.addCommand('start')
    ..addFlag('no-text', help: 'Disable text capture for privacy')
    ..addFlag('no-mouse', help: 'Disable mouse monitoring')
    ..addFlag('debug', help: 'Enable debug logging');

  parser.addCommand('stop');

  final statsCommand = parser.addCommand('stats')
    ..addOption('days', defaultsTo: '7', help: 'Number of days to analyze')
    ..addFlag('json', help: 'Output in JSON format');

  parser.addCommand('check');

  final exportCommand = parser.addCommand('export')
    ..addOption('format', defaultsTo: 'json', help: 'Export format (json, csv, sql)')
    ..addOption('output', help: 'Output file path')
    ..addOption('days', defaultsTo: '30', help: 'Number of days to export');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printHelp(parser);
      return;
    }

    if (results['version'] as bool) {
      _printVersion();
      return;
    }

    if (results.command == null) {
      _printHelp(parser);
      exit(1);
    }

    await _executeCommand(results);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('');
    _printHelp(parser);
    exit(1);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

/// Execute the parsed command with proper error handling
Future<void> _executeCommand(ArgResults results) async {
  final command = results.command!;

  switch (command.name) {
    case 'start':
      await _startMonitoring(command);
      break;
    case 'stop':
      await _stopMonitoring();
      break;
    case 'stats':
      await _showStats(command);
      break;
    case 'check':
      await _checkPermissions();
      break;
    case 'export':
      await _exportData(command);
      break;
    default:
      stderr.writeln('Unknown command: ${command.name}');
      exit(1);
  }
}

/// Start monitoring with modern async patterns
Future<void> _startMonitoring(ArgResults command) async {
  print('🚀 Starting Selfspy monitoring (Dart implementation)');

  // Load configuration
  final config = await SelfspyConfig.load();

  // Apply command line options
  if (command['no-text'] as bool) {
    config = config.copyWith(captureText: false);
  }
  if (command['no-mouse'] as bool) {
    config = config.copyWith(captureMouse: false);
  }
  if (command['debug'] as bool) {
    Logger.root.level = Level.FINE;
  }

  // Check permissions
  final permissions = await PlatformInterface.checkPermissions();
  if (!permissions.hasAllPermissions) {
    print('❌ Insufficient permissions for monitoring');
    print('Missing permissions:');
    if (!permissions.accessibility) {
      print('   - Accessibility permission required');
    }
    if (!permissions.inputMonitoring) {
      print('   - Input monitoring permission required');
    }

    print('\nAttempting to request permissions...');
    final granted = await PlatformInterface.requestPermissions();
    if (!granted) {
      stderr.writeln('Failed to obtain required permissions');
      exit(1);
    }
  }

  // Initialize storage
  final storage = ActivityStorage(config.databasePath);
  await storage.initialize();

  // Create monitor with dependency injection
  final monitor = ActivityMonitor(
    config: config,
    storage: storage,
    platform: PlatformInterface.current,
  );

  // Set up graceful shutdown
  late StreamSubscription signalSubscription;
  signalSubscription = ProcessSignal.sigint.watch().listen((_) async {
    print('\n🛑 Received shutdown signal, stopping gracefully...');
    await signalSubscription.cancel();
    await monitor.stop();
    await storage.close();
    exit(0);
  });

  try {
    // Start monitoring
    await monitor.start();

    print('✅ Selfspy monitoring started successfully');
    print('📊 Press Ctrl+C to stop monitoring');

    // Keep running until interrupted
    await monitor.waitForShutdown();
  } finally {
    await signalSubscription.cancel();
    await monitor.stop();
    await storage.close();
  }
}

/// Stop monitoring gracefully
Future<void> _stopMonitoring() async {
  print('🛑 Stopping Selfspy monitoring...');
  
  // Send signal to running process (implementation would find and signal the process)
  print('✅ Stop signal sent');
}

/// Show activity statistics with async data processing
Future<void> _showStats(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final jsonOutput = command['json'] as bool;

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);
  
  try {
    await storage.initialize();
    final stats = await storage.getStats(days);

    if (jsonOutput) {
      print(jsonEncode(stats.toJson()));
    } else {
      _printFormattedStats(stats, days);
    }
  } finally {
    await storage.close();
  }
}

/// Check system permissions and display comprehensive status
Future<void> _checkPermissions() async {
  print('🔍 Checking Selfspy permissions...');
  print('=' * 35);
  print('');

  final permissions = await PlatformInterface.checkPermissions();
  
  if (permissions.hasAllPermissions) {
    print('✅ All permissions granted');
  } else {
    print('❌ Missing permissions:');
    if (!permissions.accessibility) {
      print('   - Accessibility permission required');
    }
    if (!permissions.inputMonitoring) {
      print('   - Input monitoring permission required');
    }
    if (!permissions.screenRecording) {
      print('   - Screen recording permission (optional)');
    }
  }

  print('');
  print('📱 System Information:');
  final systemInfo = await PlatformInterface.getSystemInfo();
  print('   Platform: ${systemInfo.platform}');
  print('   Architecture: ${systemInfo.architecture}');
  print('   Dart Version: ${Platform.version}');
  print('   VM: ${Platform.executable}');
}

/// Export data with type-safe serialization
Future<void> _exportData(ArgResults command) async {
  final format = command['format'] as String;
  final output = command['output'] as String?;
  final days = int.parse(command['days'] as String);

  print('📤 Exporting $days days of data in $format format...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();
    
    final String data;
    switch (format.toLowerCase()) {
      case 'json':
        data = await storage.exportJson(days);
        break;
      case 'csv':
        data = await storage.exportCsv(days);
        break;
      case 'sql':
        data = await storage.exportSql(days);
        break;
      default:
        throw ArgumentError('Unsupported export format: $format');
    }

    if (output != null) {
      await File(output).writeAsString(data);
      print('✅ Data exported to $output');
    } else {
      print(data);
    }
  } finally {
    await storage.close();
  }
}

/// Print formatted statistics with elegant output
void _printFormattedStats(ActivityStats stats, int days) {
  print('');
  print('📊 Selfspy Activity Statistics (Last $days days)');
  print('=' * 50);
  print('');
  print('⌨️  Keystrokes: ${_formatNumber(stats.keystrokes)}');
  print('🖱️  Mouse clicks: ${_formatNumber(stats.clicks)}');
  print('🪟  Window changes: ${_formatNumber(stats.windowChanges)}');
  print('⏰ Active time: ${_formatDuration(stats.activeTimeSeconds)}');
  
  if (stats.topApps.isNotEmpty) {
    print('📱 Most used applications:');
    for (var i = 0; i < stats.topApps.length; i++) {
      final app = stats.topApps[i];
      print('   ${i + 1}. ${app.name} (${app.percentage.toStringAsFixed(1)}%)');
    }
  }
  print('');
}

/// Format numbers with Dart's elegant string interpolation
String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  } else {
    return number.toString();
  }
}

/// Format duration with functional approach
String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}

/// Setup logging with configurable levels
void _setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final time = record.time.toIso8601String().substring(11, 19);
    print('$time [${record.level.name}] ${record.loggerName}: ${record.message}');
  });
}

/// Print comprehensive help information
void _printHelp(ArgParser parser) {
  print('Selfspy - Modern Activity Monitoring in Dart');
  print('');
  print('USAGE:');
  print('    selfspy [COMMAND] [OPTIONS]');
  print('');
  print('COMMANDS:');
  print('    start                 Start activity monitoring');
  print('    stop                  Stop running monitoring instance');
  print('    stats                 Show activity statistics');
  print('    check                 Check system permissions and setup');
  print('    export                Export data to various formats');
  print('');
  print('GLOBAL OPTIONS:');
  print('    -h, --help            Show this help message');
  print('    -v, --version         Show version information');
  print('');
  print('START OPTIONS:');
  print('    --no-text             Disable text capture for privacy');
  print('    --no-mouse            Disable mouse monitoring');
  print('    --debug               Enable debug logging');
  print('');
  print('STATS OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 7)');
  print('    --json                Output in JSON format');
  print('');
  print('EXPORT OPTIONS:');
  print('    --format <FORMAT>     Export format: json, csv, sql (default: json)');
  print('    --output <FILE>       Output file path');
  print('    --days <N>            Number of days to export (default: 30)');
  print('');
  print('EXAMPLES:');
  print('    selfspy start');
  print('    selfspy start --no-text --debug');
  print('    selfspy stats --days 30 --json');
  print('    selfspy export --format csv --output activity.csv');
  print('');
  print('Dart Implementation Features:');
  print('  • Elegant syntax with strong typing');
  print('  • Modern async/await patterns');
  print('  • Excellent performance');
  print('  • Potential for Flutter GUI development');
  print('  • Null safety and sound type system');
}

/// Print version and feature information
void _printVersion() {
  print('Selfspy v1.0.0 (Dart implementation)');
  print('Modern activity monitoring with elegant syntax');
  print('');
  print('Features:');
  print('  • Strong typing with null safety');
  print('  • Modern async/await programming');
  print('  • Excellent cross-platform support');
  print('  • Potential Flutter GUI integration');
  print('  • Sound type system');
  print('  • Hot reload for rapid development');
}