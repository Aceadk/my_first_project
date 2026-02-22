import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/widgets/accessible_icon_button.dart';

void main() {
  group('DsAccessibleIconButton', () {
    testWidgets('triggers callback and renders tooltip when enabled', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          child: DsAccessibleIconButton(
            icon: Icons.favorite,
            onPressed: () => tapped++,
            semanticLabel: 'Favorite',
            semanticHint: 'Save profile',
            tooltip: 'Favorite',
            enableHaptics: false,
          ),
        ),
      );

      expect(find.byTooltip('Favorite'), findsOneWidget);
      await tester.tap(find.byType(DsAccessibleIconButton));
      await tester.pump();
      expect(tapped, equals(1));
    });

    testWidgets('does not trigger callback when disabled', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          child: DsAccessibleIconButton(
            icon: Icons.block,
            onPressed: () => tapped++,
            semanticLabel: 'Blocked',
            enabled: false,
            enableHaptics: false,
          ),
        ),
      );

      await tester.tap(find.byType(DsAccessibleIconButton));
      await tester.pump();
      expect(tapped, equals(0));
    });
  });

  group('DsActionButton', () {
    testWidgets('respects size variants and enabled/disabled interactions', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DsActionButton(
                icon: Icons.close,
                onPressed: () => taps++,
                semanticLabel: 'Pass',
                size: DsActionButtonSize.small,
                enableHaptics: false,
              ),
              const SizedBox(width: 12),
              DsActionButton(
                icon: Icons.star,
                onPressed: () => taps++,
                semanticLabel: 'Super like',
                size: DsActionButtonSize.large,
                enabled: false,
                enableHaptics: false,
              ),
            ],
          ),
        ),
      );

      final buttons = find.byType(DsActionButton);
      expect(
        tester.getSize(buttons.first).width,
        equals(DsSizes.actionButtonSm),
      );
      expect(
        tester.getSize(buttons.last).width,
        equals(DsSizes.actionButtonLg),
      );

      await tester.tap(buttons.first);
      await tester.tap(buttons.last);
      await tester.pump();

      expect(taps, equals(1));
    });
  });

  group('DsLabeledActionButton', () {
    testWidgets('renders label and delegates tap to inner action button', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          child: DsLabeledActionButton(
            icon: Icons.check,
            label: 'Like',
            onPressed: () => tapped++,
          ),
        ),
      );

      expect(find.text('Like'), findsOneWidget);
      await tester.tap(find.byType(DsActionButton));
      await tester.pump();
      expect(tapped, equals(1));
    });
  });
}

Widget _wrap({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
