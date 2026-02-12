import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/gradual_rollout_service.dart';
import 'core/services/app_check_service.dart';
import 'core/services/tracking_consent_service.dart';
import 'core/services/consent_service.dart';
import 'core/performance/performance_monitor.dart';

Future<void> main() async {
  // Record app start time immediately for cold start tracking
  PerformanceMonitor.instance.recordAppStartTime();

  // Run the app in a zone that catches errors
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize App Check for device attestation (SECURITY)
    // Must be initialized before any Firebase service calls
    await AppCheckService.instance.initialize();

    // Initialize crash reporting early
    await CrashReportingService.instance.initialize();

    // Initialize performance monitoring
    await PerformanceMonitor.instance.initialize();

    // Start memory monitoring in production
    if (!kDebugMode) {
      PerformanceMonitor.instance.startMemoryMonitoring();
    }

    // Initialize app update service
    await AppUpdateService.instance.initialize();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request App Tracking Transparency consent (iOS only)
    // Must be called before Firebase Analytics starts collecting IDFA
    await TrackingConsentService.instance.requestConsent();

    // Initialize push notifications
    await PushNotificationService.instance.initialize();

    final preferences = await SharedPreferences.getInstance();

    // Initialize GDPR consent service
    await ConsentService.instance.initialize(preferences);

    // Initialize gradual rollout service
    await GradualRolloutService.instance.initialize(preferences);

    runApp(CrushApp(preferences: preferences));

    // Record first frame for cold start measurement
    SchedulerBinding.instance.addPostFrameCallback((_) {
      PerformanceMonitor.instance.recordFirstFrame();
    });
  }, (error, stackTrace) {
    // Report uncaught errors to Crashlytics
    CrashReportingService.instance.recordError(
      error,
      stackTrace,
      reason: 'Uncaught error in main zone',
      fatal: true,
    );
  });
}
