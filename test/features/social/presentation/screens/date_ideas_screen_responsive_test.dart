import 'package:crushhour/features/social/presentation/screens/date_ideas_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateIdeasContentMaxWidthFor', () {
    test('maps to shared breakpoint max widths', () {
      expect(dateIdeasContentMaxWidthFor(390), double.infinity);
      expect(dateIdeasContentMaxWidthFor(820), 720);
      expect(dateIdeasContentMaxWidthFor(1200), 960);
    });
  });
}
