import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/startup/startup_policy.dart';

void main() {
  group('buildStartupPolicy', () {
    test('uses the full blocking startup path when fast start is disabled', () {
      final policy = buildStartupPolicy(fastStartEnabled: false);

      expect(policy.fastStartEnabled, isFalse);
      expect(policy.postLaunchDelay, Duration.zero);
      expect(policy.runPostLaunchTasksSequentially, isFalse);
      expect(
        policy.blockingTaskGroups
            .expand((group) => group)
            .map((task) => task.name)
            .toList(),
        [
          'Firebase.initializeApp',
          'AppCheckService.initialize',
          'CrashReportingService.initialize',
          'PerformanceMonitor.initialize',
          'AppUpdateService.initialize',
          'FirebaseMessaging.onBackgroundMessage',
          'ConsentService.initialize',
          'GradualRolloutService.initialize',
        ],
      );
      expect(policy.postLaunchTasks.map((task) => task.name).toList(), [
        'CrushDI.initializePlatformServices',
        'TrackingConsentService.requestConsent',
        'PushNotificationService.initialize',
      ]);
    });

    test(
      'defers non-critical work and skips permission prompts in fast start',
      () {
        final policy = buildStartupPolicy(fastStartEnabled: true);
        final blockingTaskNames = policy.blockingTaskGroups
            .expand((group) => group)
            .map((task) => task.name)
            .toList();
        final postLaunchTaskNames = policy.postLaunchTasks
            .map((task) => task.name)
            .toList();

        expect(policy.fastStartEnabled, isTrue);
        expect(policy.postLaunchDelay, const Duration(seconds: 2));
        expect(policy.runPostLaunchTasksSequentially, isTrue);
        expect(blockingTaskNames, [
          'Firebase.initializeApp',
          'ConsentService.initialize',
        ]);
        expect(postLaunchTaskNames, [
          'AppCheckService.initialize',
          'CrashReportingService.initialize',
          'PerformanceMonitor.initialize',
          'AppUpdateService.initialize',
          'FirebaseMessaging.onBackgroundMessage',
          'GradualRolloutService.initialize',
          'CrushDI.initializePlatformServices',
        ]);
        expect(
          postLaunchTaskNames,
          isNot(
            containsAll([
              'TrackingConsentService.requestConsent',
              'PushNotificationService.initialize',
            ]),
          ),
        );
      },
    );
  });
}
