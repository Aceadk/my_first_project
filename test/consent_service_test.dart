import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/services/consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Since ConsentService is a singleton, we work with its instance directly.
  // We use SharedPreferences mock initial values to control state.

  group('ConsentService', () {
    group('Initialization', () {
      test('initializes with no consent when preferences are empty', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final service = ConsentService.instance;

        await service.initialize(prefs);

        expect(service.hasConsent, isFalse);
      });

      test('initializes with consent true when previously granted', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final service = ConsentService.instance;

        await service.initialize(prefs);

        expect(service.hasConsent, isTrue);
      });

      test('initializes with consent false when previously revoked', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final service = ConsentService.instance;

        await service.initialize(prefs);

        expect(service.hasConsent, isFalse);
      });
    });

    group('Grant Consent', () {
      test('sets hasConsent to true after granting', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final service = ConsentService.instance;

        await service.initialize(prefs);
        expect(service.hasConsent, isFalse);

        await service.grantConsent();
        expect(service.hasConsent, isTrue);
      });

      test('persists consent to SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({});
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        await service.grantConsent();

        // Re-read from preferences to confirm persistence
        final storedConsent = prefs.getBool('gdpr_consent_given');
        expect(storedConsent, isTrue);
      });

      test('saves a consent timestamp when granting', () async {
        SharedPreferences.setMockInitialValues({});
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        await service.grantConsent();

        final timestamp = await service.getConsentTimestamp();
        expect(timestamp, isNotNull);
        // Verify it's a valid ISO 8601 date string
        final parsed = DateTime.tryParse(timestamp!);
        expect(parsed, isNotNull);
      });

      test('timestamp is close to current time', () async {
        SharedPreferences.setMockInitialValues({});
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        final before = DateTime.now();
        await service.grantConsent();
        final after = DateTime.now();

        final timestamp = await service.getConsentTimestamp();
        final parsed = DateTime.parse(timestamp!);
        expect(parsed.isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(
            parsed.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('Revoke Consent', () {
      test('sets hasConsent to false after revoking', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': true,
          'gdpr_consent_timestamp': '2026-01-01T00:00:00.000',
        });
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);
        expect(service.hasConsent, isTrue);

        await service.revokeConsent();
        expect(service.hasConsent, isFalse);
      });

      test('removes consent timestamp from preferences', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': true,
          'gdpr_consent_timestamp': '2026-01-01T00:00:00.000',
        });
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        await service.revokeConsent();

        final timestamp = await service.getConsentTimestamp();
        expect(timestamp, isNull);
      });

      test('persists revocation to SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': true,
        });
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        await service.revokeConsent();

        final storedConsent = prefs.getBool('gdpr_consent_given');
        expect(storedConsent, isFalse);
      });
    });

    group('Consent Timestamp', () {
      test('returns null when no consent has been granted', () async {
        SharedPreferences.setMockInitialValues({});
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        final timestamp = await service.getConsentTimestamp();
        expect(timestamp, isNull);
      });

      test('returns stored timestamp when consent was granted', () async {
        const storedTimestamp = '2026-01-15T10:30:00.000';
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': true,
          'gdpr_consent_timestamp': storedTimestamp,
        });
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        final timestamp = await service.getConsentTimestamp();
        expect(timestamp, storedTimestamp);
      });
    });

    group('hasConsent state', () {
      test('reflects initial state before any operations', () async {
        SharedPreferences.setMockInitialValues({});
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        expect(service.hasConsent, isFalse);
      });

      test('grant then revoke cycle works correctly', () async {
        SharedPreferences.setMockInitialValues({});
        final service = ConsentService.instance;
        final prefs = await SharedPreferences.getInstance();
        await service.initialize(prefs);

        expect(service.hasConsent, isFalse);

        await service.grantConsent();
        expect(service.hasConsent, isTrue);

        await service.revokeConsent();
        expect(service.hasConsent, isFalse);

        await service.grantConsent();
        expect(service.hasConsent, isTrue);
      });
    });
  });
}
