import 'package:crushhour/features/discovery/presentation/widgets/deck_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accessibility regression coverage for [DeckActionButton] (DISC-UI-003).
///
/// These guard the non-gesture discovery actions (pass / like / super-like /
/// rewind) against regressions in their touch-target size, tooltip, disabled
/// state, or semantics during future refactors.
void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('DeckActionButton accessibility', () {
    testWidgets(
      'keeps a >=48dp interactive target even when the visual size is smaller',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            DeckActionButton(
              icon: Icons.replay,
              color: Colors.blue,
              semanticLabel: 'Undo last swipe',
              onTap: () {},
              size: 44, // smaller than the platform minimum on purpose
            ),
          ),
        );

        // The hit-area SizedBox is the only SizedBox inside the button.
        final hitSize = tester.getSize(
          find
              .descendant(
                of: find.byType(DeckActionButton),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(hitSize.width, greaterThanOrEqualTo(kMinInteractiveDimension));
        expect(hitSize.height, greaterThanOrEqualTo(kMinInteractiveDimension));
      },
    );

    testWidgets('preserves the requested visual size for large buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DeckActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.pink,
            semanticLabel: 'Like this profile',
            onTap: () {},
            size: 52,
          ),
        ),
      );

      final hitSize = tester.getSize(
        find
            .descendant(
              of: find.byType(DeckActionButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(hitSize.width, 52);
      expect(hitSize.height, 52);
    });

    testWidgets('exposes a tooltip mirroring the semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DeckActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.pink,
            semanticLabel: 'Like this profile',
            onTap: () {},
          ),
        ),
      );

      expect(find.byTooltip('Like this profile'), findsOneWidget);
    });

    testWidgets('uses an explicit tooltip when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          DeckActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.pink,
            semanticLabel: 'Like this profile',
            tooltip: 'Like (→)',
            onTap: () {},
          ),
        ),
      );

      expect(find.byTooltip('Like (→)'), findsOneWidget);
    });

    testWidgets('invokes onTap when enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          DeckActionButton(
            icon: Icons.close_rounded,
            color: Colors.red,
            semanticLabel: 'Pass on this profile',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(DeckActionButton));
      expect(taps, 1);
    });

    testWidgets('does not invoke onTap and dims when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          DeckActionButton(
            icon: Icons.star_rounded,
            color: Colors.amber,
            semanticLabel: 'Super like this profile',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DeckActionButton), warnIfMissed: false);
      expect(taps, 0);

      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(DeckActionButton),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('publishes a labelled button to assistive technologies', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          DeckActionButton(
            icon: Icons.close_rounded,
            color: Colors.red,
            semanticLabel: 'Pass on this profile',
            onTap: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Pass on this profile'), findsOneWidget);
      handle.dispose();
    });
  });
}
