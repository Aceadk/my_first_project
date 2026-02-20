import 'dart:io';

import 'package:crushhour/core/app_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for managing app updates and version checking.
///
/// Features:
/// - Check current app version against minimum required version
/// - Detect if forced update is required
/// - Handle app store redirects for updates
/// - Version comparison utilities
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  PackageInfo? _packageInfo;
  bool _isInitialized = false;

  // Store URLs - Update these once your app is published to the stores
  // iOS: Replace 'id000000000' with your actual App Store ID after submission
  // Android: Package ID is 'com.ace.crush' (matches build.gradle.kts)
  static const String _appStoreUrl =
      'https://apps.apple.com/app/crushhour/id000000000';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ace.crush';

  /// Initialize the service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _isInitialized = true;
      AppLogger.debug(
        'AppUpdateService: Initialized - version ${_packageInfo?.version}',
      );
    } catch (e) {
      AppLogger.error('AppUpdateService: Failed to initialize - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION INFO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the current app version (e.g., "1.2.3").
  String get currentVersion => _packageInfo?.version ?? '0.0.0';

  /// Get the current build number (e.g., "42").
  String get buildNumber => _packageInfo?.buildNumber ?? '0';

  /// Get the full version string (e.g., "1.2.3+42").
  String get fullVersion => '$currentVersion+$buildNumber';

  /// Get the app name.
  String get appName => _packageInfo?.appName ?? 'Crush';

  /// Get the package name.
  String get packageName => _packageInfo?.packageName ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION CHECKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if the current version meets the minimum required version.
  ///
  /// Returns an [UpdateCheckResult] with the status and details.
  UpdateCheckResult checkVersion({
    required String minVersion,
    String? latestVersion,
    bool forceUpdate = false,
    String? updateMessage,
  }) {
    final current = _parseVersion(currentVersion);
    final minimum = _parseVersion(minVersion);
    final latest = latestVersion != null ? _parseVersion(latestVersion) : null;

    final meetsMinimum = _compareVersions(current, minimum) >= 0;
    final isLatest = latest == null || _compareVersions(current, latest) >= 0;

    if (!meetsMinimum && forceUpdate) {
      return UpdateCheckResult(
        status: UpdateStatus.forceUpdate,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        message: updateMessage ?? 'Please update the app to continue.',
      );
    }

    if (!meetsMinimum) {
      return UpdateCheckResult(
        status: UpdateStatus.updateRequired,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        message: updateMessage ?? 'A new version is available.',
      );
    }

    if (!isLatest) {
      return UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        message: updateMessage ?? 'A new version is available.',
      );
    }

    return UpdateCheckResult(
      status: UpdateStatus.upToDate,
      currentVersion: currentVersion,
      minVersion: minVersion,
      latestVersion: latestVersion,
    );
  }

  /// Compare two version strings.
  /// Returns: negative if v1 < v2, 0 if equal, positive if v1 > v2.
  int compareVersions(String v1, String v2) {
    return _compareVersions(_parseVersion(v1), _parseVersion(v2));
  }

  List<int> _parseVersion(String version) {
    // Remove any prefix like 'v' and split by '.'
    final cleaned = version.replaceFirst(RegExp(r'^v'), '');
    return cleaned.split('.').map((part) {
      // Handle versions like "1.2.3-beta.1" by taking only the numeric part
      final match = RegExp(r'^\d+').firstMatch(part);
      return match != null ? int.parse(match.group(0)!) : 0;
    }).toList();
  }

  int _compareVersions(List<int> v1, List<int> v2) {
    final maxLength = v1.length > v2.length ? v1.length : v2.length;

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < v1.length ? v1[i] : 0;
      final part2 = i < v2.length ? v2[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORE NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the appropriate store URL for the current platform.
  String get storeUrl {
    if (Platform.isIOS) return _appStoreUrl;
    if (Platform.isAndroid) return _playStoreUrl;
    return _playStoreUrl; // Default to Play Store
  }

  /// Open the app store page for updating.
  Future<bool> openStore() async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      AppLogger.error('AppUpdateService: Failed to open store - $e');
      return false;
    }
  }

  /// Check if the service is initialized.
  bool get isInitialized => _isInitialized;
}

/// Result of a version check.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    required this.minVersion,
    this.latestVersion,
    this.message,
  });

  final UpdateStatus status;
  final String currentVersion;
  final String minVersion;
  final String? latestVersion;
  final String? message;

  bool get requiresUpdate =>
      status == UpdateStatus.forceUpdate ||
      status == UpdateStatus.updateRequired;

  bool get isForced => status == UpdateStatus.forceUpdate;

  @override
  String toString() {
    return 'UpdateCheckResult(status: $status, current: $currentVersion, min: $minVersion)';
  }
}

/// Update status enum.
enum UpdateStatus {
  /// App is up to date.
  upToDate,

  /// An update is available but not required.
  updateAvailable,

  /// An update is required but can be dismissed.
  updateRequired,

  /// An update is required and the app cannot continue without it.
  forceUpdate,
}

/// Extension for easy version checking from feature flags.
extension AppUpdateServiceExtension on AppUpdateService {
  /// Check version using feature flag values.
  UpdateCheckResult checkWithFeatureFlags({
    required String minAppVersion,
    required bool forceUpdate,
    String? forceUpdateMessage,
    String? latestVersion,
  }) {
    return checkVersion(
      minVersion: minAppVersion,
      latestVersion: latestVersion,
      forceUpdate: forceUpdate,
      updateMessage: forceUpdateMessage,
    );
  }
}
