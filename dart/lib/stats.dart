/// Statistics and analytics for Selfspy Dart implementation
///
/// Advanced analytics with functional programming patterns and data visualization

import 'dart:convert';
import 'dart:math';

import 'storage.dart';
import 'types.dart';

/// Advanced statistics calculator with functional approach
class StatsCalculator {
  final ActivityStorage storage;

  const StatsCalculator(this.storage);

  /// Calculate comprehensive activity metrics
  Future<AdvancedActivityStats> calculateAdvanced(int days) async {
    final baseStats = await storage.getStats(days);

    // Calculate additional metrics
    final efficiency = _calculateEfficiency(baseStats);
    final patterns = await _calculatePatterns(days);
    final trends = await _calculateTrends(days);
    final insights = _generateInsights(baseStats, patterns);

    return AdvancedActivityStats(
      base: baseStats,
      efficiency: efficiency,
      patterns: patterns,
      trends: trends,
      insights: insights,
    );
  }

  /// Calculate activity efficiency metrics
  EfficiencyMetrics _calculateEfficiency(ActivityStats stats) {
    final totalEvents = stats.totalEvents;
    final activeHours = stats.activeTimeSeconds / 3600.0;

    final eventsPerHour = activeHours > 0 ? totalEvents / activeHours : 0;
    final keystrokesPerClick = stats.clicks > 0 ? stats.keystrokes / stats.clicks : 0;
    final focusScore = _calculateFocusScore(stats);

    return EfficiencyMetrics(
      eventsPerHour: eventsPerHour,
      keystrokesPerClick: keystrokesPerClick,
      focusScore: focusScore,
      productivityScore: stats.productivityScore,
    );
  }

  /// Calculate focus score based on window changes
  double _calculateFocusScore(ActivityStats stats) {
    if (stats.activeTimeSeconds == 0) return 0.0;

    final hoursActive = stats.activeTimeSeconds / 3600.0;
    final windowChangesPerHour = hoursActive > 0 ? stats.windowChanges / hoursActive : 0;

    // Lower window changes per hour = higher focus
    // Scale inversely: 20+ changes/hour = 0, 0 changes = 10
    final focusScore = (20 - windowChangesPerHour).clamp(0, 20) / 2;
    return focusScore.clamp(0.0, 10.0);
  }

  /// Calculate usage patterns over time
  Future<UsagePatterns> _calculatePatterns(int days) async {
    // This would analyze hourly/daily patterns in a real implementation
    // For now, return simulated patterns

    final hourlyDistribution = List.generate(24, (hour) {
      // Simulate typical work pattern (peak at 10am and 2pm)
      final morning = _gaussianDistribution(hour, 10, 2) * 0.7;
      final afternoon = _gaussianDistribution(hour, 14, 2) * 0.8;
      final evening = _gaussianDistribution(hour, 20, 1) * 0.3;
      return (morning + afternoon + evening).clamp(0.0, 1.0);
    });

    final weeklyDistribution = List.generate(7, (day) {
      // Simulate work week pattern (lower on weekends)
      if (day == 0 || day == 6) return 0.3; // Sunday/Saturday
      return 0.8 + (Random().nextDouble() * 0.4 - 0.2); // Weekdays with variance
    });

    final peakHours = _findPeakHours(hourlyDistribution);
    final mostActiveDay = _findMostActiveDay(weeklyDistribution);

    return UsagePatterns(
      hourlyDistribution: hourlyDistribution,
      weeklyDistribution: weeklyDistribution,
      peakHours: peakHours,
      mostActiveDay: mostActiveDay,
    );
  }

  /// Calculate trends over time periods
  Future<TrendAnalysis> _calculateTrends(int days) async {
    // In a real implementation, this would compare periods
    // For now, simulate trend data

    final keystrokeTrend = TrendData(
      current: 1000,
      previous: 950,
      changePercent: 5.26,
      direction: TrendDirection.up,
    );

    final clickTrend = TrendData(
      current: 200,
      previous: 180,
      changePercent: 11.11,
      direction: TrendDirection.up,
    );

    final focusTrend = TrendData(
      current: 7.5,
      previous: 6.8,
      changePercent: 10.29,
      direction: TrendDirection.up,
    );

    return TrendAnalysis(
      keystrokeTrend: keystrokeTrend,
      clickTrend: clickTrend,
      focusTrend: focusTrend,
    );
  }

  /// Generate actionable insights
  List<ActivityInsight> _generateInsights(ActivityStats stats, UsagePatterns patterns) {
    final insights = <ActivityInsight>[];

    // Productivity insights
    if (stats.productivityScore < 3.0) {
      insights.add(const ActivityInsight(
        type: InsightType.productivity,
        message: 'Low activity detected. Consider setting daily activity goals.',
        priority: InsightPriority.high,
        actionable: true,
      ));
    }

    // Focus insights
    final focusScore = _calculateFocusScore(stats);
    if (focusScore < 4.0) {
      insights.add(const ActivityInsight(
        type: InsightType.focus,
        message: 'High window switching detected. Try time-blocking for better focus.',
        priority: InsightPriority.medium,
        actionable: true,
      ));
    }

    // Peak time insights
    if (patterns.peakHours.isNotEmpty) {
      insights.add(ActivityInsight(
        type: InsightType.timing,
        message: 'Most productive during ${patterns.peakHours.join(", ")}:00. Schedule important work during these hours.',
        priority: InsightPriority.low,
        actionable: true,
      ));
    }

    // App diversity insights
    if (stats.topApps.length < 3) {
      insights.add(const ActivityInsight(
        type: InsightType.diversity,
        message: 'Limited application usage detected. Consider diversifying your workflow.',
        priority: InsightPriority.low,
        actionable: false,
      ));
    }

    return insights;
  }

  /// Gaussian distribution helper for pattern simulation
  double _gaussianDistribution(double x, double mean, double stdDev) {
    final variance = stdDev * stdDev;
    final exponent = -0.5 * pow((x - mean) / stdDev, 2);
    return (1 / sqrt(2 * pi * variance)) * exp(exponent);
  }

  /// Find peak activity hours
  List<int> _findPeakHours(List<double> hourlyDistribution) {
    final peaks = <int>[];
    final threshold = hourlyDistribution.reduce(max) * 0.8; // 80% of max

    for (int i = 0; i < hourlyDistribution.length; i++) {
      if (hourlyDistribution[i] >= threshold) {
        peaks.add(i);
      }
    }

    return peaks;
  }

  /// Find most active day of week
  int _findMostActiveDay(List<double> weeklyDistribution) {
    double maxActivity = 0;
    int mostActiveDay = 0;

    for (int i = 0; i < weeklyDistribution.length; i++) {
      if (weeklyDistribution[i] > maxActivity) {
        maxActivity = weeklyDistribution[i];
        mostActiveDay = i;
      }
    }

    return mostActiveDay;
  }
}

/// Advanced activity statistics with computed metrics
class AdvancedActivityStats {
  final ActivityStats base;
  final EfficiencyMetrics efficiency;
  final UsagePatterns patterns;
  final TrendAnalysis trends;
  final List<ActivityInsight> insights;

  const AdvancedActivityStats({
    required this.base,
    required this.efficiency,
    required this.patterns,
    required this.trends,
    required this.insights,
  });

  Map<String, dynamic> toJson() => {
    'base': base.toJson(),
    'efficiency': efficiency.toJson(),
    'patterns': patterns.toJson(),
    'trends': trends.toJson(),
    'insights': insights.map((i) => i.toJson()).toList(),
  };
}

/// Efficiency metrics for productivity analysis
class EfficiencyMetrics {
  final double eventsPerHour;
  final double keystrokesPerClick;
  final double focusScore;
  final double productivityScore;

  const EfficiencyMetrics({
    required this.eventsPerHour,
    required this.keystrokesPerClick,
    required this.focusScore,
    required this.productivityScore,
  });

  Map<String, dynamic> toJson() => {
    'eventsPerHour': eventsPerHour,
    'keystrokesPerClick': keystrokesPerClick,
    'focusScore': focusScore,
    'productivityScore': productivityScore,
  };
}

/// Usage patterns for temporal analysis
class UsagePatterns {
  final List<double> hourlyDistribution;
  final List<double> weeklyDistribution;
  final List<int> peakHours;
  final int mostActiveDay;

  const UsagePatterns({
    required this.hourlyDistribution,
    required this.weeklyDistribution,
    required this.peakHours,
    required this.mostActiveDay,
  });

  String get mostActiveDayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[mostActiveDay];
  }

  Map<String, dynamic> toJson() => {
    'hourlyDistribution': hourlyDistribution,
    'weeklyDistribution': weeklyDistribution,
    'peakHours': peakHours,
    'mostActiveDay': mostActiveDay,
    'mostActiveDayName': mostActiveDayName,
  };
}

/// Trend analysis for temporal comparisons
class TrendAnalysis {
  final TrendData keystrokeTrend;
  final TrendData clickTrend;
  final TrendData focusTrend;

  const TrendAnalysis({
    required this.keystrokeTrend,
    required this.clickTrend,
    required this.focusTrend,
  });

  Map<String, dynamic> toJson() => {
    'keystrokeTrend': keystrokeTrend.toJson(),
    'clickTrend': clickTrend.toJson(),
    'focusTrend': focusTrend.toJson(),
  };
}

/// Individual trend data point
class TrendData {
  final double current;
  final double previous;
  final double changePercent;
  final TrendDirection direction;

  const TrendData({
    required this.current,
    required this.previous,
    required this.changePercent,
    required this.direction,
  });

  Map<String, dynamic> toJson() => {
    'current': current,
    'previous': previous,
    'changePercent': changePercent,
    'direction': direction.name,
  };
}

/// Trend direction enumeration
enum TrendDirection {
  up,
  down,
  stable;

  String get emoji {
    switch (this) {
      case TrendDirection.up:
        return '📈';
      case TrendDirection.down:
        return '📉';
      case TrendDirection.stable:
        return '➡️';
    }
  }
}

/// Activity insight for actionable recommendations
class ActivityInsight {
  final InsightType type;
  final String message;
  final InsightPriority priority;
  final bool actionable;

  const ActivityInsight({
    required this.type,
    required this.message,
    required this.priority,
    required this.actionable,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'message': message,
    'priority': priority.name,
    'actionable': actionable,
  };
}

/// Insight type categorization
enum InsightType {
  productivity,
  focus,
  timing,
  diversity,
  health;

  String get emoji {
    switch (this) {
      case InsightType.productivity:
        return '📊';
      case InsightType.focus:
        return '🎯';
      case InsightType.timing:
        return '⏰';
      case InsightType.diversity:
        return '🌈';
      case InsightType.health:
        return '💪';
    }
  }
}

/// Insight priority levels
enum InsightPriority {
  low,
  medium,
  high,
  critical;

  String get emoji {
    switch (this) {
      case InsightPriority.low:
        return '💡';
      case InsightPriority.medium:
        return '⚠️';
      case InsightPriority.high:
        return '🚨';
      case InsightPriority.critical:
        return '🔥';
    }
  }
}

/// ASCII chart generator for terminal visualizations
class ASCIIChartGenerator {
  /// Generate horizontal bar chart
  static String generateBarChart(List<double> values, List<String> labels, {int width = 50}) {
    if (values.length != labels.length) {
      throw ArgumentError('Values and labels must have the same length');
    }

    final buffer = StringBuffer();
    final maxValue = values.reduce(max);

    for (int i = 0; i < values.length; i++) {
      final label = labels[i].padRight(15);
      final barLength = ((values[i] / maxValue) * width).round();
      final bar = '█' * barLength + '░' * (width - barLength);
      final value = values[i].toStringAsFixed(1);

      buffer.writeln('$label │$bar│ $value');
    }

    return buffer.toString();
  }

  /// Generate line chart using ASCII characters
  static String generateLineChart(List<double> values, {int height = 10, int width = 60}) {
    if (values.isEmpty) return '';

    final buffer = StringBuffer();
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;

    // Create chart grid
    final chart = List.generate(height, (_) => List.filled(width, ' '));

    // Plot points
    for (int i = 0; i < values.length && i < width; i++) {
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = (height - 1 - (normalizedValue * (height - 1))).round().clamp(0, height - 1);
      chart[y][i] = '●';
    }

    // Convert to string
    for (int y = 0; y < height; y++) {
      buffer.writeln(chart[y].join(''));
    }

    return buffer.toString();
  }

  /// Generate simple histogram
  static String generateHistogram(Map<String, int> data, {int maxBarLength = 40}) {
    final buffer = StringBuffer();
    final maxValue = data.values.reduce(max);

    for (final entry in data.entries) {
      final barLength = ((entry.value / maxValue) * maxBarLength).round();
      final bar = '█' * barLength;
      buffer.writeln('${entry.key.padRight(15)} $bar ${entry.value}');
    }

    return buffer.toString();
  }
}

/// Report generator for formatted output
class ReportGenerator {
  final StatsCalculator calculator;

  const ReportGenerator(this.calculator);

  /// Generate comprehensive text report
  Future<String> generateTextReport(int days) async {
    final stats = await calculator.calculateAdvanced(days);
    final buffer = StringBuffer();

    // Header
    buffer.writeln('📊 Selfspy Activity Report (Dart Implementation)');
    buffer.writeln('=' * 60);
    buffer.writeln('📅 Period: Last $days days');
    buffer.writeln('⏰ Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Basic statistics
    buffer.writeln('📈 Activity Summary:');
    buffer.writeln('  ⌨️  Keystrokes:     ${_formatNumber(stats.base.keystrokes)}');
    buffer.writeln('  🖱️  Mouse clicks:   ${_formatNumber(stats.base.clicks)}');
    buffer.writeln('  🪟  Window changes: ${_formatNumber(stats.base.windowChanges)}');
    buffer.writeln('  ⏰ Active time:    ${_formatDuration(stats.base.activeTimeSeconds)}');
    buffer.writeln('  🎯 Productivity:   ${stats.base.productivityScore.toStringAsFixed(1)}/10');
    buffer.writeln();

    // Efficiency metrics
    buffer.writeln('⚡ Efficiency Metrics:');
    buffer.writeln('  📊 Events/hour:      ${stats.efficiency.eventsPerHour.toStringAsFixed(1)}');
    buffer.writeln('  ⌨️ Keys/click ratio: ${stats.efficiency.keystrokesPerClick.toStringAsFixed(1)}');
    buffer.writeln('  🎯 Focus score:      ${stats.efficiency.focusScore.toStringAsFixed(1)}/10');
    buffer.writeln();

    // Top applications
    if (stats.base.topApps.isNotEmpty) {
      buffer.writeln('🏆 Most Used Applications:');
      for (int i = 0; i < stats.base.topApps.length; i++) {
        final app = stats.base.topApps[i];
        final emoji = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][i.clamp(0, 4)];
        buffer.writeln('  $emoji ${app.name.padRight(20)} ${app.percentage.toStringAsFixed(1)}% (${app.formattedDuration})');
      }
      buffer.writeln();
    }

    // Trends
    buffer.writeln('📈 Trends:');
    buffer.writeln('  ⌨️  Keystrokes: ${stats.trends.keystrokeTrend.direction.emoji} ${stats.trends.keystrokeTrend.changePercent.toStringAsFixed(1)}%');
    buffer.writeln('  🖱️  Clicks:     ${stats.trends.clickTrend.direction.emoji} ${stats.trends.clickTrend.changePercent.toStringAsFixed(1)}%');
    buffer.writeln('  🎯 Focus:      ${stats.trends.focusTrend.direction.emoji} ${stats.trends.focusTrend.changePercent.toStringAsFixed(1)}%');
    buffer.writeln();

    // Insights
    if (stats.insights.isNotEmpty) {
      buffer.writeln('💡 Insights & Recommendations:');
      for (int i = 0; i < stats.insights.length; i++) {
        final insight = stats.insights[i];
        buffer.writeln('  ${i + 1}. ${insight.priority.emoji} ${insight.message}');
      }
      buffer.writeln();
    }

    // Usage patterns
    buffer.writeln('🕐 Usage Patterns:');
    buffer.writeln('  📅 Most active day: ${stats.patterns.mostActiveDayName}');
    buffer.writeln('  ⏰ Peak hours: ${stats.patterns.peakHours.map((h) => '${h}:00').join(', ')}');
    buffer.writeln();

    return buffer.toString();
  }

  /// Generate JSON report
  Future<String> generateJsonReport(int days) async {
    final stats = await calculator.calculateAdvanced(days);
    return jsonEncode({
      'report_type': 'comprehensive',
      'generated_at': DateTime.now().toIso8601String(),
      'period_days': days,
      'implementation': 'dart',
      'data': stats.toJson(),
    });
  }

  /// Format large numbers with suffixes
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
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}