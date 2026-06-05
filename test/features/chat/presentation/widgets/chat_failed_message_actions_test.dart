import 'package:crushhour/features/chat/presentation/widgets/chat_failed_message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// CHAT-UI-003 — failed-send state must be visible (not colour alone) and
/// recoverable, with accessible, adequately-sized controls.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onRetry,
    required VoidCallback onDiscard,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChatFailedMessageActions(
              onRetry: onRetry,
              onDiscard: onDiscard,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the failure with text + icon (not colour alone)', (
    tester,
  ) async {
    await pump(tester, onRetry: () {}, onDiscard: () {});

    expect(find.text('Failed to send'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Retry and Delete invoke their callbacks', (tester) async {
    var retried = 0;
    var discarded = 0;
    await pump(
      tester,
      onRetry: () => retried++,
      onDiscard: () => discarded++,
    );

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(retried, 1);
    expect(discarded, 1);
  });

  testWidgets('actions expose explicit screen-reader labels', (tester) async {
    await pump(tester, onRetry: () {}, onDiscard: () {});

    expect(find.bySemanticsLabel('Retry sending message'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete failed message'), findsOneWidget);
  });

  testWidgets('action tap targets meet the 48dp minimum', (tester) async {
    await pump(tester, onRetry: () {}, onDiscard: () {});

    final inkWells = find.descendant(
      of: find.byType(ChatFailedMessageActions),
      matching: find.byType(InkWell),
    );
    expect(inkWells, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(inkWells.at(i));
      expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
      expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    }
  });
}
