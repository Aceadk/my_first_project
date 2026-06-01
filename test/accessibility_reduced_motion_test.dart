import 'package:crushhour/design_system/animations/ds_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A11Y-003 — reduced motion.
///
/// The design-system entrance/press animation wrappers must honor the platform
/// "reduce motion" accessibility setting (MediaQuery.disableAnimations). When it
/// is on they should render their child statically, with no transition driver,
/// so vestibular-sensitive users are not subjected to movement.
void main() {
  Widget host({required bool disableAnimations, required Widget child}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );
  }

  group('A11Y-003 reduced motion is respected', () {
    testWidgets('DsFadeIn drops FadeTransition when motion is reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          disableAnimations: true,
          child: const DsFadeIn(child: Text('fade')),
        ),
      );

      expect(find.text('fade'), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('DsFadeIn animates when motion is allowed', (tester) async {
      await tester.pumpWidget(
        host(
          disableAnimations: false,
          child: const DsFadeIn(child: Text('fade')),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      // Settle the running controller so the test tears down cleanly.
      await tester.pumpAndSettle();
    });

    testWidgets('DsSlideIn drops Slide/Fade transitions when reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          disableAnimations: true,
          child: const DsSlideIn(child: Text('slide')),
        ),
      );

      expect(find.text('slide'), findsOneWidget);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('DsScaleIn drops ScaleTransition when reduced', (tester) async {
      await tester.pumpWidget(
        host(
          disableAnimations: true,
          child: const DsScaleIn(child: Text('scale')),
        ),
      );

      expect(find.text('scale'), findsOneWidget);
      expect(find.byType(ScaleTransition), findsNothing);
    });

    testWidgets('DsPressable drops AnimatedScale and still fires onTap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          disableAnimations: true,
          child: DsPressable(
            onTap: () => taps++,
            child: const Text('press'),
          ),
        ),
      );

      expect(find.byType(AnimatedScale), findsNothing);
      await tester.tap(find.text('press'));
      expect(taps, 1);
    });

    testWidgets('DsStaggeredList renders all items statically when reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          disableAnimations: true,
          child: const DsStaggeredList(
            children: [Text('one'), Text('two'), Text('three')],
          ),
        ),
      );

      expect(find.byType(SlideTransition), findsNothing);
      for (final label in ['one', 'two', 'three']) {
        expect(find.text(label), findsOneWidget);
      }
      // Flush the staggered start timers so teardown is clean.
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    });
  });
}
