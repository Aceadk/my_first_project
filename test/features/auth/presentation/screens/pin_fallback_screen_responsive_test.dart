import 'package:crushhour/features/auth/presentation/screens/pin_fallback_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pinFallbackContentMaxWidthFor', () {
    test('maps to shared breakpoint max widths', () {
      expect(pinFallbackContentMaxWidthFor(390), double.infinity);
      expect(pinFallbackContentMaxWidthFor(820), 720);
      expect(pinFallbackContentMaxWidthFor(1200), 960);
    });
  });
}
