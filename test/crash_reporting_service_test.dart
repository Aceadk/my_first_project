import 'package:crushhour/core/services/crash_reporting_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? originalFlutterOnError;
  late bool Function(Object, StackTrace)? originalPlatformOnError;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
    CrashReportingService.resetInstanceForTesting();
  });

  group('CrashReportingService', () {
    test('initialize configures debug collection and is idempotent', () async {
      final fake = _FakeCrashlyticsClient();
      final service = _buildService(fake: fake, isDebug: true);

      await service.initialize();
      await service.initialize();

      expect(service.isInitialized, isTrue);
      expect(fake.collectionEnabledCalls, <bool>[false]);
      expect(service.isCrashlyticsCollectionEnabled, isFalse);
      expect(service.isDebugMode, isTrue);
    });

    test('initialize configures release collection', () async {
      final fake = _FakeCrashlyticsClient();
      final service = _buildService(fake: fake, isDebug: false);

      await service.initialize();

      expect(fake.collectionEnabledCalls, <bool>[true]);
      expect(service.isDebugMode, isFalse);
    });

    test('recordError returns early when service not initialized', () async {
      final fake = _FakeCrashlyticsClient();
      final service = _buildService(fake: fake, isDebug: false);

      await service.recordError(
        Exception('skip'),
        StackTrace.current,
        reason: 'not-initialized',
      );

      expect(fake.recordedErrors, isEmpty);
      expect(fake.logs, isEmpty);
    });

    test('recordError logs custom keys, reason and fatal flag', () async {
      final fake = _FakeCrashlyticsClient();
      final service = _buildService(fake: fake, isDebug: false);
      await service.initialize();

      await service.recordError(
        Exception('boom'),
        StackTrace.current,
        reason: 'unit-test',
        fatal: true,
        information: const <String, dynamic>{
          'feature': 'crash_reporting',
          'flow': 2,
        },
      );

      expect(fake.customKeys['feature'], 'crash_reporting');
      expect(fake.customKeys['flow'], '2');
      expect(fake.logs, contains('Error reason: unit-test'));
      expect(fake.recordedErrors, hasLength(1));
      expect(fake.recordedErrors.single.fatal, isTrue);
      expect(fake.recordedErrors.single.reason, 'unit-test');
    });

    test(
      'recordFlutterError, user ID, keys and logs use crash client',
      () async {
        final fake = _FakeCrashlyticsClient();
        final service = _buildService(fake: fake, isDebug: false);
        await service.initialize();

        await service.recordFlutterError(
          FlutterErrorDetails(exception: Exception('flutter')),
        );
        await service.setUserId('user-1');
        await service.clearUserId();
        await service.setCustomKey('build', 'test');
        await service.setCustomKeys(const <String, String>{
          'channel': 'unit',
          'target': 'service',
        });
        await service.log('hello');
        await service.logNavigation('home', 'settings');
        await service.logUserAction('tap', params: const {'id': 'save'});
        await service.logUserAction('swipe');
        await service.logApiCall('/v1/messages', statusCode: 200);
        await service.logApiCall('/v1/messages', error: 'timeout');
        await service.logApiCall('/v1/messages');

        expect(fake.flutterErrors, hasLength(1));
        expect(fake.userIdentifiers, <String>['user-1', '']);
        expect(fake.customKeys['build'], 'test');
        expect(fake.customKeys['channel'], 'unit');
        expect(fake.customKeys['target'], 'service');
        expect(
          fake.logs,
          containsAll(<String>[
            'hello',
            'Navigation: home -> settings',
            'User action: tap (id=save)',
            'User action: swipe',
            'API: /v1/messages - 200',
            'API Error: /v1/messages - timeout',
            'API: /v1/messages',
          ]),
        );
      },
    );

    test('service methods swallow underlying crash client errors', () async {
      final fake = _FakeCrashlyticsClient()
        ..throwOnRecordError = true
        ..throwOnRecordFlutterError = true
        ..throwOnSetUserIdentifier = true
        ..throwOnSetCustomKey = true
        ..throwOnLog = true;
      final service = _buildService(fake: fake, isDebug: false);
      await service.initialize();

      await service.recordError(Exception('x'), StackTrace.current);
      await service.recordFlutterError(
        FlutterErrorDetails(exception: Exception('x')),
      );
      await service.setUserId('user');
      await service.clearUserId();
      await service.setCustomKey('k', 'v');
      await service.setCustomKeys(const <String, String>{'a': '1', 'b': '2'});
      await service.log('msg');
    });

    test(
      'Flutter and platform error handlers use release crash paths',
      () async {
        final fake = _FakeCrashlyticsClient();
        final service = _buildService(fake: fake, isDebug: false);
        await service.initialize();

        FlutterError.onError!(
          FlutterErrorDetails(exception: Exception('flutter')),
        );
        expect(fake.flutterFatalErrors, hasLength(1));

        final handled = PlatformDispatcher.instance.onError!(
          Exception('platform'),
          StackTrace.current,
        );
        expect(handled, isTrue);
        expect(fake.recordedErrors, hasLength(1));
        expect(fake.recordedErrors.single.fatal, isTrue);
      },
    );

    test(
      'Flutter and platform error handlers avoid crash calls in debug',
      () async {
        final fake = _FakeCrashlyticsClient();
        final service = _buildService(fake: fake, isDebug: true);
        await service.initialize();

        FlutterError.onError!(
          FlutterErrorDetails(exception: Exception('flutter')),
        );
        PlatformDispatcher.instance.onError!(
          Exception('platform'),
          StackTrace.current,
        );

        expect(fake.flutterFatalErrors, isEmpty);
        expect(fake.recordedErrors, isEmpty);
      },
    );

    test('testCrash respects debug/release mode', () {
      final debugFake = _FakeCrashlyticsClient();
      final debugService = _buildService(fake: debugFake, isDebug: true);
      debugService.testCrash();
      expect(debugFake.crashCalls, 0);

      final releaseFake = _FakeCrashlyticsClient();
      final releaseService = _buildService(fake: releaseFake, isDebug: false);
      releaseService.testCrash();
      expect(releaseFake.crashCalls, 1);
    });

    test('setCrashlyticsCollectionEnabled forwards to crash client', () async {
      final fake = _FakeCrashlyticsClient();
      final service = _buildService(fake: fake, isDebug: false);
      await service.initialize();

      await service.setCrashlyticsCollectionEnabled(false);
      await service.setCrashlyticsCollectionEnabled(true);

      expect(fake.collectionEnabledCalls, <bool>[true, false, true]);
      expect(service.isCrashlyticsCollectionEnabled, isTrue);
    });
  });

  group('CrashReporting extension and zone handler', () {
    test('reportError extension uses configured singleton service', () async {
      final fake = _FakeCrashlyticsClient();
      final service = _buildService(fake: fake, isDebug: false);
      await service.initialize();
      CrashReportingService.setInstanceForTesting(service);

      await StateError('from-extension').reportError(
        stackTrace: StackTrace.current,
        reason: 'extension-test',
        fatal: true,
      );

      expect(fake.recordedErrors, hasLength(1));
      expect(fake.recordedErrors.single.reason, 'extension-test');
      expect(fake.recordedErrors.single.fatal, isTrue);
    });

    test(
      'crashlyticsErrorHandler follows singleton debug/release branch',
      () async {
        final debugFake = _FakeCrashlyticsClient();
        final debugService = _buildService(fake: debugFake, isDebug: true);
        await debugService.initialize();
        CrashReportingService.setInstanceForTesting(debugService);

        crashlyticsErrorHandler(Exception('debug-zone'), StackTrace.current);
        await Future<void>.delayed(Duration.zero);
        expect(debugFake.recordedErrors, isEmpty);

        final releaseFake = _FakeCrashlyticsClient();
        final releaseService = _buildService(fake: releaseFake, isDebug: false);
        await releaseService.initialize();
        CrashReportingService.setInstanceForTesting(releaseService);

        crashlyticsErrorHandler(Exception('release-zone'), StackTrace.current);
        await Future<void>.delayed(Duration.zero);
        expect(releaseFake.recordedErrors, hasLength(1));
        expect(releaseFake.recordedErrors.single.fatal, isFalse);
      },
    );
  });
}

CrashReportingService _buildService({
  required _FakeCrashlyticsClient fake,
  required bool isDebug,
}) {
  return CrashReportingService.test(
    crashlytics: fake,
    isDebugMode: () => isDebug,
    addIsolateErrorListener: (_) {},
  );
}

class _FakeCrashlyticsClient implements CrashlyticsClient {
  final List<bool> collectionEnabledCalls = <bool>[];
  final List<_RecordedError> recordedErrors = <_RecordedError>[];
  final List<FlutterErrorDetails> flutterErrors = <FlutterErrorDetails>[];
  final List<FlutterErrorDetails> flutterFatalErrors = <FlutterErrorDetails>[];
  final List<String> userIdentifiers = <String>[];
  final Map<String, String> customKeys = <String, String>{};
  final List<String> logs = <String>[];
  int crashCalls = 0;
  bool _collectionEnabled = false;

  bool throwOnRecordError = false;
  bool throwOnRecordFlutterError = false;
  bool throwOnSetUserIdentifier = false;
  bool throwOnSetCustomKey = false;
  bool throwOnLog = false;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    collectionEnabledCalls.add(enabled);
    _collectionEnabled = enabled;
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (throwOnRecordError) {
      throw Exception('recordError failed');
    }
    recordedErrors.add(
      _RecordedError(
        exception: exception,
        stackTrace: stackTrace,
        reason: reason,
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (throwOnRecordFlutterError) {
      throw Exception('recordFlutterError failed');
    }
    flutterErrors.add(details);
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    flutterFatalErrors.add(details);
  }

  @override
  Future<void> setUserIdentifier(String userId) async {
    if (throwOnSetUserIdentifier) {
      throw Exception('setUserIdentifier failed');
    }
    userIdentifiers.add(userId);
  }

  @override
  Future<void> setCustomKey(String key, String value) async {
    if (throwOnSetCustomKey) {
      throw Exception('setCustomKey failed');
    }
    customKeys[key] = value;
  }

  @override
  Future<void> log(String message) async {
    if (throwOnLog) {
      throw Exception('log failed');
    }
    logs.add(message);
  }

  @override
  void crash() {
    crashCalls += 1;
  }

  @override
  bool get isCrashlyticsCollectionEnabled => _collectionEnabled;
}

class _RecordedError {
  _RecordedError({
    required this.exception,
    required this.stackTrace,
    required this.reason,
    required this.fatal,
  });

  final dynamic exception;
  final StackTrace? stackTrace;
  final String? reason;
  final bool fatal;
}
