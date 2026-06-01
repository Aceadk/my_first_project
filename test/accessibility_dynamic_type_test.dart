import 'package:crushhour/design_system/utils/accessibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A11Y-002 — dynamic type, focus order, and keyboard navigation.
///
/// Covers the locally verifiable half of A11Y-002: the global text-scale cap
/// that keeps 200%+ system text from breaking layouts, plus deterministic focus
/// order and keyboard activation for the design-system focus utilities. Manual
/// external-keyboard passes on device remain a separate, human step.
void main() {
  TextScaler? observed;

  Widget probe({required TextScaler systemScale}) {
    observed = null;
    return MediaQuery(
      data: MediaQueryData(textScaler: systemScale),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DsTextScaleCap(
          child: Builder(
            builder: (context) {
              observed = MediaQuery.of(context).textScaler;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  group('A11Y-002 dynamic type cap', () {
    testWidgets('caps extreme system text scaling at 2.0x', (tester) async {
      await tester.pumpWidget(probe(systemScale: const TextScaler.linear(3.5)));
      expect(observed!.scale(10), 20.0); // 10pt -> 20pt, not 35pt.
    });

    testWidgets('leaves in-range scaling untouched', (tester) async {
      await tester.pumpWidget(probe(systemScale: const TextScaler.linear(1.6)));
      expect(observed!.scale(10), closeTo(16.0, 0.001));
    });

    testWidgets('lifts sub-1.0 scaling to the readable floor', (tester) async {
      await tester.pumpWidget(probe(systemScale: const TextScaler.linear(0.7)));
      expect(observed!.scale(10), 10.0);
    });
  });

  group('A11Y-002 focus order and keyboard navigation', () {
    testWidgets('DsFocusTraversalScreen yields deterministic reading order', (
      tester,
    ) async {
      final first = FocusNode(debugLabel: 'first');
      final second = FocusNode(debugLabel: 'second');
      final third = FocusNode(debugLabel: 'third');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(third.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DsFocusTraversalScreen(
              child: Column(
                children: [
                  TextField(focusNode: first),
                  TextField(focusNode: second),
                  TextField(focusNode: third),
                ],
              ),
            ),
          ),
        ),
      );

      first.requestFocus();
      await tester.pump();
      expect(first.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(third.hasFocus, isTrue);
    });

    testWidgets('a focused button activates with the keyboard', (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => activations++,
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      );

      Focus.of(tester.element(find.text('Continue'))).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(activations, 2);
    });
  });
}
