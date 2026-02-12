import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/theme/app_theme_mode.dart';

void main() {
  group('AppThemeModeX', () {
    test('returns expected storage keys', () {
      expect(AppThemeMode.system.storageKey, 'system');
      expect(AppThemeMode.light.storageKey, 'light');
      expect(AppThemeMode.dark.storageKey, 'dark');
      expect(AppThemeMode.darkLuxury.storageKey, 'luxury');
      expect(AppThemeMode.darkLuxuryModern.storageKey, 'luxury_modern');
    });

    test('identifies luxury modes', () {
      expect(AppThemeMode.system.isLuxury, isFalse);
      expect(AppThemeMode.light.isLuxury, isFalse);
      expect(AppThemeMode.dark.isLuxury, isFalse);
      expect(AppThemeMode.darkLuxury.isLuxury, isTrue);
      expect(AppThemeMode.darkLuxuryModern.isLuxury, isTrue);
    });
  });

  group('appThemeModeFromKey', () {
    test('maps direct keys correctly', () {
      expect(appThemeModeFromKey('system'), AppThemeMode.system);
      expect(appThemeModeFromKey('light'), AppThemeMode.light);
      expect(appThemeModeFromKey('dark'), AppThemeMode.dark);
      expect(appThemeModeFromKey('luxury'), AppThemeMode.darkLuxury);
      expect(
          appThemeModeFromKey('luxury_modern'), AppThemeMode.darkLuxuryModern);
    });

    test('maps legacy aliases correctly', () {
      const luxuryAliases = [
        'luxury_classic',
        'dark_luxury',
        'darkLuxury',
        'royal',
        'classic',
      ];
      for (final alias in luxuryAliases) {
        expect(appThemeModeFromKey(alias), AppThemeMode.darkLuxury);
      }

      const modernAliases = [
        'modern',
        'modern_luxury',
        'darkLuxuryModern',
      ];
      for (final alias in modernAliases) {
        expect(appThemeModeFromKey(alias), AppThemeMode.darkLuxuryModern);
      }
    });

    test('falls back to system for unknown or null values', () {
      expect(appThemeModeFromKey(null), AppThemeMode.system);
      expect(appThemeModeFromKey(''), AppThemeMode.system);
      expect(appThemeModeFromKey('unknown'), AppThemeMode.system);
    });
  });
}
