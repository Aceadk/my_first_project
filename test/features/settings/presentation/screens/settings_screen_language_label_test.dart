import 'package:crushhour/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settingsLanguageLabelFor', () {
    test('returns labels for supported languages', () {
      expect(settingsLanguageLabelFor('en'), 'English');
      expect(settingsLanguageLabelFor('es'), 'Spanish');
      expect(settingsLanguageLabelFor('ar'), 'Arabic');
      expect(settingsLanguageLabelFor('yue'), 'Cantonese');
      expect(settingsLanguageLabelFor('zh'), 'Chinese');
    });

    test('returns uppercase code for unknown languages', () {
      expect(settingsLanguageLabelFor('xx'), 'XX');
    });
  });
}
