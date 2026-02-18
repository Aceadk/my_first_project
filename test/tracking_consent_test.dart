import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/services/tracking_consent_service.dart';
import 'mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const attChannel = MethodChannel('app_tracking_transparency');
  const analyticsChannel = MethodChannel(
    'plugins.flutter.io/firebase_analytics',
  );
  const analyticsPigeonSetChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setAnalyticsCollectionEnabled',
  );
  const analyticsPigeonSetBasicChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setAnalyticsCollectionEnabled',
    StandardMessageCodec(),
  );

  late int attStatus;
  late int attRequestResponse;
  late List<String> attMethodCalls;
  late List<String> analyticsMethodCalls;

  group('TrackingConsentService', () {
    setUp(() {
      setupFirebaseAnalyticsMocks();

      attStatus = TrackingStatus.notDetermined.index;
      attRequestResponse = TrackingStatus.authorized.index;
      attMethodCalls = <String>[];
      analyticsMethodCalls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(attChannel, (call) async {
            attMethodCalls.add(call.method);
            switch (call.method) {
              case 'getTrackingAuthorizationStatus':
                return attStatus;
              case 'requestTrackingAuthorization':
                attStatus = attRequestResponse;
                return attRequestResponse;
              default:
                return null;
            }
          });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(analyticsChannel, (call) async {
            analyticsMethodCalls.add(call.method);
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(analyticsPigeonSetChannel, (call) async {
            analyticsMethodCalls.add(call.method);
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler(analyticsPigeonSetBasicChannel, (
            message,
          ) async {
            analyticsMethodCalls.add('decoded:${message.toString()}');
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(attChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(analyticsChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(analyticsPigeonSetChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler(analyticsPigeonSetBasicChannel, null);
    });

    test('singleton instance is available', () {
      expect(TrackingConsentService.instance, isA<TrackingConsentService>());
    });

    test('initial state is not determined and unauthorized', () {
      final service = TrackingConsentService(isIosPlatform: () => false);

      expect(service.status, TrackingStatus.notDetermined);
      expect(service.isAuthorized, isFalse);
    });

    test('requestConsent is a no-op on non-iOS platforms', () async {
      var analyticsCalls = 0;

      final service = TrackingConsentService(
        isIosPlatform: () => false,
        trackingStatusProvider: () async {
          fail('trackingStatusProvider should not be called on non-iOS');
        },
        trackingAuthorizationRequester: () async {
          fail(
            'trackingAuthorizationRequester should not be called on non-iOS',
          );
        },
        analyticsCollectionSetter: (_) async {
          analyticsCalls++;
        },
      );

      await service.requestConsent();

      expect(service.status, TrackingStatus.notDetermined);
      expect(service.isAuthorized, isFalse);
      expect(analyticsCalls, 0);
    });

    test(
      'default constructor checks platform and no-ops on non-iOS host',
      () async {
        final service = TrackingConsentService();

        await service.requestConsent();
        final status = await service.checkStatus();

        expect(service.status, TrackingStatus.notDetermined);
        expect(service.isAuthorized, isFalse);
        expect(status, TrackingStatus.authorized);
        expect(attMethodCalls, isEmpty);
      },
    );

    test(
      'requestConsent on iOS with authorized status enables analytics',
      () async {
        var requestCalls = 0;
        final analyticsEnabled = <bool>[];

        final service = TrackingConsentService(
          isIosPlatform: () => true,
          trackingStatusProvider: () async => TrackingStatus.authorized,
          trackingAuthorizationRequester: () async {
            requestCalls++;
            return TrackingStatus.authorized;
          },
          analyticsCollectionSetter: (enabled) async {
            analyticsEnabled.add(enabled);
          },
        );

        await service.requestConsent();

        expect(service.status, TrackingStatus.authorized);
        expect(service.isAuthorized, isTrue);
        expect(requestCalls, 0);
        expect(analyticsEnabled, [true]);
      },
    );

    test('requestConsent requests ATT when status is not determined', () async {
      var requestCalls = 0;
      final analyticsEnabled = <bool>[];

      final service = TrackingConsentService(
        isIosPlatform: () => true,
        trackingStatusProvider: () async => TrackingStatus.notDetermined,
        trackingAuthorizationRequester: () async {
          requestCalls++;
          return TrackingStatus.denied;
        },
        analyticsCollectionSetter: (enabled) async {
          analyticsEnabled.add(enabled);
        },
      );

      await service.requestConsent();

      expect(requestCalls, 1);
      expect(service.status, TrackingStatus.denied);
      expect(service.isAuthorized, isFalse);
      expect(analyticsEnabled, [false]);
    });

    test(
      'requestConsent falls back to disabled analytics on exceptions',
      () async {
        final analyticsEnabled = <bool>[];

        final service = TrackingConsentService(
          isIosPlatform: () => true,
          trackingStatusProvider: () async {
            throw Exception('ATT provider failure');
          },
          trackingAuthorizationRequester: () async => TrackingStatus.authorized,
          analyticsCollectionSetter: (enabled) async {
            analyticsEnabled.add(enabled);
          },
        );

        await service.requestConsent();

        expect(service.isAuthorized, isFalse);
        expect(analyticsEnabled, [false]);
      },
    );

    test('requestConsent with default ATT handlers works on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      attStatus = TrackingStatus.notDetermined.index;
      attRequestResponse = TrackingStatus.authorized.index;

      final service = TrackingConsentService(
        isIosPlatform: () => true,
        analyticsCollectionSetter: (enabled) async {
          analyticsMethodCalls.add('custom:$enabled');
        },
      );

      await service.requestConsent();

      expect(service.status, TrackingStatus.authorized);
      expect(service.isAuthorized, isTrue);
      expect(
        attMethodCalls,
        containsAllInOrder(<String>[
          'getTrackingAuthorizationStatus',
          'requestTrackingAuthorization',
        ]),
      );
      expect(analyticsMethodCalls, ['custom:true']);
    });

    test('default analytics setter path is executed on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      attStatus = TrackingStatus.authorized.index;
      attRequestResponse = TrackingStatus.authorized.index;

      final service = TrackingConsentService(isIosPlatform: () => true);

      await expectLater(service.requestConsent(), completes);
      expect(service.status, TrackingStatus.authorized);
    });

    test('checkStatus returns authorized on non-iOS', () async {
      final service = TrackingConsentService(isIosPlatform: () => false);

      final status = await service.checkStatus();

      expect(status, TrackingStatus.authorized);
    });

    test('checkStatus on iOS updates and returns current ATT status', () async {
      final service = TrackingConsentService(
        isIosPlatform: () => true,
        trackingStatusProvider: () async => TrackingStatus.restricted,
      );

      final status = await service.checkStatus();

      expect(status, TrackingStatus.restricted);
      expect(service.status, TrackingStatus.restricted);
      expect(service.isAuthorized, isFalse);
    });

    test('checkStatus can use default ATT provider on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      attStatus = TrackingStatus.restricted.index;
      final service = TrackingConsentService(isIosPlatform: () => true);

      final status = await service.checkStatus();

      expect(status, TrackingStatus.restricted);
      expect(service.status, TrackingStatus.restricted);
      expect(attMethodCalls, ['getTrackingAuthorizationStatus']);
    });
  });
}
