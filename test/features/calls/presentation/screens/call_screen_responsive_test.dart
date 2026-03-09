import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('callScreenContentMaxWidthFor', () {
    test('maps to shared breakpoint max widths', () {
      expect(callScreenContentMaxWidthFor(390), double.infinity);
      expect(callScreenContentMaxWidthFor(820), 720);
      expect(callScreenContentMaxWidthFor(1200), 960);
    });
  });
}
