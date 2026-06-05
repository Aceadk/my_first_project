import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// I18N-001 (auth): verify the localized OTP + login keys resolve, including
/// the OTP-sent-to placeholder and English fallback for untranslated locales.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('OTP sent-to placeholder interpolates the phone number', () {
    expect(en.authOtpSentTo('+1 555 0100'), 'OTP sent to +1 555 0100');
  });

  test('otp-screen copy is non-empty', () {
    expect(en.authOtpCaption, isNotEmpty);
    expect(en.authEnterOtp, isNotEmpty);
    expect(en.authEnterCodeFromSms, isNotEmpty);
    expect(en.authEnterCodeToContinue, isNotEmpty);
    expect(en.authEnterCodeVerifyPhone, isNotEmpty);
    expect(en.authCodeShouldBe6Digits, isNotEmpty);
  });

  test('login-screen copy is non-empty', () {
    expect(en.wordOr, isNotEmpty);
    expect(en.authEnterEmailOrUsername, isNotEmpty);
    expect(en.authUsernameMustBe320, isNotEmpty);
    expect(en.authEnterYourPassword, isNotEmpty);
    expect(en.authAppleSignInFailed, isNotEmpty);
  });

  test('untranslated locale falls back to English for the new keys', () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(fr.authEnterOtp, en.authEnterOtp);
    expect(fr.authOtpSentTo('123'), 'OTP sent to 123');
    expect(fr.wordOr, en.wordOr);
  });
}
