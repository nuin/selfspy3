/// Platform abstraction layer for Selfspy Dart implementation
///
/// Leverages Dart's strong typing and FFI for cross-platform system integration

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'types.dart';

/// Abstract platform interface for cross-platform support
abstract class PlatformInterface {
  /// Get current platform implementation
  static PlatformInterface get current {
    if (Platform.isMacOS) {
      return MacOSPlatform();
    } else if (Platform.isLinux) {
      return LinuxPlatform();
    } else if (Platform.isWindows) {
      return WindowsPlatform();
    } else {
      return FallbackPlatform();
    }
  }

  /// Check system permissions
  static Future<PermissionStatus> checkPermissions() async {
    return current.checkPermissions();
  }

  /// Request necessary permissions
  static Future<bool> requestPermissions() async {
    return current.requestPermissions();
  }

  /// Get system information
  static Future<SystemInfo> getSystemInfo() async {
    return current.getSystemInfo();
  }

  // Abstract methods to be implemented by platform-specific classes
  Future<PermissionStatus> checkPermissions();
  Future<bool> requestPermissions();
  Future<SystemInfo> getSystemInfo();

  /// Start keyboard monitoring
  Stream<KeystrokeEvent> startKeyboardMonitoring();

  /// Start mouse monitoring
  Stream<MouseEvent> startMouseMonitoring();

  /// Start window monitoring
  Stream<WindowEvent> startWindowMonitoring();

  /// Get active window information
  Future<WindowEvent?> getActiveWindow();

  /// Stop all monitoring
  Future<void> stopMonitoring();
}

/// macOS-specific implementation using FFI
class MacOSPlatform extends PlatformInterface {
  StreamController<KeystrokeEvent>? _keyboardController;
  StreamController<MouseEvent>? _mouseController;
  StreamController<WindowEvent>? _windowController;

  @override
  Future<PermissionStatus> checkPermissions() async {
    // Simulate permission check using process execution
    // In a real implementation, this would use FFI to call Accessibility APIs
    try {
      final result = await Process.run('which', ['osascript']);
      final accessibility = result.exitCode == 0;

      return PermissionStatus(
        accessibility: accessibility,
        inputMonitoring: accessibility, // Simplified check
        screenRecording: true, // Optional
      );
    } catch (e) {
      return const PermissionStatus(
        accessibility: false,
        inputMonitoring: false,
        screenRecording: false,
      );
    }
  }

  @override
  Future<bool> requestPermissions() async {
    print('Please grant accessibility permissions in System Preferences:');
    print('1. Open System Preferences > Security & Privacy > Privacy');
    print('2. Select "Accessibility" from the left panel');
    print('3. Click the lock and enter your password');
    print('4. Add this application to the list');
    print('');
    print('Press Enter when permissions are granted...');

    stdin.readLineSync();
    return true;
  }

  @override
  Future<SystemInfo> getSystemInfo() async {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;

    // Get architecture using uname
    ProcessResult? archResult;
    try {
      archResult = await Process.run('uname', ['-m']);
    } catch (e) {
      // Fallback if uname is not available
    }

    final architecture = archResult?.exitCode == 0
        ? (archResult!.stdout as String).trim()
        : 'unknown';

    return SystemInfo(
      platform: platform,
      architecture: architecture,
      version: version,
      environment: Platform.environment,
    );
  }

  @override
  Stream<KeystrokeEvent> startKeyboardMonitoring() {
    _keyboardController ??= StreamController<KeystrokeEvent>.broadcast();

    // Simulate keyboard events for demonstration
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_keyboardController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = KeystrokeEvent(
        timestamp: DateTime.now(),
        key: 'simulated_key',
        modifiers: const ['none'],
        windowId: 1,
        encrypted: false,
      );

      _keyboardController?.add(event);
    });

    return _keyboardController!.stream;
  }

  @override
  Stream<MouseEvent> startMouseMonitoring() {
    _mouseController ??= StreamController<MouseEvent>.broadcast();

    // Simulate mouse events
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_mouseController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = MouseEvent(
        timestamp: DateTime.now(),
        type: MouseEventType.click,
        x: 100,
        y: 200,
        button: 'left',
        windowId: 1,
      );

      _mouseController?.add(event);
    });

    return _mouseController!.stream;
  }

  @override
  Stream<WindowEvent> startWindowMonitoring() {
    _windowController ??= StreamController<WindowEvent>.broadcast();

    // Simulate window events
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_windowController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = WindowEvent(
        timestamp: DateTime.now(),
        title: 'Sample Window',
        appName: 'Sample App',
        bundleId: 'com.example.app',
        pid: 12345,
        geometry: const WindowGeometry(x: 0, y: 0, width: 800, height: 600),
      );

      _windowController?.add(event);
    });

    return _windowController!.stream;
  }

  @override
  Future<WindowEvent?> getActiveWindow() async {
    // In a real implementation, this would use Accessibility APIs
    return WindowEvent(
      timestamp: DateTime.now(),
      title: 'Active Window',
      appName: 'Current App',
      bundleId: 'com.example.current',
      pid: 67890,
      geometry: const WindowGeometry(x: 100, y: 100, width: 1000, height: 700),
    );
  }

  @override
  Future<void> stopMonitoring() async {
    await _keyboardController?.close();
    await _mouseController?.close();
    await _windowController?.close();

    _keyboardController = null;
    _mouseController = null;
    _windowController = null;
  }
}

/// Linux-specific implementation
class LinuxPlatform extends PlatformInterface {
  StreamController<KeystrokeEvent>? _keyboardController;
  StreamController<MouseEvent>? _mouseController;
  StreamController<WindowEvent>? _windowController;

  @override
  Future<PermissionStatus> checkPermissions() async {
    // Check for X11/Wayland environment
    final hasDisplay = Platform.environment.containsKey('DISPLAY') ||
        Platform.environment.containsKey('WAYLAND_DISPLAY');

    // Check input group membership (simplified)
    bool hasInputAccess = false;
    try {
      final result = await Process.run('groups', []);
      if (result.exitCode == 0) {
        final groups = result.stdout as String;
        hasInputAccess = groups.contains('input');
      }
    } catch (e) {
      hasInputAccess = false;
    }

    return PermissionStatus(
      accessibility: hasDisplay,
      inputMonitoring: hasInputAccess,
      screenRecording: true,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    print('For full functionality on Linux, you may need to:');
    print('1. Add your user to the "input" group: sudo usermod -a -G input \$USER');
    print('2. Restart your session or run: newgrp input');
    print('3. Ensure you\'re running in X11 or Wayland environment');
    print('');
    return true;
  }

  @override
  Future<SystemInfo> getSystemInfo() async {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;

    // Get distribution info
    String distribution = 'Unknown Linux';
    try {
      final file = File('/etc/os-release');
      if (await file.exists()) {
        final content = await file.readAsString();
        final match = RegExp(r'PRETTY_NAME="([^"]*)"').firstMatch(content);
        if (match != null) {
          distribution = match.group(1) ?? distribution;
        }
      }
    } catch (e) {
      // Keep default
    }

    // Get architecture
    String architecture = 'unknown';
    try {
      final result = await Process.run('uname', ['-m']);
      if (result.exitCode == 0) {
        architecture = (result.stdout as String).trim();
      }
    } catch (e) {
      // Keep default
    }

    return SystemInfo(
      platform: platform,
      architecture: architecture,
      version: '$distribution ($version)',
      environment: Platform.environment,
    );
  }

  @override
  Stream<KeystrokeEvent> startKeyboardMonitoring() {
    _keyboardController ??= StreamController<KeystrokeEvent>.broadcast();

    // Linux implementation would use X11/Wayland APIs
    // For now, simulate events
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_keyboardController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = KeystrokeEvent(
        timestamp: DateTime.now(),
        key: 'linux_key',
        modifiers: const ['ctrl'],
        windowId: 2,
        encrypted: false,
      );

      _keyboardController?.add(event);
    });

    return _keyboardController!.stream;
  }

  @override
  Stream<MouseEvent> startMouseMonitoring() {
    _mouseController ??= StreamController<MouseEvent>.broadcast();

    Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_mouseController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = MouseEvent(
        timestamp: DateTime.now(),
        type: MouseEventType.move,
        x: 300,
        y: 400,
        windowId: 2,
      );

      _mouseController?.add(event);
    });

    return _mouseController!.stream;
  }

  @override
  Stream<WindowEvent> startWindowMonitoring() {
    _windowController ??= StreamController<WindowEvent>.broadcast();

    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_windowController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = WindowEvent(
        timestamp: DateTime.now(),
        title: 'Linux Window',
        appName: 'Linux App',
        pid: 54321,
        geometry: const WindowGeometry(x: 50, y: 50, width: 900, height: 500),
      );

      _windowController?.add(event);
    });

    return _windowController!.stream;
  }

  @override
  Future<WindowEvent?> getActiveWindow() async {
    return WindowEvent(
      timestamp: DateTime.now(),
      title: 'Active Linux Window',
      appName: 'Current Linux App',
      pid: 98765,
      geometry: const WindowGeometry(x: 200, y: 150, width: 1200, height: 800),
    );
  }

  @override
  Future<void> stopMonitoring() async {
    await _keyboardController?.close();
    await _mouseController?.close();
    await _windowController?.close();

    _keyboardController = null;
    _mouseController = null;
    _windowController = null;
  }
}

/// Windows-specific implementation
class WindowsPlatform extends PlatformInterface {
  StreamController<KeystrokeEvent>? _keyboardController;
  StreamController<MouseEvent>? _mouseController;
  StreamController<WindowEvent>? _windowController;

  @override
  Future<PermissionStatus> checkPermissions() async {
    // Windows generally doesn't require special permissions for monitoring
    return const PermissionStatus(
      accessibility: true,
      inputMonitoring: true,
      screenRecording: true,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    print('Windows monitoring should work without additional permissions.');
    print('If you encounter issues, try running as Administrator.');
    return true;
  }

  @override
  Future<SystemInfo> getSystemInfo() async {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    final architecture = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'unknown';

    return SystemInfo(
      platform: platform,
      architecture: architecture,
      version: version,
      environment: Platform.environment,
    );
  }

  @override
  Stream<KeystrokeEvent> startKeyboardMonitoring() {
    _keyboardController ??= StreamController<KeystrokeEvent>.broadcast();

    // Windows implementation would use Windows API
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_keyboardController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = KeystrokeEvent(
        timestamp: DateTime.now(),
        key: 'windows_key',
        modifiers: const ['alt'],
        windowId: 3,
        encrypted: false,
      );

      _keyboardController?.add(event);
    });

    return _keyboardController!.stream;
  }

  @override
  Stream<MouseEvent> startMouseMonitoring() {
    _mouseController ??= StreamController<MouseEvent>.broadcast();

    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_mouseController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = MouseEvent(
        timestamp: DateTime.now(),
        type: MouseEventType.scroll,
        x: 500,
        y: 300,
        button: 'wheel',
        windowId: 3,
      );

      _mouseController?.add(event);
    });

    return _mouseController!.stream;
  }

  @override
  Stream<WindowEvent> startWindowMonitoring() {
    _windowController ??= StreamController<WindowEvent>.broadcast();

    Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_windowController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      final event = WindowEvent(
        timestamp: DateTime.now(),
        title: 'Windows Window',
        appName: 'Windows App',
        pid: 11111,
        geometry: const WindowGeometry(x: 150, y: 100, width: 1000, height: 600),
      );

      _windowController?.add(event);
    });

    return _windowController!.stream;
  }

  @override
  Future<WindowEvent?> getActiveWindow() async {
    return WindowEvent(
      timestamp: DateTime.now(),
      title: 'Active Windows Window',
      appName: 'Current Windows App',
      pid: 22222,
      geometry: const WindowGeometry(x: 300, y: 200, width: 1100, height: 750),
    );
  }

  @override
  Future<void> stopMonitoring() async {
    await _keyboardController?.close();
    await _mouseController?.close();
    await _windowController?.close();

    _keyboardController = null;
    _mouseController = null;
    _windowController = null;
  }
}

/// Fallback implementation for unsupported platforms
class FallbackPlatform extends PlatformInterface {
  @override
  Future<PermissionStatus> checkPermissions() async {
    return const PermissionStatus(
      accessibility: false,
      inputMonitoring: false,
      screenRecording: false,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    print('Platform not supported for activity monitoring.');
    return false;
  }

  @override
  Future<SystemInfo> getSystemInfo() async {
    return SystemInfo(
      platform: Platform.operatingSystem,
      architecture: 'unknown',
      version: Platform.operatingSystemVersion,
      environment: Platform.environment,
    );
  }

  @override
  Stream<KeystrokeEvent> startKeyboardMonitoring() {
    return const Stream.empty();
  }

  @override
  Stream<MouseEvent> startMouseMonitoring() {
    return const Stream.empty();
  }

  @override
  Stream<WindowEvent> startWindowMonitoring() {
    return const Stream.empty();
  }

  @override
  Future<WindowEvent?> getActiveWindow() async {
    return null;
  }

  @override
  Future<void> stopMonitoring() async {
    // Nothing to stop
  }
}