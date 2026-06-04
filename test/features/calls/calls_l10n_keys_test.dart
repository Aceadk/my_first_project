import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// I18N-001 (calls): verify the localized incoming-call + PiP keys resolve,
/// including the auto-dismiss placeholder and English fallback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('auto-dismiss placeholder interpolates the countdown', () {
    expect(en.callIncomingAutoDismiss(30), 'Auto-dismisses in 30s');
    expect(en.callIncomingAutoDismiss(0), 'Auto-dismisses in 0s');
  });

  test('incoming-call + PiP labels are non-empty', () {
    expect(en.callIncomingUnknownCaller, isNotEmpty);
    expect(en.callIncomingVideoTitle, isNotEmpty);
    expect(en.callDecline, isNotEmpty);
    expect(en.callSlideToAnswer, isNotEmpty);
    expect(en.callPipFloatingWindow, isNotEmpty);
    expect(en.callPipActiveCall, isNotEmpty);
  });

  test('untranslated locale falls back to English for new call keys', () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(fr.callDecline, en.callDecline);
    expect(fr.callIncomingAutoDismiss(5), 'Auto-dismisses in 5s');
  });
}
