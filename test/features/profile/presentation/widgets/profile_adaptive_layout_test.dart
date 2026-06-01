import 'package:crushhour/features/profile/presentation/widgets/profile_adaptive_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileAdaptiveLayoutMetrics', () {
    test('keeps phone layouts single column with compact media tiles', () {
      final metrics = ProfileAdaptiveLayoutMetrics.fromWidth(width: 390);

      expect(metrics.useTwoColumnSetup, isFalse);
      expect(metrics.useTwoColumnEdit, isFalse);
      expect(metrics.useTwoColumnView, isFalse);
      expect(metrics.mediaTileWidth, 96);
      expect(metrics.mediaTileHeight, 128);
    });

    test('uses setup and edit columns on tablet width', () {
      final metrics = ProfileAdaptiveLayoutMetrics.fromWidth(width: 820);

      expect(metrics.useTwoColumnSetup, isTrue);
      expect(metrics.useTwoColumnEdit, isTrue);
      expect(metrics.useTwoColumnView, isFalse);
      expect(metrics.sidePanelWidth, 320);
      expect(metrics.mediaTileWidth, 108);
    });

    test('disables columns when large text would make columns cramped', () {
      final metrics = ProfileAdaptiveLayoutMetrics.fromWidth(
        width: 900,
        textScale: 1.5,
      );

      expect(metrics.useTwoColumnSetup, isFalse);
      expect(metrics.useTwoColumnEdit, isFalse);
      expect(metrics.useTwoColumnView, isFalse);
    });

    test('uses wider view layout metrics on desktop width', () {
      final metrics = ProfileAdaptiveLayoutMetrics.fromWidth(width: 1200);

      expect(metrics.useTwoColumnView, isTrue);
      expect(metrics.sidePanelWidth, 360);
      expect(metrics.mediaTileWidth, 116);
    });
  });
}
