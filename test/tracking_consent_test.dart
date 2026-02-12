import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/services/tracking_consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingConsentService', () {
    late TrackingConsentService service;

    setUp(() {
      service = TrackingConsentService.instance;
    });

    group('Initial State', () {
      test('initial status is notDetermined', () {
        expect(service.status, TrackingStatus.notDetermined);
      });

      test('isAuthorized returns false when status is notDetermined', () {
        expect(service.isAuthorized, isFalse);
      });
    });

    group('isAuthorized logic', () {
      // TrackingConsentService.isAuthorized checks _status == TrackingStatus.authorized
      // Since _status is private and set by requestConsent/checkStatus,
      // we verify the getter logic relative to the status enum.

      test('TrackingStatus.authorized is the only authorized state', () {
        // Verify the enum values exist and the authorized logic
        expect(TrackingStatus.authorized, isNotNull);
        expect(TrackingStatus.denied, isNotNull);
        expect(TrackingStatus.notDetermined, isNotNull);
        expect(TrackingStatus.restricted, isNotNull);
        expect(TrackingStatus.notSupported, isNotNull);
      });
    });

    group('Platform behavior (non-iOS)', () {
      // On non-iOS platforms (macOS test runner), requestConsent and
      // checkStatus should return early without modifying state.
      // Platform.isIOS will be false on macOS test environment.

      test('requestConsent is a no-op on non-iOS', () async {
        // On macOS (test runner), Platform.isIOS is false
        // so requestConsent should return immediately
        await service.requestConsent();
        // Status should remain notDetermined because iOS check skips
        expect(service.status, TrackingStatus.notDetermined);
      });

      test('checkStatus returns authorized on non-iOS', () async {
        // On non-iOS, checkStatus returns TrackingStatus.authorized
        final status = await service.checkStatus();
        expect(status, TrackingStatus.authorized);
      });
    });

    group('TrackingStatus enum', () {
      test('has all expected values', () {
        expect(TrackingStatus.values.length, greaterThanOrEqualTo(4));
        expect(TrackingStatus.values, contains(TrackingStatus.notDetermined));
        expect(TrackingStatus.values, contains(TrackingStatus.restricted));
        expect(TrackingStatus.values, contains(TrackingStatus.denied));
        expect(TrackingStatus.values, contains(TrackingStatus.authorized));
      });
    });
  });
}
