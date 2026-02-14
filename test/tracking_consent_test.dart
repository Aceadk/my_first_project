import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/services/tracking_consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingConsentService', () {
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
  });
}
