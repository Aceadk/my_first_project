import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';

/// Service for detecting jailbroken (iOS) or rooted (Android) devices.
///
/// Detection is informational and non-blocking — the app still functions
/// normally on compromised devices. Results are logged for fraud analytics.
class DeviceIntegrityService {
  DeviceIntegrityService._();

  static bool? _cachedResult;

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
    if (kDebugMode) {
      _cachedResult = false;
      return false;
    }

    try {
      if (Platform.isAndroid) {
        _cachedResult = await _checkAndroid();
      } else if (Platform.isIOS) {
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
        'DeviceIntegrity: Compromised device detected (${Platform.operatingSystem})',
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
      if (await File(path).exists()) return true;
    }

    // Check for common root management apps
    const rootIndicators = [
      '/system/app/Superuser.apk',
      '/system/app/SuperSU.apk',
      '/system/app/Magisk.apk',
    ];

    for (final path in rootIndicators) {
      if (await File(path).exists()) return true;
    }

    // Check build tags for test-keys (indicates custom ROM)
    try {
      final result = await Process.run('getprop', ['ro.build.tags']);
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
      if (await File(path).exists()) return true;
    }
    for (final path in jailbreakPaths) {
      if (await Directory(path).exists()) return true;
    }

    // Check if app can write outside its sandbox
    try {
      final testFile = File('/private/jailbreak_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      // If we could write outside sandbox, device is jailbroken
      return true;
    } catch (_) {
      // Expected to fail on non-jailbroken devices
    }

    return false;
  }

  /// Reset cached result (for testing).
  @visibleForTesting
  static void resetCache() {
    _cachedResult = null;
  }
}
