import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';

typedef FileExistsChecker = Future<bool> Function(String path);
typedef DirectoryExistsChecker = Future<bool> Function(String path);
typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);
typedef DebugModeProvider = bool Function();
typedef PlatformFlagProvider = bool Function();
typedef PlatformNameProvider = String Function();
typedef IOSSandboxWriteProbe = Future<bool> Function();

/// Service for detecting jailbroken (iOS) or rooted (Android) devices.
///
/// Detection is informational and non-blocking — the app still functions
/// normally on compromised devices. Results are logged for fraud analytics.
class DeviceIntegrityService {
  DeviceIntegrityService._();

  static bool? _cachedResult;
  static FileExistsChecker _fileExists = _defaultFileExists;
  static DirectoryExistsChecker _directoryExists = _defaultDirectoryExists;
  static ProcessRunner _processRunner = _defaultProcessRunner;
  static DebugModeProvider _isDebugMode = _defaultIsDebugMode;
  static PlatformFlagProvider _isAndroid = _defaultIsAndroid;
  static PlatformFlagProvider _isIOS = _defaultIsIOS;
  static PlatformNameProvider _platformName = _defaultPlatformName;
  static IOSSandboxWriteProbe _iosSandboxWriteProbe =
      _defaultIOSSandboxWriteProbe;

  static Future<bool> _defaultFileExists(String path) => File(path).exists();
  static Future<bool> _defaultDirectoryExists(String path) =>
      Directory(path).exists();
  static Future<ProcessResult> _defaultProcessRunner(
    String executable,
    List<String> arguments,
  ) {
    return Process.run(executable, arguments);
  }

  static bool _defaultIsDebugMode() => kDebugMode;
  static bool _defaultIsAndroid() => Platform.isAndroid;
  static bool _defaultIsIOS() => Platform.isIOS;
  static String _defaultPlatformName() => Platform.operatingSystem;

  static Future<bool> _defaultIOSSandboxWriteProbe() async {
    try {
      final testFile = File('/private/jailbreak_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the last check detected a compromised device.
  static bool get isCompromised => _cachedResult ?? false;

  /// Perform device integrity check. Results are cached for the session.
  ///
  /// Returns `true` if the device appears to be jailbroken/rooted.
  /// Returns `false` on desktop, web, or if detection fails.
  static Future<bool> checkIntegrity() async {
    // Return cached result if already checked this session
    if (_cachedResult != null) return _cachedResult!;

    // Skip detection in debug mode to avoid false positives on emulators
    if (_isDebugMode()) {
      _cachedResult = false;
      return false;
    }

    try {
      if (_isAndroid()) {
        _cachedResult = await _checkAndroid();
      } else if (_isIOS()) {
        _cachedResult = await _checkIOS();
      } else {
        _cachedResult = false;
      }
    } catch (e) {
      AppLogger.error('DeviceIntegrity: Check failed: $e');
      _cachedResult = false;
    }

    if (_cachedResult == true) {
      AppLogger.warning(
        'DeviceIntegrity: Compromised device detected (${_platformName()})',
      );
    }

    return _cachedResult!;
  }

  /// Android root detection heuristics.
  static Future<bool> _checkAndroid() async {
    // Check for common su binary locations
    const suPaths = [
      '/system/app/Superuser.apk',
      '/system/xbin/su',
      '/system/bin/su',
      '/sbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/data/local/su',
      '/su/bin/su',
    ];

    for (final path in suPaths) {
      if (await _fileExists(path)) return true;
    }

    // Check for common root management apps
    const rootIndicators = [
      '/system/app/Superuser.apk',
      '/system/app/SuperSU.apk',
      '/system/app/Magisk.apk',
    ];

    for (final path in rootIndicators) {
      if (await _fileExists(path)) return true;
    }

    // Check build tags for test-keys (indicates custom ROM)
    try {
      final result = await _processRunner('getprop', ['ro.build.tags']);
      final tags = result.stdout.toString().trim();
      if (tags.contains('test-keys')) return true;
    } catch (_) {
      // getprop may not be accessible — not indicative of root
    }

    return false;
  }

  /// iOS jailbreak detection heuristics.
  static Future<bool> _checkIOS() async {
    // Check for common jailbreak file paths
    const jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Applications/Sileo.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
    ];

    for (final path in jailbreakPaths) {
      if (await _fileExists(path)) return true;
    }
    for (final path in jailbreakPaths) {
      if (await _directoryExists(path)) return true;
    }

    // Check if app can write outside its sandbox
    try {
      if (await _iosSandboxWriteProbe()) {
        // If we could write outside sandbox, device is jailbroken
        return true;
      }
    } catch (_) {
      // Expected to fail on non-jailbroken devices
    }

    return false;
  }

  /// Configure test hooks for deterministic unit tests.
  @visibleForTesting
  static void configureForTesting({
    FileExistsChecker? fileExists,
    DirectoryExistsChecker? directoryExists,
    ProcessRunner? processRunner,
    DebugModeProvider? isDebugMode,
    PlatformFlagProvider? isAndroid,
    PlatformFlagProvider? isIOS,
    PlatformNameProvider? platformName,
    IOSSandboxWriteProbe? iosSandboxWriteProbe,
  }) {
    _fileExists = fileExists ?? _defaultFileExists;
    _directoryExists = directoryExists ?? _defaultDirectoryExists;
    _processRunner = processRunner ?? _defaultProcessRunner;
    _isDebugMode = isDebugMode ?? _defaultIsDebugMode;
    _isAndroid = isAndroid ?? _defaultIsAndroid;
    _isIOS = isIOS ?? _defaultIsIOS;
    _platformName = platformName ?? _defaultPlatformName;
    _iosSandboxWriteProbe =
        iosSandboxWriteProbe ?? _defaultIOSSandboxWriteProbe;
  }

  /// Reset service state and test hooks.
  @visibleForTesting
  static void resetForTesting() {
    _cachedResult = null;
    _fileExists = _defaultFileExists;
    _directoryExists = _defaultDirectoryExists;
    _processRunner = _defaultProcessRunner;
    _isDebugMode = _defaultIsDebugMode;
    _isAndroid = _defaultIsAndroid;
    _isIOS = _defaultIsIOS;
    _platformName = _defaultPlatformName;
    _iosSandboxWriteProbe = _defaultIOSSandboxWriteProbe;
  }

  /// Reset cached result (for testing).
  @visibleForTesting
  static void resetCache() {
    _cachedResult = null;
  }
}
