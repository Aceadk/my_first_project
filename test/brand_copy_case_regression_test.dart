import 'dart:io';

import 'package:crushhour/l10n/generated/app_localizations_en.dart';
import 'package:crushhour/l10n/generated/app_localizations_yue.dart';
import 'package:crushhour/l10n/generated/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('brand copy localization casing', () {
    test('english localization uses Crush title case', () {
      final en = AppLocalizationsEn();

      expect(en.crush, 'Crush');
      expect(en.authSignInToContinue, contains('Crush'));
      expect(en.settingsGetPlus, contains('Crush Plus'));
      expect(en.onboardingWelcome, contains('Crush'));
      expect(en.subscriptionGetPlus, contains('Crush Plus'));
      expect(en.reportSubmittedThanksForKeeping, contains('Crush'));

      expect(en.authSignInToContinue, isNot(contains('CRUSH')));
      expect(en.settingsGetPlus, isNot(contains('CRUSH')));
      expect(en.onboardingWelcome, isNot(contains('CRUSH')));
      expect(en.subscriptionGetPlus, isNot(contains('CRUSH')));
      expect(en.reportSubmittedThanksForKeeping, isNot(contains('CRUSH')));
    });

    test(
      'zh and yue localizations keep Crush title case in contiguous scripts',
      () {
        final zh = AppLocalizationsZh();
        final yue = AppLocalizationsYue();

        expect(zh.authSignInToContinue, contains('Crush'));
        expect(zh.onboardingWelcome, contains('Crush'));
        expect(zh.subscriptionGetPlus, contains('Crush Plus'));
        expect(zh.authSignInToContinue, isNot(contains('CRUSH')));
        expect(zh.onboardingWelcome, isNot(contains('CRUSH')));
        expect(zh.subscriptionGetPlus, isNot(contains('CRUSH Plus')));

        expect(yue.authSignInToContinue, contains('Crush'));
        expect(yue.onboardingWelcome, contains('Crush'));
        expect(yue.subscriptionGetPlus, contains('Crush Plus'));
        expect(yue.authSignInToContinue, isNot(contains('CRUSH')));
        expect(yue.onboardingWelcome, isNot(contains('CRUSH')));
        expect(yue.subscriptionGetPlus, isNot(contains('CRUSH Plus')));
      },
    );
  });

  group('brand copy runtime casing', () {
    test('high-traffic onboarding/discovery/premium strings remain Crush case', () {
      final files = <String, String>{
        'lib/features/discovery/presentation/screens/likes_you_screen.dart':
            'Upgrade to Crush Plus to see who likes you and match instantly!',
        'lib/features/chat/presentation/screens/matches_screen.dart':
            'See likes first, Passport to any city, and unlimited likes to help you match faster.',
        'lib/features/discovery/presentation/widgets/welcome_tutorial_overlay.dart':
            'Welcome to Crush!',
        'lib/features/settings/presentation/screens/appearance_settings_screen.dart':
            'Crush Premium',
        'lib/features/auth/presentation/widgets/biometric_prompt.dart':
            'Unlock Crush',
        'lib/main.dart': 'Starting Crush...',
      };

      for (final entry in files.entries) {
        final source = File(entry.key).readAsStringSync();
        expect(
          source,
          contains(entry.value),
          reason: 'Expected "${entry.value}" in ${entry.key}',
        );
        expect(
          source,
          isNot(contains('CRUSH')),
          reason: 'Unexpected uppercase brand token in ${entry.key}',
        );
      }
    });
  });
}
