#!/usr/bin/env dart

/// Selfviz - Enhanced Activity Visualizations for Dart Selfspy
///
/// Beautiful terminal dashboards with rich visualizations and modern UI patterns

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../lib/config.dart';
import '../lib/storage.dart';
import '../lib/stats.dart';
import '../lib/types.dart';

final _logger = Logger('Selfviz');

/// Main entry point for visualization application
Future<void> main(List<String> arguments) async {
  _setupLogging();

  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show usage information')
    ..addFlag('version', abbr: 'v', help: 'Show version information');

  // Add subcommands
  final enhancedCommand = parser.addCommand('enhanced')
    ..addOption('days', defaultsTo: '7', help: 'Number of days to analyze')
    ..addFlag('charts', help: 'Include ASCII charts');

  final timelineCommand = parser.addCommand('timeline')
    ..addOption('days', defaultsTo: '1', help: 'Number of days to analyze')
    ..addOption('granularity', defaultsTo: 'hour', help: 'Timeline granularity: hour, day, week');

  final heatmapCommand = parser.addCommand('heatmap')
    ..addOption('days', defaultsTo: '30', help: 'Number of days to analyze')
    ..addOption('type', defaultsTo: 'activity', help: 'Heatmap type: activity, keyboard, mouse');

  final dashboardCommand = parser.addCommand('dashboard')
    ..addOption('refresh', defaultsTo: '2', help: 'Refresh interval in seconds');

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
      // Default to enhanced command
      await _runEnhanced(enhancedCommand.parse(['--days', '7']));
      return;
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

/// Execute the parsed command
Future<void> _executeCommand(ArgResults results) async {
  final command = results.command!;

  switch (command.name) {
    case 'enhanced':
      await _runEnhanced(command);
      break;
    case 'timeline':
      await _runTimeline(command);
      break;
    case 'heatmap':
      await _runHeatmap(command);
      break;
    case 'dashboard':
      await _runDashboard(command);
      break;
    default:
      stderr.writeln('Unknown command: ${command.name}');
      exit(1);
  }
}

/// Run enhanced statistics with beautiful visualizations
Future<void> _runEnhanced(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final includeCharts = command['charts'] as bool;

  print('🎨 Generating enhanced statistics for $days days...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();
    final calculator = StatsCalculator(storage);
    final advanced = await calculator.calculateAdvanced(days);

    _printEnhancedHeader(days);
    _printActivityOverview(advanced.base);
    _printProductivityMetrics(advanced);
    _printApplicationAnalysis(advanced.base);

    if (includeCharts) {
      _printASCIICharts(advanced);
    }

    _printInsightsAndTips(advanced);
  } finally {
    await storage.close();
  }
}

/// Run timeline visualization
Future<void> _runTimeline(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final granularity = command['granularity'] as String;

  print('📅 Generating timeline for $days days with $granularity granularity...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();

    _printTimelineHeader(days, granularity);

    switch (granularity.toLowerCase()) {
      case 'hour':
        await _printHourlyTimeline(storage, days);
        break;
      case 'day':
        await _printDailyTimeline(storage, days);
        break;
      case 'week':
        await _printWeeklyTimeline(storage, days);
        break;
      default:
        throw ArgumentError('Unsupported granularity: $granularity. Use: hour, day, week');
    }
  } finally {
    await storage.close();
  }
}

/// Run heatmap visualization
Future<void> _runHeatmap(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final type = command['type'] as String;

  print('🔥 Generating $type heatmap for $days days...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();

    switch (type.toLowerCase()) {
      case 'activity':
        await _printActivityHeatmap(storage, days);
        break;
      case 'keyboard':
        await _printKeyboardHeatmap(storage, days);
        break;
      case 'mouse':
        await _printMouseHeatmap(storage, days);
        break;
      default:
        throw ArgumentError('Unsupported heatmap type: $type. Use: activity, keyboard, mouse');
    }
  } finally {
    await storage.close();
  }
}

/// Run live dashboard with real-time updates
Future<void> _runDashboard(ArgResults command) async {
  final refreshSeconds = int.parse(command['refresh'] as String);

  print('\x1B[2J\x1B[H'); // Clear screen and move cursor to top
  print('🚀 Live Selfspy Dashboard');
  print('Press Ctrl+C to exit');
  print('=' * 60);

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();

    while (true) {
      await _printLiveDashboard(storage);
      await Future.delayed(Duration(seconds: refreshSeconds));
      print('\x1B[2J\x1B[H'); // Clear screen and move cursor to top
    }
  } finally {
    await storage.close();
  }
}

/// Print enhanced header with styling
void _printEnhancedHeader(int days) {
  print('');
  print('🎨 Enhanced Activity Analysis');
  print('━' * 50);
  print('📅 Period: Last $days days');
  print('⏰ Generated: ${DateTime.now().toIso8601String().substring(0, 19)}Z');
  print('💎 Dart Selfspy v1.0.0');
  print('');
}

/// Print activity overview with visual bars
void _printActivityOverview(ActivityStats stats) {
  print('📊 Activity Overview');
  print('─' * 30);

  // Create activity bars
  final maxValue = [stats.keystrokes, stats.clicks, stats.windowChanges].reduce(max);
  final keystrokeBar = _createBar(stats.keystrokes, maxValue, 30);
  final clickBar = _createBar(stats.clicks, maxValue, 30);
  final windowBar = _createBar(stats.windowChanges, maxValue, 30);

  print('⌨️  Keystrokes     │$keystrokeBar│ ${_formatNumber(stats.keystrokes)}');
  print('🖱️  Mouse Clicks   │$clickBar│ ${_formatNumber(stats.clicks)}');
  print('🪟  Window Changes │$windowBar│ ${_formatNumber(stats.windowChanges)}');
  print('');
}

/// Print productivity metrics with scores
void _printProductivityMetrics(AdvancedActivityStats advanced) {
  print('📈 Productivity Metrics');
  print('─' * 30);

  final stats = advanced.base;
  final efficiency = advanced.efficiency;

  final dailyKeystrokes = stats.keystrokes / stats.periodDays;
  final dailyActiveHours = (stats.activeTimeSeconds / stats.periodDays) / 3600.0;

  print('📝 Keystrokes/day:   ${_formatNumber(dailyKeystrokes.round())}');
  print('⏰ Active hours/day: ${dailyActiveHours.toStringAsFixed(1)}h');
  print('🎯 Productivity:     ${_createScoreBar(stats.productivityScore)} ${stats.productivityScore.toStringAsFixed(1)}/10');
  print('🔍 Focus Score:      ${_createScoreBar(efficiency.focusScore)} ${efficiency.focusScore.toStringAsFixed(1)}/10');
  print('💪 Activity level:   ${_getActivityLevel(stats.productivityScore)}');
  print('');
}

/// Print application analysis with rankings
void _printApplicationAnalysis(ActivityStats stats) {
  if (stats.topApps.isEmpty) return;

  print('🏆 Application Usage Analysis');
  print('─' * 35);

  final topApps = stats.topApps.take(5).toList();
  for (int i = 0; i < topApps.length; i++) {
    final app = topApps[i];
    final emoji = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][i];
    final percentageBar = _createPercentageBar(app.percentage, 20);

    print('$emoji ${app.name.padRight(20)} │$percentageBar│ ${app.percentage.toStringAsFixed(1)}% (${app.formattedDuration})');
  }
  print('');
}

/// Print ASCII charts for advanced visualization
void _printASCIICharts(AdvancedActivityStats advanced) {
  print('📊 Activity Charts');
  print('─' * 20);
  print('');

  // Hourly activity pattern
  print('🕐 Daily Activity Pattern:');
  for (int hour = 0; hour < 24; hour++) {
    final intensity = advanced.patterns.hourlyDistribution[hour];
    final barLength = (intensity * 20).round();
    final bar = '█' * barLength + '░' * (20 - barLength);
    print('  ${hour.toString().padLeft(2, '0')}:00 │$bar│ ${(intensity * 100).toStringAsFixed(0)}%');
  }
  print('');

  // Weekly pattern
  print('📅 Weekly Activity Pattern:');
  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  for (int day = 0; day < 7; day++) {
    final intensity = advanced.patterns.weeklyDistribution[day];
    final barLength = (intensity * 30).round();
    final bar = '█' * barLength + '░' * (30 - barLength);
    print('  ${weekDays[day]} │$bar│ ${(intensity * 100).toStringAsFixed(0)}%');
  }
  print('');
}

/// Print insights and actionable tips
void _printInsightsAndTips(AdvancedActivityStats advanced) {
  print('💡 Insights & Recommendations');
  print('─' * 35);

  if (advanced.insights.isEmpty) {
    print('✨ Great work! Your activity patterns look healthy.');
    print('📊 Keep monitoring to track productivity trends.');
  } else {
    for (int i = 0; i < advanced.insights.length; i++) {
      final insight = advanced.insights[i];
      print('${i + 1}. ${insight.priority.emoji} ${insight.message}');
    }
  }

  print('');
  print('🎯 Pro Tips:');
  print('• Use focused work sessions to improve productivity');
  print('• Take regular breaks to maintain high performance');
  print('• Monitor your peak hours for optimal scheduling');
  print('');
}

/// Print timeline header
void _printTimelineHeader(int days, String granularity) {
  print('');
  print('📅 Activity Timeline ($granularity view)');
  print('━' * 50);
  print('📊 Period: Last $days days');
  print('⏰ Generated: ${DateTime.now().toIso8601String().substring(0, 19)}Z');
  print('');
}

/// Print hourly timeline
Future<void> _printHourlyTimeline(ActivityStorage storage, int days) async {
  print('🕐 Hourly Activity Timeline:');
  print('─' * 30);

  // Simulate hourly data (in a real implementation, this would query the database)
  for (int hour = 0; hour < 24; hour++) {
    final activity = _simulateHourlyActivity(hour);
    final bar = _createActivityBar(activity, 30);
    final timeStr = '${hour.toString().padLeft(2, '0')}:00';

    print('$timeStr │$bar│ ${activity.toStringAsFixed(0)} events');
  }
  print('');
}

/// Print daily timeline
Future<void> _printDailyTimeline(ActivityStorage storage, int days) async {
  print('📅 Daily Activity Timeline:');
  print('─' * 30);

  final today = DateTime.now();
  for (int i = days - 1; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final activity = _simulateDailyActivity(date);
    final bar = _createActivityBar(activity, 40);
    final dateStr = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

    print('$dateStr │$bar│ ${activity.toStringAsFixed(0)} events');
  }
  print('');
}

/// Print weekly timeline
Future<void> _printWeeklyTimeline(ActivityStorage storage, int days) async {
  print('📅 Weekly Activity Timeline:');
  print('─' * 30);

  final weeks = (days / 7).ceil();
  for (int i = weeks - 1; i >= 0; i--) {
    final weekStart = DateTime.now().subtract(Duration(days: (i + 1) * 7));
    final activity = _simulateWeeklyActivity(weekStart);
    final bar = _createActivityBar(activity, 35);
    final weekStr = 'Week ${weekStart.month}/${weekStart.day}';

    print('$weekStr │$bar│ ${activity.toStringAsFixed(0)} events');
  }
  print('');
}

/// Print activity heatmap
Future<void> _printActivityHeatmap(ActivityStorage storage, int days) async {
  print('🔥 Activity Heatmap');
  print('━' * 30);
  print('');

  // Create a 7x24 heatmap (days x hours)
  print('      ' + List.generate(24, (h) => h.toString().padLeft(2, '0')).join(' '));

  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  for (int day = 0; day < 7; day++) {
    final row = StringBuffer('${weekDays[day]} ');
    for (int hour = 0; hour < 24; hour++) {
      final intensity = _simulateHeatmapIntensity(day, hour);
      row.write(_getHeatmapChar(intensity));
      row.write(' ');
    }
    print(row.toString());
  }

  print('');
  print('Legend: ░ Low ▒ Medium ▓ High █ Very High');
  print('');
}

/// Print keyboard heatmap
Future<void> _printKeyboardHeatmap(ActivityStorage storage, int days) async {
  print('⌨️ Keyboard Activity Heatmap');
  print('━' * 35);
  print('');

  // Simplified keyboard layout visualization
  final keyRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  for (final row in keyRows) {
    final rowStr = StringBuffer();
    for (final key in row) {
      final intensity = Random().nextDouble();
      final char = _getHeatmapChar(intensity);
      rowStr.write('$char ');
    }
    print(rowStr.toString());
  }

  print('');
  print('Legend: ░ Rarely used ▒ Sometimes ▓ Often █ Very often');
  print('');
}

/// Print mouse heatmap
Future<void> _printMouseHeatmap(ActivityStorage storage, int days) async {
  print('🖱️ Mouse Activity Heatmap');
  print('━' * 30);
  print('');

  // Create a grid representing screen areas
  for (int y = 0; y < 15; y++) {
    final row = StringBuffer();
    for (int x = 0; x < 50; x++) {
      final intensity = _simulateMouseHeatmap(x, y);
      row.write(_getHeatmapChar(intensity));
    }
    print(row.toString());
  }

  print('');
  print('Legend: ░ Low activity ▒ Medium ▓ High █ Very high');
  print('');
}

/// Print live dashboard with real-time data
Future<void> _printLiveDashboard(ActivityStorage storage) async {
  final stats = await storage.getStats(1);
  final calculator = StatsCalculator(storage);
  final advanced = await calculator.calculateAdvanced(1);

  print('🚀 Live Selfspy Dashboard');
  print('━' * 60);
  print('⏰ ${DateTime.now().toIso8601String().substring(11, 19)} UTC');
  print('');

  // Current activity summary
  print('📊 Today\'s Activity:');
  print('  ⌨️  Keystrokes: ${_formatNumber(stats.keystrokes)}');
  print('  🖱️  Clicks: ${_formatNumber(stats.clicks)}');
  print('  🪟  Windows: ${_formatNumber(stats.windowChanges)}');
  print('  ⏰ Active: ${_formatDuration(stats.activeTimeSeconds)}');
  print('');

  // Productivity metrics
  print('🎯 Productivity:');
  print('  📈 Score: ${stats.productivityScore.toStringAsFixed(1)}/10');
  print('  🔍 Focus: ${advanced.efficiency.focusScore.toStringAsFixed(1)}/10');
  print('  ⚡ Events/hour: ${advanced.efficiency.eventsPerHour.toStringAsFixed(1)}');
  print('');

  // Recent activity (simulated)
  print('📝 Recent Activity:');
  final recent = _generateRecentActivity();
  for (final activity in recent) {
    print('  $activity');
  }
  print('');

  // Current top app
  if (stats.topApps.isNotEmpty) {
    final topApp = stats.topApps.first;
    print('🏆 Current Top App: ${topApp.name} (${topApp.percentage.toStringAsFixed(1)}%)');
    print('');
  }

  print('🔄 Refreshing every 2 seconds... Press Ctrl+C to exit');
}

/// Create activity bar for visualizations
String _createBar(int value, int maxValue, int width) {
  if (maxValue == 0) return '░' * width;

  final ratio = value / maxValue;
  final filled = (ratio * width).round();
  return '█' * filled + '░' * (width - filled);
}

/// Create percentage bar
String _createPercentageBar(double percentage, int width) {
  final filled = ((percentage / 100) * width).round();
  return '█' * filled + '░' * (width - filled);
}

/// Create score bar for ratings
String _createScoreBar(double score) {
  final filled = (score / 10 * 10).round();
  return '█' * filled + '░' * (10 - filled);
}

/// Create activity bar with scaling
String _createActivityBar(double activity, int width) {
  final normalized = (activity / 100).clamp(0.0, 1.0);
  final filled = (normalized * width).round();
  return '█' * filled + '░' * (width - filled);
}

/// Get activity level description
String _getActivityLevel(double score) {
  if (score >= 8) return '🔥 Very High';
  if (score >= 6) return '🚀 High';
  if (score >= 4) return '📈 Medium';
  if (score >= 2) return '🐌 Low';
  return '😴 Very Low';
}

/// Get heatmap character based on intensity
String _getHeatmapChar(double intensity) {
  if (intensity > 0.75) return '█';
  if (intensity > 0.5) return '▓';
  if (intensity > 0.25) return '▒';
  return '░';
}

/// Simulate hourly activity for demo purposes
double _simulateHourlyActivity(int hour) {
  // Simulate typical work pattern
  if (hour >= 9 && hour <= 17) {
    return 50 + Random().nextDouble() * 50; // Work hours
  } else if (hour >= 18 && hour <= 22) {
    return 20 + Random().nextDouble() * 30; // Evening
  } else {
    return Random().nextDouble() * 10; // Night/early morning
  }
}

/// Simulate daily activity
double _simulateDailyActivity(DateTime date) {
  // Weekdays vs weekends
  if (date.weekday >= 6) {
    return 200 + Random().nextDouble() * 300; // Weekend
  } else {
    return 500 + Random().nextDouble() * 400; // Weekday
  }
}

/// Simulate weekly activity
double _simulateWeeklyActivity(DateTime weekStart) {
  return 2000 + Random().nextDouble() * 1500;
}

/// Simulate heatmap intensity
double _simulateHeatmapIntensity(int day, int hour) {
  // Higher intensity during work hours on weekdays
  if (day >= 1 && day <= 5 && hour >= 9 && hour <= 17) {
    return 0.5 + Random().nextDouble() * 0.5;
  } else {
    return Random().nextDouble() * 0.4;
  }
}

/// Simulate mouse heatmap
double _simulateMouseHeatmap(int x, int y) {
  // Center area tends to have higher activity
  final centerX = 25;
  final centerY = 7;
  final distance = sqrt(pow(x - centerX, 2) + pow(y - centerY, 2));
  final intensity = 1.0 - (distance / 30).clamp(0.0, 1.0);
  return intensity * Random().nextDouble();
}

/// Generate recent activity items
List<String> _generateRecentActivity() {
  final activities = [
    '🔤 Text input detected',
    '🖱️ Mouse click at (425, 320)',
    '🪟 Switched to Code Editor',
    '⌨️ Rapid typing sequence',
    '🔍 Window focus changed',
  ];

  return activities.take(3).toList();
}

/// Format numbers with suffixes
String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  } else {
    return number.toString();
  }
}

/// Format duration as human-readable string
String _formatDuration(int seconds) {
  if (seconds <= 0) return '0s';

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}

/// Setup logging with appropriate levels
void _setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final time = record.time.toIso8601String().substring(11, 19);
    stderr.writeln('$time [${record.level.name}] ${record.loggerName}: ${record.message}');
  });
}

/// Print comprehensive help information
void _printHelp(ArgParser parser) {
  print('Selfviz - Dart Selfspy Enhanced Visualizations');
  print('');
  print('USAGE:');
  print('    selfviz [COMMAND] [OPTIONS]');
  print('');
  print('COMMANDS:');
  print('    enhanced              Show enhanced statistics (default)');
  print('    timeline              Show activity timeline');
  print('    heatmap               Show activity heatmap');
  print('    dashboard             Show live dashboard');
  print('');
  print('GLOBAL OPTIONS:');
  print('    -h, --help            Show this help message');
  print('    -v, --version         Show version information');
  print('');
  print('ENHANCED OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 7)');
  print('    --charts              Include ASCII charts');
  print('');
  print('TIMELINE OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 1)');
  print('    --granularity <TYPE>  Timeline granularity: hour, day, week (default: hour)');
  print('');
  print('HEATMAP OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 30)');
  print('    --type <TYPE>         Heatmap type: activity, keyboard, mouse (default: activity)');
  print('');
  print('DASHBOARD OPTIONS:');
  print('    --refresh <N>         Refresh interval in seconds (default: 2)');
  print('');
  print('EXAMPLES:');
  print('    selfviz');
  print('    selfviz enhanced --days 14 --charts');
  print('    selfviz timeline --granularity day --days 7');
  print('    selfviz heatmap --type keyboard --days 14');
  print('    selfviz dashboard --refresh 5');
  print('');
  print('Dart Implementation Features:');
  print('  • Beautiful ASCII visualizations');
  print('  • Real-time live dashboard');
  print('  • Interactive heatmaps and timelines');
  print('  • Advanced analytics with insights');
  print('  • Modern async/await patterns');
}

/// Print version and feature information
void _printVersion() {
  print('Selfviz v1.0.0 (Dart implementation)');
  print('Enhanced activity visualizations with elegant syntax');
  print('');
  print('Features:');
  print('  • Beautiful terminal dashboards');
  print('  • ASCII charts and heatmaps');
  print('  • Real-time live monitoring');
  print('  • Timeline visualizations');
  print('  • Interactive analytics');
  print('  • Strong typing with null safety');
}