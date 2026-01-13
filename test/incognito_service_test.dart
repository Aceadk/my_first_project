import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/discovery/data/services/incognito_service.dart';
import 'package:crushhour/features/discovery/data/models/incognito_settings.dart';

void main() {
  group('IncognitoService', () {
    late IncognitoService service;

    setUp(() {
      service = IncognitoService.instance;
      // Ensure clean state
      service.disableIncognito();
    });

    group('enableIncognito', () {
      test('enables incognito mode with default settings', () async {
        final settings = await service.enableIncognito();

        expect(settings.isEnabled, isTrue);
        expect(settings.isActive, isTrue);
        expect(settings.hideFromLikedYou, isTrue);
        expect(settings.hideLastActive, isTrue);
        expect(settings.hideReadReceipts, isTrue);
      });

      test('sets expiry for non-premium users', () async {
        final settings = await service.enableIncognito(isPremium: false);

        expect(settings.expiresAt, isNotNull);
        expect(
          settings.expiresAt!.isAfter(DateTime.now()),
          isTrue,
        );
      });

      test('no expiry for premium users', () async {
        final settings = await service.enableIncognito(isPremium: true);

        expect(settings.expiresAt, isNull);
      });

      test('respects custom privacy settings', () async {
        final settings = await service.enableIncognito(
          hideFromLikedYou: false,
          hideLastActive: true,
          hideReadReceipts: false,
          onlyShowToLiked: true,
        );

        expect(settings.hideFromLikedYou, isFalse);
        expect(settings.hideLastActive, isTrue);
        expect(settings.hideReadReceipts, isFalse);
        expect(settings.onlyShowToLiked, isTrue);
      });
    });

    group('disableIncognito', () {
      test('disables incognito mode', () async {
        await service.enableIncognito();
        expect(service.isIncognito, isTrue);

        await service.disableIncognito();

        expect(service.isIncognito, isFalse);
        expect(service.currentSettings.isEnabled, isFalse);
      });
    });

    group('updateSettings', () {
      test('updates individual settings', () async {
        await service.enableIncognito();

        await service.updateSettings(hideReadReceipts: false);

        expect(service.currentSettings.hideReadReceipts, isFalse);
        expect(service.currentSettings.hideLastActive, isTrue);
      });

      test('preserves other settings when updating', () async {
        await service.enableIncognito(
          hideFromLikedYou: true,
          hideLastActive: true,
        );

        await service.updateSettings(hideLastActive: false);

        expect(service.currentSettings.hideFromLikedYou, isTrue);
        expect(service.currentSettings.hideLastActive, isFalse);
      });
    });

    group('isVisibleTo', () {
      test('returns true when incognito disabled', () async {
        await service.disableIncognito();

        expect(service.isVisibleTo('viewer_123'), isTrue);
      });

      test('returns false for non-liked viewers when onlyShowToLiked', () async {
        await service.enableIncognito(onlyShowToLiked: true);

        expect(service.isVisibleTo('viewer_123', viewerHasLiked: false), isFalse);
      });

      test('returns true for liked viewers when onlyShowToLiked', () async {
        await service.enableIncognito(onlyShowToLiked: true);

        expect(service.isVisibleTo('viewer_123', viewerHasLiked: true), isTrue);
      });
    });

    group('shouldShowReadReceipts', () {
      test('returns true when incognito disabled', () async {
        await service.disableIncognito();

        expect(service.shouldShowReadReceipts(), isTrue);
      });

      test('returns false when hideReadReceipts is true', () async {
        await service.enableIncognito(hideReadReceipts: true);

        expect(service.shouldShowReadReceipts(), isFalse);
      });

      test('returns true when hideReadReceipts is false', () async {
        await service.enableIncognito(hideReadReceipts: false);

        expect(service.shouldShowReadReceipts(), isTrue);
      });
    });

    group('shouldShowLastActive', () {
      test('returns true when incognito disabled', () async {
        await service.disableIncognito();

        expect(service.shouldShowLastActive(), isTrue);
      });

      test('returns false when hideLastActive is true', () async {
        await service.enableIncognito(hideLastActive: true);

        expect(service.shouldShowLastActive(), isFalse);
      });
    });

    group('getRemainingTime', () {
      test('returns duration for non-premium users', () async {
        await service.enableIncognito(isPremium: false);

        final remaining = service.getRemainingTime();

        expect(remaining.inMinutes, greaterThan(0));
        expect(remaining.inMinutes, lessThanOrEqualTo(60));
      });

      test('returns zero for premium users', () async {
        await service.enableIncognito(isPremium: true);

        final remaining = service.getRemainingTime();

        expect(remaining, Duration.zero);
      });
    });

    group('stream', () {
      test('emits settings updates', () async {
        final emissions = <IncognitoSettings>[];
        final subscription = service.settingsStream.listen(emissions.add);

        await service.enableIncognito();
        await service.updateSettings(hideReadReceipts: false);
        await service.disableIncognito();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emissions.length, greaterThanOrEqualTo(2));

        await subscription.cancel();
      });
    });
  });
}
