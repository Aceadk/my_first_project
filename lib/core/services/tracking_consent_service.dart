import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/core/app_logger.dart';

enum TrackingStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  notSupported,
}

typedef IsIosPlatform = bool Function();
typedef TrackingStatusProvider = Future<TrackingStatus> Function();
typedef TrackingAuthorizationRequester = Future<TrackingStatus> Function();
typedef AnalyticsCollectionSetter = Future<void> Function(bool enabled);

/// Manages App Tracking Transparency (ATT) consent on iOS.
///
/// On iOS 14.5+, apps must request permission before collecting IDFA.
/// This service handles the ATT prompt and adjusts Firebase Analytics
/// data collection based on the user's response.
class TrackingConsentService {
  TrackingConsentService({
    IsIosPlatform? isIosPlatform,
    TrackingStatusProvider? trackingStatusProvider,
    TrackingAuthorizationRequester? trackingAuthorizationRequester,
    AnalyticsCollectionSetter? analyticsCollectionSetter,
  }) : _isIosPlatform = isIosPlatform ?? _defaultIsIosPlatform,
       _trackingStatusProvider =
           trackingStatusProvider ?? _defaultTrackingStatusProvider,
       _trackingAuthorizationRequester =
           trackingAuthorizationRequester ?? _defaultTrackingRequester,
       _analyticsCollectionSetter =
           analyticsCollectionSetter ?? _defaultAnalyticsCollectionSetter;

  TrackingConsentService._singleton() : this();
  static final TrackingConsentService instance =
      TrackingConsentService._singleton();

  static bool _defaultIsIosPlatform() => Platform.isIOS;

  static const MethodChannel _trackingChannel = MethodChannel(
    'app_tracking_transparency',
  );

  static Future<TrackingStatus> _defaultTrackingStatusProvider() async {
    final status = await _trackingChannel.invokeMethod<int>(
      'getTrackingAuthorizationStatus',
    );
    return _trackingStatusFromIndex(status);
  }

  static Future<TrackingStatus> _defaultTrackingRequester() async {
    final status = await _trackingChannel.invokeMethod<int>(
      'requestTrackingAuthorization',
    );
    return _trackingStatusFromIndex(status);
  }

  static Future<void> _defaultAnalyticsCollectionSetter(bool enabled) {
    return FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }

  static TrackingStatus _trackingStatusFromIndex(int? statusIndex) {
    if (statusIndex == null ||
        statusIndex < 0 ||
        statusIndex >= TrackingStatus.values.length) {
      return TrackingStatus.notSupported;
    }
    return TrackingStatus.values[statusIndex];
  }

  final IsIosPlatform _isIosPlatform;
  final TrackingStatusProvider _trackingStatusProvider;
  final TrackingAuthorizationRequester _trackingAuthorizationRequester;
  final AnalyticsCollectionSetter _analyticsCollectionSetter;

  TrackingStatus _status = TrackingStatus.notDetermined;

  /// Current ATT status.
  TrackingStatus get status => _status;

  /// Whether the user has granted tracking permission.
  bool get isAuthorized => _status == TrackingStatus.authorized;

  /// Request ATT consent on iOS. No-op on other platforms.
  ///
  /// Call this after the app has launched and the user can see the dialog.
  /// Do NOT call during splash screen — Apple may reject apps that show
  /// the ATT prompt before the user has context.
  Future<void> requestConsent() async {
    if (!_isIosPlatform()) return;

    try {
      // Check current status first
      _status = await _trackingStatusProvider();

      if (_status == TrackingStatus.notDetermined) {
        // Show the ATT dialog
        _status = await _trackingAuthorizationRequester();
      }

      // Adjust Firebase Analytics based on consent
      await _applyConsentToAnalytics();
    } catch (e, stackTrace) {
      AppLogger.error(
        'TrackingConsentService: ATT request failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Default to limited data collection if ATT fails
      await _setAnalyticsCollectionSafely(
        false,
        reason: 'fallback-after-att-error',
      );
    }
  }

  /// Check current ATT status without showing a dialog.
  Future<TrackingStatus> checkStatus() async {
    if (!_isIosPlatform()) return TrackingStatus.authorized;
    _status = await _trackingStatusProvider();
    return _status;
  }

  Future<void> _applyConsentToAnalytics() async {
    final enabled = _status == TrackingStatus.authorized;
    await _setAnalyticsCollectionSafely(enabled, reason: 'apply-att-consent');

    if (kDebugMode) {
      AppLogger.debug(
        'TrackingConsentService: ATT status=$_status, '
        'analytics collection=${enabled ? "enabled" : "disabled"}',
      );
    }
  }

  Future<void> _setAnalyticsCollectionSafely(
    bool enabled, {
    required String reason,
  }) async {
    try {
      await _analyticsCollectionSetter(enabled);
    } catch (e, stackTrace) {
      AppLogger.error(
        'TrackingConsentService: Failed to set analytics collection '
        '(enabled=$enabled, reason=$reason)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
