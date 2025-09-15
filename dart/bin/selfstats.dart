#!/usr/bin/env dart

/// Selfstats - Activity Statistics for Dart Selfspy
///
/// Advanced analytics with beautiful terminal output and comprehensive insights

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../lib/config.dart';
import '../lib/storage.dart';
import '../lib/stats.dart';
import '../lib/types.dart';

final _logger = Logger('Selfstats');

/// Main entry point for statistics application
Future<void> main(List<String> arguments) async {
  _setupLogging();

  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show usage information')
    ..addFlag('version', abbr: 'v', help: 'Show version information');

  // Add subcommands
  final statsCommand = parser.addCommand('stats')
    ..addOption('days', defaultsTo: '7', help: 'Number of days to analyze')
    ..addOption('format', defaultsTo: 'table', help: 'Output format: table, json, summary')
    ..addFlag('detailed', help: 'Show detailed statistics')
    ..addFlag('apps', help: 'Include application usage')
    ..addOption('export', help: 'Export to file');

  final appsCommand = parser.addCommand('apps')
    ..addOption('days', defaultsTo: '7', help: 'Number of days to analyze')
    ..addOption('limit', defaultsTo: '10', help: 'Number of apps to show')
    ..addOption('format', defaultsTo: 'table', help: 'Output format: table, json');

  final liveCommand = parser.addCommand('live')
    ..addOption('interval', defaultsTo: '5', help: 'Update interval in seconds');

  final trendsCommand = parser.addCommand('trends')
    ..addOption('days', defaultsTo: '30', help: 'Number of days to analyze')
    ..addFlag('chart', help: 'Show ASCII charts');

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
      // Default to stats command
      await _showStats(statsCommand.parse(['--days', '7']));
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
    case 'stats':
      await _showStats(command);
      break;
    case 'apps':
      await _showApps(command);
      break;
    case 'live':
      await _showLiveStats(command);
      break;
    case 'trends':
      await _showTrends(command);
      break;
    default:
      stderr.writeln('Unknown command: ${command.name}');
      exit(1);
  }
}

/// Show activity statistics with advanced analytics
Future<void> _showStats(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final format = command['format'] as String;
  final detailed = command['detailed'] as bool;
  final apps = command['apps'] as bool;
  final exportFile = command['export'] as String?;

  print('📊 Generating statistics for $days days...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();
    final calculator = StatsCalculator(storage);

    String output;
    switch (format.toLowerCase()) {
      case 'json':
        final reportGen = ReportGenerator(calculator);
        output = await reportGen.generateJsonReport(days);
        break;
      case 'table':
        output = await _generateTableStats(calculator, days, detailed, apps);
        break;
      case 'summary':
        output = await _generateSummaryStats(calculator, days);
        break;
      default:
        throw ArgumentError('Unsupported format: $format. Use: table, json, summary');
    }

    if (exportFile != null) {
      await File(exportFile).writeAsString(output);
      print('✅ Statistics exported to $exportFile');
    } else {
      print(output);
    }
  } finally {
    await storage.close();
  }
}

/// Show application usage statistics
Future<void> _showApps(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final limit = int.parse(command['limit'] as String);
  final format = command['format'] as String;

  print('📱 Generating application usage statistics for $days days...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();
    final stats = await storage.getStats(days);

    switch (format.toLowerCase()) {
      case 'json':
        final appsData = stats.topApps.take(limit).map((app) => app.toJson()).toList();
        print(jsonEncode({
          'period_days': days,
          'applications': appsData,
          'generated_at': DateTime.now().toIso8601String(),
        }));
        break;
      case 'table':
        _printAppsTable(stats.topApps.take(limit).toList(), days);
        break;
      default:
        throw ArgumentError('Unsupported format: $format. Use: table, json');
    }
  } finally {
    await storage.close();
  }
}

/// Show live statistics with real-time updates
Future<void> _showLiveStats(ArgResults command) async {
  final interval = int.parse(command['interval'] as String);

  print('📊 Live Selfspy Statistics');
  print('Press Ctrl+C to stop');
  print('=' * 40);

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();
    var lastStats = await storage.getStats(1);

    while (true) {
      await Future.delayed(Duration(seconds: interval));

      final currentStats = await storage.getStats(1);

      // Calculate deltas
      final deltaKeystrokes = currentStats.keystrokes - lastStats.keystrokes;
      final deltaClicks = currentStats.clicks - lastStats.clicks;
      final deltaWindows = currentStats.windowChanges - lastStats.windowChanges;

      if (deltaKeystrokes > 0 || deltaClicks > 0 || deltaWindows > 0) {
        final timestamp = DateTime.now().toIso8601String().substring(11, 19);
        print('[$timestamp] ⌨️ +$deltaKeystrokes 🖱️ +$deltaClicks 🪟 +$deltaWindows');
      }

      lastStats = currentStats;
    }
  } finally {
    await storage.close();
  }
}

/// Show trend analysis with optional charts
Future<void> _showTrends(ArgResults command) async {
  final days = int.parse(command['days'] as String);
  final showChart = command['chart'] as bool;

  print('📈 Generating trend analysis for $days days...');

  final config = await SelfspyConfig.load();
  final storage = ActivityStorage(config.databasePath);

  try {
    await storage.initialize();
    final calculator = StatsCalculator(storage);
    final advanced = await calculator.calculateAdvanced(days);

    print('');
    print('📈 Activity Trends');
    print('═' * 50);
    print('');

    // Trend summary
    final trends = advanced.trends;
    print('⌨️  Keystrokes: ${trends.keystrokeTrend.direction.emoji} ${trends.keystrokeTrend.changePercent.toStringAsFixed(1)}%');
    print('🖱️  Mouse clicks: ${trends.clickTrend.direction.emoji} ${trends.clickTrend.changePercent.toStringAsFixed(1)}%');
    print('🎯 Focus score: ${trends.focusTrend.direction.emoji} ${trends.focusTrend.changePercent.toStringAsFixed(1)}%');
    print('');

    // Usage patterns
    print('🕐 Usage Patterns:');
    print('  📅 Most active day: ${advanced.patterns.mostActiveDayName}');
    print('  ⏰ Peak hours: ${advanced.patterns.peakHours.map((h) => '${h}:00').join(', ')}');
    print('');

    // ASCII charts if requested
    if (showChart) {
      print('📊 Hourly Activity Distribution:');
      final hourLabels = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
      final hourlyChart = ASCIIChartGenerator.generateBarChart(
        advanced.patterns.hourlyDistribution,
        hourLabels,
        width: 30,
      );
      print(hourlyChart);
      print('');

      print('📅 Weekly Activity Distribution:');
      const weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final weeklyChart = ASCIIChartGenerator.generateBarChart(
        advanced.patterns.weeklyDistribution,
        weekLabels,
        width: 40,
      );
      print(weeklyChart);
    }

    // Insights
    if (advanced.insights.isNotEmpty) {
      print('💡 Insights & Recommendations:');
      for (int i = 0; i < advanced.insights.length; i++) {
        final insight = advanced.insights[i];
        print('  ${i + 1}. ${insight.priority.emoji} ${insight.message}');
      }
    }
  } finally {
    await storage.close();
  }
}

/// Generate table format statistics
Future<String> _generateTableStats(StatsCalculator calculator, int days, bool detailed, bool apps) async {
  final advanced = await calculator.calculateAdvanced(days);
  final stats = advanced.base;
  final buffer = StringBuffer();

  buffer.writeln('');
  buffer.writeln('📊 Selfspy Activity Statistics (Last $days days)');
  buffer.writeln('=' * 60);
  buffer.writeln('');

  // Basic stats
  buffer.writeln('📈 Activity Summary:');
  buffer.writeln('  ⌨️  Keystrokes:     ${_formatNumber(stats.keystrokes)}');
  buffer.writeln('  🖱️  Mouse clicks:   ${_formatNumber(stats.clicks)}');
  buffer.writeln('  🪟  Window changes: ${_formatNumber(stats.windowChanges)}');
  buffer.writeln('  ⏰ Active time:    ${_formatDuration(stats.activeTimeSeconds)}');
  buffer.writeln('  🎯 Productivity:   ${stats.productivityScore.toStringAsFixed(1)}/10');
  buffer.writeln('');

  if (detailed) {
    buffer.writeln('⚡ Efficiency Metrics:');
    buffer.writeln('  📊 Events/hour:      ${advanced.efficiency.eventsPerHour.toStringAsFixed(1)}');
    buffer.writeln('  ⌨️ Keys/click ratio: ${advanced.efficiency.keystrokesPerClick.toStringAsFixed(1)}');
    buffer.writeln('  🎯 Focus score:      ${advanced.efficiency.focusScore.toStringAsFixed(1)}/10');
    buffer.writeln('');

    buffer.writeln('📈 Daily Averages:');
    buffer.writeln('  ⌨️  Keystrokes/day:     ${(stats.keystrokes / stats.periodDays).toStringAsFixed(0)}');
    buffer.writeln('  🖱️  Mouse clicks/day:   ${(stats.clicks / stats.periodDays).toStringAsFixed(0)}');
    buffer.writeln('  🪟  Window changes/day: ${(stats.windowChanges / stats.periodDays).toStringAsFixed(0)}');
    buffer.writeln('  ⏰ Active hours/day:   ${((stats.activeTimeSeconds / stats.periodDays) / 3600.0).toStringAsFixed(1)}h');
    buffer.writeln('');
  }

  if (apps && stats.topApps.isNotEmpty) {
    buffer.writeln('🏆 Most Used Applications:');
    for (int i = 0; i < stats.topApps.length; i++) {
      final app = stats.topApps[i];
      final emoji = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][i.clamp(0, 4)];
      final percentage = app.percentage.toStringAsFixed(1);
      buffer.writeln('  $emoji ${app.name.padRight(20)} ${percentage.padLeft(5)}% (${app.formattedDuration})');
    }
    buffer.writeln('');
  }

  return buffer.toString();
}

/// Generate summary format statistics
Future<String> _generateSummaryStats(StatsCalculator calculator, int days) async {
  final advanced = await calculator.calculateAdvanced(days);
  final stats = advanced.base;
  final buffer = StringBuffer();

  final totalEvents = stats.totalEvents;
  final activityScore = stats.productivityScore.round();

  buffer.writeln('📊 Quick Summary ($days days)');
  buffer.writeln('━' * 35);
  buffer.writeln('🎯 Activity Score: $activityScore/10');
  buffer.writeln('📝 Total Events:  ${_formatNumber(totalEvents)}');
  buffer.writeln('⏰ Active Time:   ${_formatDuration(stats.activeTimeSeconds)}');

  if (stats.topApps.isNotEmpty) {
    final topApp = stats.topApps.first;
    buffer.writeln('🏆 Top App:       ${topApp.name} (${topApp.percentage.toStringAsFixed(1)}%)');
  }

  return buffer.toString();
}

/// Print applications table
void _printAppsTable(List<AppUsage> apps, int days) {
  print('');
  print('🏆 Application Usage Statistics ($days days)');
  print('=' * 60);

  if (apps.isEmpty) {
    print('No application data found.');
    return;
  }

  print('');
  print('${"Rank".padRight(6)}${"Application".padRight(25)}${"Usage".padRight(10)}${"Time".padRight(15)}');
  print('-' * 56);

  for (int i = 0; i < apps.length; i++) {
    final app = apps[i];
    final rank = (i + 1).toString().padRight(6);
    final name = app.name.padRight(25);
    final usage = '${app.percentage.toStringAsFixed(1)}%'.padRight(10);
    final time = app.formattedDuration.padRight(15);

    print('$rank$name$usage$time');
  }

  print('');
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
  final secs = seconds % 60;

  final parts = <String>[];
  if (hours > 0) parts.add('${hours}h');
  if (minutes > 0) parts.add('${minutes}m');
  if (secs > 0 && hours == 0) parts.add('${secs}s');

  return parts.isEmpty ? '0s' : parts.join(' ');
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
  print('Selfstats - Dart Selfspy Statistics');
  print('');
  print('USAGE:');
  print('    selfstats [COMMAND] [OPTIONS]');
  print('');
  print('COMMANDS:');
  print('    stats                 Show activity statistics (default)');
  print('    apps                  Show application usage statistics');
  print('    live                  Show live statistics');
  print('    trends                Show trend analysis');
  print('');
  print('GLOBAL OPTIONS:');
  print('    -h, --help            Show this help message');
  print('    -v, --version         Show version information');
  print('');
  print('STATS OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 7)');
  print('    --format <FORMAT>     Output format: table, json, summary (default: table)');
  print('    --detailed            Show detailed statistics');
  print('    --apps                Include application usage');
  print('    --export <FILE>       Export to file');
  print('');
  print('APPS OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 7)');
  print('    --limit <N>           Number of apps to show (default: 10)');
  print('    --format <FORMAT>     Output format: table, json (default: table)');
  print('');
  print('LIVE OPTIONS:');
  print('    --interval <N>        Update interval in seconds (default: 5)');
  print('');
  print('TRENDS OPTIONS:');
  print('    --days <N>            Number of days to analyze (default: 30)');
  print('    --chart               Show ASCII charts');
  print('');
  print('EXAMPLES:');
  print('    selfstats');
  print('    selfstats stats --days 30 --detailed --apps');
  print('    selfstats apps --limit 5 --format json');
  print('    selfstats trends --days 14 --chart');
  print('    selfstats live --interval 3');
  print('');
  print('Dart Implementation Features:');
  print('  • Advanced analytics with trend analysis');
  print('  • ASCII charts and visualizations');
  print('  • Real-time live monitoring');
  print('  • Comprehensive insights and recommendations');
  print('  • Strong typing with null safety');
}

/// Print version and feature information
void _printVersion() {
  print('Selfstats v1.0.0 (Dart implementation)');
  print('Advanced activity statistics with elegant syntax');
  print('');
  print('Features:');
  print('  • Modern async/await patterns');
  print('  • Advanced analytics and insights');
  print('  • Beautiful ASCII visualizations');
  print('  • Real-time live statistics');
  print('  • Strong typing with null safety');
  print('  • Functional programming approach');
}