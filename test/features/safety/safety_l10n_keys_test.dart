import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// I18N-001 (safety_screen): the screen is now fully localized. Verify the new
/// safety keys resolve and — most importantly — that the ICU plural and the
/// placeholder messages render correctly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('safety plural renders singular vs plural correctly', () {
    expect(en.safetySharedWithContacts(1), 'Shared with 1 contact');
    expect(en.safetySharedWithContacts(2), 'Shared with 2 contacts');
    expect(en.safetySharedWithContacts(5), 'Shared with 5 contacts');
  });

  test('safety placeholder messages interpolate', () {
    expect(en.safetyDateWith('Alex'), 'Date with Alex');
    expect(en.safetyReportedOn('Jun 4, 2026'), contains('Jun 4, 2026'));
  });

  test('representative safety labels are non-empty', () {
    expect(en.safetyTitle, isNotEmpty);
    expect(en.safetyEmergencyAlertBody, isNotEmpty);
    expect(en.safetyStatusOngoing, isNotEmpty);
    expect(en.safetyCreatePlan, isNotEmpty);
    expect(en.safetyErrorValidEmail, isNotEmpty);
  });

  test('untranslated locale falls back to English for new keys', () async {
    // French has no safety* overrides yet; gen-l10n falls back to the template.
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(fr.safetyTitle, en.safetyTitle);
    expect(fr.safetySharedWithContacts(2), 'Shared with 2 contacts');
  });
}
