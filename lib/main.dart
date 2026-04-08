import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'core/di.dart';
import 'core/app_logger.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/gradual_rollout_service.dart';
import 'core/services/app_check_service.dart';
import 'core/services/tracking_consent_service.dart';
import 'core/services/consent_service.dart';
import 'core/performance/performance_monitor.dart';
import 'core/startup/startup_policy.dart';
import 'core/widgets/error_boundary.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Run the app in a guarded zone so uncaught startup/build errors are reported.
  await runZonedGuarded(
    () async {
      // Record app start time immediately for cold start tracking.
      PerformanceMonitor.instance.recordAppStartTime();

      WidgetsFlutterBinding.ensureInitialized();

      // Replace default red/grey error screen with branded fallback UI.
      installErrorWidgetBuilder();

      runApp(const _StartupBootstrapApp());
    },
    (error, stackTrace) {
      AppLogger.error(
        'Uncaught error in main zone',
        error: error,
        stackTrace: stackTrace,
      );
      CrashReportingService.instance.recordError(
        error,
        stackTrace,
        reason: 'Uncaught error in main zone',
        fatal: true,
      );
    },
  );
}

enum _StartupPhase { loading, ready, failed }

class _StartupBootstrapApp extends StatefulWidget {
  const _StartupBootstrapApp();

  @override
  State<_StartupBootstrapApp> createState() => _StartupBootstrapAppState();
}

class _StartupBootstrapAppState extends State<_StartupBootstrapApp> {
  _StartupPhase _phase = _StartupPhase.loading;
  SharedPreferences? _preferences;
  StartupPolicy? _startupPolicy;
  String? _errorMessage;
  bool _postLaunchTasksScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _phase = _StartupPhase.loading;
        _errorMessage = null;
      });
    }

    final preferences = await _loadSharedPreferences();
    if (!mounted) return;
    if (preferences == null) {
      setState(() {
        _phase = _StartupPhase.failed;
        _errorMessage = 'Unable to load local app settings.';
      });
      return;
    }

    final startupPolicy = _buildStartupPolicy();
    final startupError = await _initializeCoreServices(
      startupPolicy,
      preferences,
    );
    if (!mounted) return;
    if (startupError != null) {
      setState(() {
        _phase = _StartupPhase.failed;
        _errorMessage = startupError;
      });
      return;
    }

    setState(() {
      _preferences = preferences;
      _startupPolicy = startupPolicy;
      _phase = _StartupPhase.ready;
      _errorMessage = null;
    });

    if (_postLaunchTasksScheduled) return;
    _postLaunchTasksScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      PerformanceMonitor.instance.recordFirstFrame();
      final startupPolicy = _startupPolicy;
      if (startupPolicy != null) {
        _schedulePostLaunchTasks(startupPolicy, preferences);
      }
    });
  }

  Future<SharedPreferences?> _loadSharedPreferences() async {
    try {
      return await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 8),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'SharedPreferences initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      await CrashReportingService.instance.recordError(
        error,
        stackTrace,
        reason: 'SharedPreferences initialization failed',
        fatal: true,
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _StartupPhase.ready && _preferences != null) {
      return CrushApp(preferences: _preferences!);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _phase == _StartupPhase.failed
                  ? _StartupFailureContent(
                      message:
                          _errorMessage ??
                          'Crush could not start. Please try again.',
                      onRetry: _bootstrap,
                    )
                  : const _StartupLoadingContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupLoadingContent extends StatelessWidget {
  const _StartupLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: Key('startup_loading_content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Starting Crush...', textAlign: TextAlign.center),
      ],
    );
  }
}

class _StartupFailureContent extends StatelessWidget {
  const _StartupFailureContent({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('startup_failure_content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 40),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            unawaited(onRetry());
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

StartupPolicy _buildStartupPolicy() {
  AppConfig.printConfig();
  return buildStartupPolicy(fastStartEnabled: AppConfig.fastStartEnabled);
}

Map<StartupTaskId, StartupAction> _createStartupActions(
  SharedPreferences preferences,
) {
  return {
    StartupTaskId.firebaseInitializeApp: _initializeFirebase,
    StartupTaskId.appCheckInitialize: AppCheckService.instance.initialize,
    StartupTaskId.crashReportingInitialize:
        CrashReportingService.instance.initialize,
    StartupTaskId.performanceInitialize: PerformanceMonitor.instance.initialize,
    StartupTaskId.appUpdateInitialize: AppUpdateService.instance.initialize,
    StartupTaskId.firebaseMessagingBackgroundHandler: () async {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    },
    StartupTaskId.consentInitialize: () =>
        ConsentService.instance.initialize(preferences),
    StartupTaskId.gradualRolloutInitialize: () =>
        GradualRolloutService.instance.initialize(preferences),
    StartupTaskId.platformServicesInitialize: () =>
        CrushDI.initializePlatformServices(),
    StartupTaskId.trackingConsentRequest: () =>
        TrackingConsentService.instance.requestConsent(),
    StartupTaskId.pushNotificationsInitialize: () =>
        PushNotificationService.instance.initialize(),
  };
}

Future<String?> _initializeCoreServices(
  StartupPolicy startupPolicy,
  SharedPreferences preferences,
) async {
  final actions = _createStartupActions(preferences);
  return _runBlockingStartupGroups(startupPolicy, actions);
}

Future<String?> _runBlockingStartupGroups(
  StartupPolicy startupPolicy,
  Map<StartupTaskId, StartupAction> actions,
) async {
  for (final group in startupPolicy.blockingTaskGroups) {
    final results = await Future.wait(
      group.map((task) {
        final action = actions[task.id];
        if (action == null) {
          throw StateError('No startup action registered for ${task.name}');
        }
        return _runStartupTask(
          name: task.name,
          action: action,
          timeout: task.timeout,
          critical: task.critical,
        );
      }),
    );

    for (var index = 0; index < group.length; index++) {
      final task = group[index];
      if (task.critical && !results[index]) {
        return task.failureMessage ??
            'Unable to connect secure app services. Check your network and try again.';
      }
    }
  }

  if (!kDebugMode) {
    PerformanceMonitor.instance.startMemoryMonitoring();
  }

  return null;
}

void _schedulePostLaunchTasks(
  StartupPolicy startupPolicy,
  SharedPreferences preferences,
) {
  if (startupPolicy.postLaunchTasks.isEmpty) {
    return;
  }

  final actions = _createStartupActions(preferences);

  Future<void> startTasks() async {
    if (startupPolicy.fastStartEnabled) {
      AppLogger.debug(
        'Fast start enabled: running deferred startup tasks after first frame.',
      );
    }
    if (startupPolicy.runPostLaunchTasksSequentially) {
      for (final task in startupPolicy.postLaunchTasks) {
        final action = actions[task.id];
        if (action == null) continue;
        await _runStartupTask(
          name: task.name,
          action: action,
          timeout: task.timeout,
          critical: task.critical,
        );
      }
      return;
    }

    await Future.wait(
      startupPolicy.postLaunchTasks.map((task) {
        final action = actions[task.id];
        if (action == null) {
          throw StateError('No startup action registered for ${task.name}');
        }
        return _runStartupTask(
          name: task.name,
          action: action,
          timeout: task.timeout,
          critical: task.critical,
        );
      }),
    );
  }

  if (startupPolicy.postLaunchDelay == Duration.zero) {
    unawaited(startTasks());
    return;
  }

  unawaited(
    Future<void>.delayed(
      startupPolicy.postLaunchDelay,
    ).then((_) => startTasks()),
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<bool> _runStartupTask({
  required String name,
  required Future<void> Function() action,
  Duration timeout = const Duration(seconds: 10),
  bool critical = false,
}) async {
  try {
    await action().timeout(timeout);
    return true;
  } catch (error, stackTrace) {
    AppLogger.error(
      'Startup task failed: $name',
      error: error,
      stackTrace: stackTrace,
    );
    await CrashReportingService.instance.recordError(
      error,
      stackTrace,
      reason: 'Startup task failed: $name',
      fatal: critical,
    );
    return false;
  }
}
