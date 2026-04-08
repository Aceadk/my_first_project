typedef StartupAction = Future<void> Function();

enum StartupTaskId {
  firebaseInitializeApp,
  appCheckInitialize,
  crashReportingInitialize,
  performanceInitialize,
  appUpdateInitialize,
  firebaseMessagingBackgroundHandler,
  consentInitialize,
  gradualRolloutInitialize,
  platformServicesInitialize,
  trackingConsentRequest,
  pushNotificationsInitialize,
}

class StartupTaskDefinition {
  const StartupTaskDefinition({
    required this.id,
    required this.name,
    this.timeout = const Duration(seconds: 10),
    this.critical = false,
    this.failureMessage,
  });

  final StartupTaskId id;
  final String name;
  final Duration timeout;
  final bool critical;
  final String? failureMessage;
}

class StartupPolicy {
  const StartupPolicy({
    required this.fastStartEnabled,
    required this.blockingTaskGroups,
    required this.postLaunchTasks,
    required this.postLaunchDelay,
    required this.runPostLaunchTasksSequentially,
  });

  final bool fastStartEnabled;
  final List<List<StartupTaskDefinition>> blockingTaskGroups;
  final List<StartupTaskDefinition> postLaunchTasks;
  final Duration postLaunchDelay;
  final bool runPostLaunchTasksSequentially;
}

StartupPolicy buildStartupPolicy({required bool fastStartEnabled}) {
  const firebaseTask = StartupTaskDefinition(
    id: StartupTaskId.firebaseInitializeApp,
    name: 'Firebase.initializeApp',
    timeout: Duration(seconds: 15),
    critical: true,
    failureMessage:
        'Unable to connect secure app services. Check your network and try again.',
  );
  const appCheckTask = StartupTaskDefinition(
    id: StartupTaskId.appCheckInitialize,
    name: 'AppCheckService.initialize',
  );
  const crashReportingTask = StartupTaskDefinition(
    id: StartupTaskId.crashReportingInitialize,
    name: 'CrashReportingService.initialize',
  );
  const performanceTask = StartupTaskDefinition(
    id: StartupTaskId.performanceInitialize,
    name: 'PerformanceMonitor.initialize',
  );
  const appUpdateTask = StartupTaskDefinition(
    id: StartupTaskId.appUpdateInitialize,
    name: 'AppUpdateService.initialize',
  );
  const firebaseMessagingTask = StartupTaskDefinition(
    id: StartupTaskId.firebaseMessagingBackgroundHandler,
    name: 'FirebaseMessaging.onBackgroundMessage',
  );
  const consentTask = StartupTaskDefinition(
    id: StartupTaskId.consentInitialize,
    name: 'ConsentService.initialize',
  );
  const gradualRolloutTask = StartupTaskDefinition(
    id: StartupTaskId.gradualRolloutInitialize,
    name: 'GradualRolloutService.initialize',
  );
  const platformServicesTask = StartupTaskDefinition(
    id: StartupTaskId.platformServicesInitialize,
    name: 'CrushDI.initializePlatformServices',
    timeout: Duration(seconds: 12),
  );
  const trackingConsentTask = StartupTaskDefinition(
    id: StartupTaskId.trackingConsentRequest,
    name: 'TrackingConsentService.requestConsent',
    timeout: Duration(seconds: 12),
  );
  const pushNotificationsTask = StartupTaskDefinition(
    id: StartupTaskId.pushNotificationsInitialize,
    name: 'PushNotificationService.initialize',
    timeout: Duration(seconds: 15),
  );

  if (fastStartEnabled) {
    return const StartupPolicy(
      fastStartEnabled: true,
      blockingTaskGroups: [
        [firebaseTask, consentTask],
      ],
      postLaunchTasks: [
        appCheckTask,
        crashReportingTask,
        performanceTask,
        appUpdateTask,
        firebaseMessagingTask,
        gradualRolloutTask,
        platformServicesTask,
      ],
      postLaunchDelay: Duration(seconds: 2),
      runPostLaunchTasksSequentially: true,
    );
  }

  return const StartupPolicy(
    fastStartEnabled: false,
    blockingTaskGroups: [
      [firebaseTask],
      [appCheckTask, crashReportingTask, performanceTask],
      [appUpdateTask, firebaseMessagingTask, consentTask, gradualRolloutTask],
    ],
    postLaunchTasks: [
      platformServicesTask,
      trackingConsentTask,
      pushNotificationsTask,
    ],
    postLaunchDelay: Duration.zero,
    runPostLaunchTasksSequentially: false,
  );
}
