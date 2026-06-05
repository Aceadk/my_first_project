import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// I18N-001 (auth): verify the localized email-protection + new-device keys
/// resolve, and that untranslated locales fall back to English.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('email-protection copy is non-empty', () {
    expect(en.authEmailProtectionTitle, isNotEmpty);
    expect(en.authEmailProtectionIntro, isNotEmpty);
    expect(en.authEmailVerifiedBadge, isNotEmpty);
    expect(en.authEmailAlreadyVerifiedLocked, isNotEmpty);
    expect(en.authWantDifferentEmail, isNotEmpty);
    expect(en.authDifferentEmailInstructions, isNotEmpty);
    expect(en.authGoToAccountSettings, isNotEmpty);
    expect(en.authStatusNotVerified, isNotEmpty);
    expect(en.authEmailAddress, isNotEmpty);
    expect(en.authEmailAlreadyRegistered, isNotEmpty);
  });

  test('new-device copy is non-empty', () {
    expect(en.authNewDeviceTitle, isNotEmpty);
    expect(en.authNewDeviceIntro, isNotEmpty);
    expect(en.authCodeWillBeSentToEmailOnFile, isNotEmpty);
    expect(en.authVerifyDevice, isNotEmpty);
    expect(en.authEnterUsernameOrEmail, isNotEmpty);
    expect(en.authCodeOnTheWayAccount, isNotEmpty);
    expect(en.authDeviceVerified, isNotEmpty);
  });

  test('untranslated locale falls back to English for the new keys', () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(fr.authEmailProtectionTitle, en.authEmailProtectionTitle);
    expect(fr.authNewDeviceTitle, en.authNewDeviceTitle);
    expect(fr.authDeviceVerified, en.authDeviceVerified);
  });
}
