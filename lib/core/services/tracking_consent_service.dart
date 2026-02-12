import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Manages App Tracking Transparency (ATT) consent on iOS.
///
/// On iOS 14.5+, apps must request permission before collecting IDFA.
/// This service handles the ATT prompt and adjusts Firebase Analytics
/// data collection based on the user's response.
class TrackingConsentService {
  TrackingConsentService._();
  static final TrackingConsentService instance = TrackingConsentService._();

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
    if (!Platform.isIOS) return;

    try {
      // Check current status first
      _status = await AppTrackingTransparency.trackingAuthorizationStatus;

      if (_status == TrackingStatus.notDetermined) {
        // Show the ATT dialog
        _status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      // Adjust Firebase Analytics based on consent
      await _applyConsentToAnalytics();
    } catch (e) {
      debugPrint('TrackingConsentService: ATT request failed: $e');
      // Default to limited data collection if ATT fails
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    }
  }

  /// Check current ATT status without showing a dialog.
  Future<TrackingStatus> checkStatus() async {
    if (!Platform.isIOS) return TrackingStatus.authorized;
    _status = await AppTrackingTransparency.trackingAuthorizationStatus;
    return _status;
  }

  Future<void> _applyConsentToAnalytics() async {
    final enabled = _status == TrackingStatus.authorized;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);

    if (kDebugMode) {
      debugPrint(
        'TrackingConsentService: ATT status=$_status, '
        'analytics collection=${enabled ? "enabled" : "disabled"}',
      );
    }
  }
}
