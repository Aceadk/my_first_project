import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// I18N-001 (auth): verify the localized change-email keys resolve, including
/// the current-email placeholder and English fallback for untranslated locales.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('current-email placeholder interpolates the address', () {
    expect(en.authCurrentEmailLabel('a@b.com'), 'Current email: a@b.com');
  });

  test('change-email labels + form copy are non-empty', () {
    expect(en.authChangeEmailTitle, isNotEmpty);
    expect(en.authChangeEmailIntro, isNotEmpty);
    expect(en.authNewEmailAddress, isNotEmpty);
    expect(en.authCodeWillBeSentToEmail, isNotEmpty);
    expect(en.authEnterCodeFromEmail, isNotEmpty);
    expect(en.authVerifyCode, isNotEmpty);
    expect(en.authEnterEmailAddress, isNotEmpty);
    expect(en.authUseCodeFromEmail, isNotEmpty);
    expect(en.authEnterCurrentPasswordPrompt, isNotEmpty);
  });

  test('change-email result/snackbar copy is non-empty', () {
    expect(en.authCouldNotSendCode, isNotEmpty);
    expect(en.authRequestFailed, isNotEmpty);
    expect(en.authCodeOnTheWayEmail, isNotEmpty);
    expect(en.authInvalidOrExpiredCode, isNotEmpty);
    expect(en.authVerificationFailed, isNotEmpty);
    expect(en.authEmailUpdated, isNotEmpty);
  });

  test('untranslated locale falls back to English for new change-email keys', () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(fr.authChangeEmailTitle, en.authChangeEmailTitle);
    expect(fr.authCurrentEmailLabel('x@y.z'), 'Current email: x@y.z');
  });
}
