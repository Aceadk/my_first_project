import 'package:crushhour/features/auth/presentation/screens/terms_conditions_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('termsConditionsContentMaxWidthFor', () {
    test('maps to shared breakpoint max widths', () {
      expect(termsConditionsContentMaxWidthFor(390), double.infinity);
      expect(termsConditionsContentMaxWidthFor(820), 720);
      expect(termsConditionsContentMaxWidthFor(1200), 960);
    });
  });
}
