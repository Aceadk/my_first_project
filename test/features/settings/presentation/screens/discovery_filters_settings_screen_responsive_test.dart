import 'package:crushhour/features/settings/presentation/screens/discovery_filters_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('discoveryFiltersContentMaxWidthFor', () {
    test('maps to shared breakpoint max widths', () {
      expect(discoveryFiltersContentMaxWidthFor(390), double.infinity);
      expect(discoveryFiltersContentMaxWidthFor(820), 720);
      expect(discoveryFiltersContentMaxWidthFor(1200), 960);
    });
  });
}
