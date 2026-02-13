import 'package:crushhour/design_system/utils/accessibility.dart' as ds;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DsAccessibility', () {
    test('contrast helpers and text color choose accessible values', () {
      final ratio = ds.DsAccessibility.contrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(ratio, greaterThan(20));

      expect(
        ds.DsAccessibility.meetsContrastAA(Colors.black, Colors.white),
        isTrue,
      );
      expect(
        ds.DsAccessibility.meetsContrastAAA(Colors.black, Colors.white),
        isTrue,
      );
      expect(
        ds.DsAccessibility.meetsContrastAAA(
          const Color(0xFF777777),
          Colors.white,
        ),
        isFalse,
      );

      expect(
        ds.DsAccessibility.accessibleTextColor(Colors.white),
        Colors.black,
      );
      expect(
        ds.DsAccessibility.accessibleTextColor(Colors.black),
        Colors.white,
      );
    });

    testWidgets(
      'prefersReducedMotion and animationDuration honor media query',
      (tester) async {
        var prefersReduced = false;
        var duration = Duration.zero;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                prefersReduced = ds.DsAccessibility.prefersReducedMotion(
                  context,
                );
                duration = ds.DsAccessibility.animationDuration(
                  context,
                  normal: const Duration(milliseconds: 400),
                  reduced: const Duration(milliseconds: 1),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(prefersReduced, isTrue);
        expect(duration, const Duration(milliseconds: 1));
      },
    );

    testWidgets('announce and announceDelayed are callable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox(width: 10, height: 10)),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      ds.DsAccessibility.announce(context, 'Accessible update');
      ds.DsAccessibility.announceDelayed(
        context,
        'Delayed update',
        delay: const Duration(milliseconds: 1),
      );
      await tester.pump(const Duration(milliseconds: 2));
    });
  });

  group('Accessibility wrappers', () {
    testWidgets('basic semantic wrappers build and expose their child', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ds.ExcludeSemantics(child: Text('exclude')),
                ds.MergeSemantics(child: Text('merge')),
                ds.SemanticLabel(
                  label: 'Labeled Item',
                  hint: 'Item hint',
                  isButton: true,
                  child: Text('label'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('exclude'), findsOneWidget);
      expect(find.text('merge'), findsOneWidget);
      expect(find.text('label'), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('extension wrappers build correctly', (tester) async {
      final labeled = ds.AccessibilityExtension(
        const Text('ext-label'),
      ).withSemantics(label: 'ext semantic', hint: 'ext hint', isButton: true);
      final excluded = ds.AccessibilityExtension(
        const Text('ext-exclude'),
      ).excludeSemantics();
      final liveRegion = ds.AccessibilityExtension(
        const Text('ext-live'),
      ).asLiveRegion(label: 'live region');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(children: [labeled, excluded, liveRegion]),
          ),
        ),
      );

      expect(find.text('ext-label'), findsOneWidget);
      expect(find.text('ext-exclude'), findsOneWidget);
      expect(find.text('ext-live'), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets(
      'profile, match, progress, loading, and dialog wrappers build',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ds.SemanticProfileCard(
                    name: 'Alex',
                    age: 29,
                    distance: '3 miles',
                    bio: 'Loves coffee',
                    child: Text('profile-card'),
                  ),
                  ds.SemanticMatchTile(
                    name: 'Sam',
                    isOnline: true,
                    unreadCount: 2,
                    lastMessage: 'Hey there',
                    child: Text('match-tile'),
                  ),
                  ds.SemanticProgress(value: 0.5, label: 'profile complete'),
                  ds.SemanticLoading(
                    label: 'Loading chat',
                    child: Text('loading-child'),
                  ),
                  ds.SemanticDialog(
                    title: 'Confirm',
                    child: Text('dialog-child'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('profile-card'), findsOneWidget);
        expect(find.text('match-tile'), findsOneWidget);
        expect(find.text('loading-child'), findsOneWidget);
        expect(find.text('dialog-child'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('semantic button handles tap and min size constraint', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ds.SemanticButton(
              label: 'Do action',
              hint: 'Runs an action',
              minSize: 48,
              onTap: () => tapped = true,
              child: const Text('tap me'),
            ),
          ),
        ),
      );

      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ds.SemanticButton),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.minWidth, 48);
      expect(box.constraints.minHeight, 48);

      await tester.tap(find.text('tap me'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('semantic image, focus group, and focus indicator build', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ds.SemanticImage(
                  label: 'Profile image',
                  child: Text('image-a'),
                ),
                ds.SemanticImage(
                  label: 'Decorative',
                  isDecorative: true,
                  child: Text('image-b'),
                ),
                ds.AccessibleFocusGroup(
                  children: [Text('focus-1'), Text('focus-2')],
                ),
                ds.FocusIndicator(child: Text('focus-indicator')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('image-a'), findsOneWidget);
      expect(find.text('image-b'), findsOneWidget);
      expect(find.text('focus-1'), findsOneWidget);
      expect(find.text('focus-2'), findsOneWidget);
      expect(find.text('focus-indicator'), findsOneWidget);
      expect(find.byType(FocusTraversalGroup), findsWidgets);
      expect(find.byType(AnimatedContainer), findsWidgets);
    });
  });
}
