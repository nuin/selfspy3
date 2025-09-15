/// Activity monitoring coordinator for Selfspy Dart implementation
///
/// Modern async patterns with isolate-based concurrency for system monitoring

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import 'config.dart';
import 'platform.dart';
import 'storage.dart';
import 'types.dart';

/// Main activity monitor with dependency injection and modern async patterns
class ActivityMonitor {
  final SelfspyConfig config;
  final ActivityStorage storage;
  final PlatformInterface platform;
  final Logger _logger = Logger('ActivityMonitor');

  bool _isRunning = false;
  int? _sessionId;
  Completer<void>? _shutdownCompleter;

  // Stream subscriptions for different monitoring types
  StreamSubscription<KeystrokeEvent>? _keyboardSubscription;
  StreamSubscription<MouseEvent>? _mouseSubscription;
  StreamSubscription<WindowEvent>? _windowSubscription;

  // Monitoring status tracking
  final Map<String, bool> _componentStatus = {
    'keyboard': false,
    'mouse': false,
    'window': false,
    'storage': false,
  };

  final List<String> _errors = [];

  ActivityMonitor({
    required this.config,
    required this.storage,
    required this.platform,
  });

  /// Start monitoring with comprehensive error handling
  Future<void> start() async {
    if (_isRunning) {
      _logger.warning('Monitor already running');
      return;
    }

    _logger.info('Starting activity monitoring...');

    try {
      // Initialize storage
      await storage.initialize();
      _componentStatus['storage'] = true;

      // Start monitoring session
      _sessionId = await storage.insertSessionStart();
      _isRunning = true;
      _shutdownCompleter = Completer<void>();

      // Start monitoring components based on configuration
      if (config.captureText) {
        await _startKeyboardMonitoring();
      }

      if (config.captureMouse) {
        await _startMouseMonitoring();
      }

      if (config.captureWindows) {
        await _startWindowMonitoring();
      }

      // Start maintenance tasks
      _startMaintenanceTasks();

      _logger.info('Activity monitoring started successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to start monitoring', e, stackTrace);
      _errors.add('Start failed: $e');
      await stop();
      rethrow;
    }
  }

  /// Stop monitoring gracefully
  Future<void> stop() async {
    if (!_isRunning) return;

    _logger.info('Stopping activity monitoring...');

    _isRunning = false;

    // Cancel all subscriptions
    await _keyboardSubscription?.cancel();
    await _mouseSubscription?.cancel();
    await _windowSubscription?.cancel();

    // Stop platform monitoring
    await platform.stopMonitoring();

    // Update component status
    _componentStatus.updateAll((key, value) => false);

    // End monitoring session
    if (_sessionId != null) {
      try {
        await storage.updateSessionEnd(_sessionId!);
      } catch (e) {
        _logger.warning('Failed to update session end: $e');
      }
    }

    // Signal shutdown completion
    _shutdownCompleter?.complete();

    _logger.info('Activity monitoring stopped');
  }

  /// Wait for shutdown signal
  Future<void> waitForShutdown() async {
    if (_shutdownCompleter != null) {
      await _shutdownCompleter!.future;
    }
  }

  /// Get current monitoring status
  MonitoringStatus get status {
    return MonitoringStatus(
      isRunning: _isRunning,
      startTime: _sessionId != null ? DateTime.now() : null, // Simplified
      sessionId: _sessionId,
      componentStatus: Map.from(_componentStatus),
      errors: List.from(_errors),
    );
  }

  /// Start keyboard monitoring with async processing
  Future<void> _startKeyboardMonitoring() async {
    try {
      final keyboardStream = platform.startKeyboardMonitoring();

      _keyboardSubscription = keyboardStream.listen(
        (event) => _processKeystrokeEvent(event),
        onError: (error) {
          _logger.warning('Keyboard monitoring error: $error');
          _errors.add('Keyboard error: $error');
          _componentStatus['keyboard'] = false;
        },
        onDone: () {
          _logger.info('Keyboard monitoring stream closed');
          _componentStatus['keyboard'] = false;
        },
      );

      _componentStatus['keyboard'] = true;
      _logger.fine('Keyboard monitoring started');
    } catch (e) {
      _logger.severe('Failed to start keyboard monitoring: $e');
      _errors.add('Keyboard start failed: $e');
      throw e;
    }
  }

  /// Start mouse monitoring with coordinate tracking
  Future<void> _startMouseMonitoring() async {
    try {
      final mouseStream = platform.startMouseMonitoring();

      _mouseSubscription = mouseStream.listen(
        (event) => _processMouseEvent(event),
        onError: (error) {
          _logger.warning('Mouse monitoring error: $error');
          _errors.add('Mouse error: $error');
          _componentStatus['mouse'] = false;
        },
        onDone: () {
          _logger.info('Mouse monitoring stream closed');
          _componentStatus['mouse'] = false;
        },
      );

      _componentStatus['mouse'] = true;
      _logger.fine('Mouse monitoring started');
    } catch (e) {
      _logger.severe('Failed to start mouse monitoring: $e');
      _errors.add('Mouse start failed: $e');
      throw e;
    }
  }

  /// Start window monitoring with application context
  Future<void> _startWindowMonitoring() async {
    try {
      final windowStream = platform.startWindowMonitoring();

      _windowSubscription = windowStream.listen(
        (event) => _processWindowEvent(event),
        onError: (error) {
          _logger.warning('Window monitoring error: $error');
          _errors.add('Window error: $error');
          _componentStatus['window'] = false;
        },
        onDone: () {
          _logger.info('Window monitoring stream closed');
          _componentStatus['window'] = false;
        },
      );

      _componentStatus['window'] = true;
      _logger.fine('Window monitoring started');
    } catch (e) {
      _logger.severe('Failed to start window monitoring: $e');
      _errors.add('Window start failed: $e');
      throw e;
    }
  }

  /// Process keystroke event with privacy filtering
  Future<void> _processKeystrokeEvent(KeystrokeEvent event) async {
    if (!_isRunning) return;

    try {
      // Apply privacy filters
      if (_shouldExcludeKeystroke(event)) {
        _logger.finest('Keystroke excluded due to privacy settings');
        return;
      }

      // Encrypt if enabled
      var processedEvent = event;
      if (config.encryption.enabled) {
        processedEvent = await _encryptKeystroke(event);
      }

      // Store in database
      await storage.insertKeystroke(processedEvent);

      _logger.finest('Processed keystroke: ${event.key}');
    } catch (e) {
      _logger.warning('Failed to process keystroke: $e');
      _errors.add('Keystroke processing failed: $e');
    }
  }

  /// Process mouse event with coordinate validation
  Future<void> _processMouseEvent(MouseEvent event) async {
    if (!_isRunning) return;

    try {
      // Validate coordinates (basic sanity check)
      if (event.x < 0 || event.y < 0 || event.x > 10000 || event.y > 10000) {
        _logger.warning('Invalid mouse coordinates: (${event.x}, ${event.y})');
        return;
      }

      // Store in database
      await storage.insertMouseEvent(event);

      _logger.finest('Processed mouse ${event.type.name} at (${event.x}, ${event.y})');
    } catch (e) {
      _logger.warning('Failed to process mouse event: $e');
      _errors.add('Mouse processing failed: $e');
    }
  }

  /// Process window event with application tracking
  Future<void> _processWindowEvent(WindowEvent event) async {
    if (!_isRunning) return;

    try {
      // Check if app is excluded
      if (config.privacy.excludedApps.contains(event.appName)) {
        _logger.finest('Window excluded: ${event.appName}');
        return;
      }

      // Store in database and get window ID
      final windowId = await storage.insertWindowEvent(event);

      _logger.finest('Processed window change: ${event.appName} - ${event.title} (ID: $windowId)');
    } catch (e) {
      _logger.warning('Failed to process window event: $e');
      _errors.add('Window processing failed: $e');
    }
  }

  /// Check if keystroke should be excluded based on privacy settings
  bool _shouldExcludeKeystroke(KeystrokeEvent event) {
    // Check private mode
    if (config.privacy.privateMode) {
      return true;
    }

    // Check for sensitive keywords
    final keyLower = event.key.toLowerCase();
    for (final keyword in config.privacy.sensitiveKeywords) {
      if (keyLower.contains(keyword.toLowerCase())) {
        return true;
      }
    }

    // Check password protection (simplified detection)
    if (config.privacy.passwordProtection) {
      // This would be more sophisticated in a real implementation
      final passwordIndicators = ['password', 'passwd', 'secret', 'pin'];
      for (final indicator in passwordIndicators) {
        if (keyLower.contains(indicator)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Encrypt keystroke data using modern cryptography
  Future<KeystrokeEvent> _encryptKeystroke(KeystrokeEvent event) async {
    try {
      // Simple demonstration using SHA-256 (in practice, use proper encryption)
      final keyBytes = utf8.encode(event.key);
      final digest = sha256.convert(keyBytes);
      final encryptedKey = digest.toString();

      return KeystrokeEvent(
        timestamp: event.timestamp,
        key: encryptedKey,
        modifiers: event.modifiers,
        windowId: event.windowId,
        encrypted: true,
      );
    } catch (e) {
      _logger.warning('Failed to encrypt keystroke: $e');
      return event; // Return original on encryption failure
    }
  }

  /// Start background maintenance tasks
  void _startMaintenanceTasks() {
    // Periodic stats reporting
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      try {
        final stats = await storage.getStats(1);
        _logger.fine('Current stats: ${stats.keystrokes} keystrokes, ${stats.clicks} clicks');
      } catch (e) {
        _logger.warning('Failed to get stats: $e');
      }
    });

    // Periodic cleanup (if configured)
    if (config.database.cleanupDays > 0) {
      Timer.periodic(const Duration(hours: 24), (timer) async {
        if (!_isRunning) {
          timer.cancel();
          return;
        }

        try {
          await storage.cleanupOldData(config.database.cleanupDays);
          _logger.info('Completed daily cleanup');
        } catch (e) {
          _logger.warning('Failed to cleanup old data: $e');
          _errors.add('Cleanup failed: $e');
        }
      });
    }

    // Error list maintenance (prevent unbounded growth)
    Timer.periodic(const Duration(hours: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      if (_errors.length > 100) {
        _errors.removeRange(0, _errors.length - 50);
        _logger.fine('Trimmed error list');
      }
    });
  }
}

/// Monitoring statistics with performance metrics
class MonitoringMetrics {
  final int eventsProcessed;
  final Duration uptime;
  final Map<String, int> eventCounts;
  final List<String> recentErrors;
  final double memoryUsage;

  const MonitoringMetrics({
    required this.eventsProcessed,
    required this.uptime,
    required this.eventCounts,
    required this.recentErrors,
    required this.memoryUsage,
  });

  Map<String, dynamic> toJson() => {
    'eventsProcessed': eventsProcessed,
    'uptime': uptime.inSeconds,
    'eventCounts': eventCounts,
    'recentErrors': recentErrors,
    'memoryUsage': memoryUsage,
  };
}

/// Event buffer for batched processing
class EventBuffer<T> {
  final int maxSize;
  final Duration flushInterval;
  final List<T> _buffer = [];
  Timer? _flushTimer;

  EventBuffer({
    this.maxSize = 100,
    this.flushInterval = const Duration(seconds: 5),
  });

  /// Add event to buffer with automatic flushing
  Future<void> add(T event, Future<void> Function(List<T>) processor) async {
    _buffer.add(event);

    // Flush if buffer is full
    if (_buffer.length >= maxSize) {
      await _flush(processor);
    } else {
      // Set up timer for interval-based flushing
      _flushTimer?.cancel();
      _flushTimer = Timer(flushInterval, () => _flush(processor));
    }
  }

  /// Flush buffer manually
  Future<void> _flush(Future<void> Function(List<T>) processor) async {
    if (_buffer.isEmpty) return;

    final events = List<T>.from(_buffer);
    _buffer.clear();
    _flushTimer?.cancel();

    try {
      await processor(events);
    } catch (e) {
      // Re-add events to buffer on failure (with size limit)
      if (_buffer.length + events.length <= maxSize * 2) {
        _buffer.addAll(events);
      }
      rethrow;
    }
  }

  /// Get current buffer size
  int get size => _buffer.length;

  /// Dispose buffer and cancel timer
  void dispose() {
    _flushTimer?.cancel();
    _buffer.clear();
  }
}