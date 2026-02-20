import 'package:crushhour/features/calls/presentation/widgets/call_safety_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestable(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('renders safety tip and action buttons', (tester) async {
    await tester.pumpWidget(
      buildTestable(
        CallSafetyControls(
          showSafetyTip: true,
          onDismissTip: () {},
          onOpenGuidelines: () {},
          onReportPressed: () {},
          onBlockPressed: () {},
          isBlocked: false,
          isReportedRecently: false,
          matchName: 'Alex',
        ),
      ),
    );

    expect(find.text('Safety reminder'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Block'), findsOneWidget);
    expect(find.textContaining('first call with Alex'), findsOneWidget);
  });

  testWidgets('fires callbacks for controls', (tester) async {
    var dismissTapped = 0;
    var guidelinesTapped = 0;
    var reportTapped = 0;
    var blockTapped = 0;

    await tester.pumpWidget(
      buildTestable(
        CallSafetyControls(
          showSafetyTip: true,
          onDismissTip: () => dismissTapped++,
          onOpenGuidelines: () => guidelinesTapped++,
          onReportPressed: () => reportTapped++,
          onBlockPressed: () => blockTapped++,
          isBlocked: false,
          isReportedRecently: false,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Dismiss safety tip'));
    await tester.pump();
    await tester.tap(find.text('View safety guidelines'));
    await tester.pump();
    await tester.tap(find.text('Report'));
    await tester.pump();
    await tester.tap(find.text('Block'));
    await tester.pump();

    expect(dismissTapped, 1);
    expect(guidelinesTapped, 1);
    expect(reportTapped, 1);
    expect(blockTapped, 1);
  });

  testWidgets('disables actions when already reported or blocked', (
    tester,
  ) async {
    var reportTapped = 0;
    var blockTapped = 0;

    await tester.pumpWidget(
      buildTestable(
        CallSafetyControls(
          showSafetyTip: false,
          onDismissTip: () {},
          onOpenGuidelines: () {},
          onReportPressed: () => reportTapped++,
          onBlockPressed: () => blockTapped++,
          isBlocked: true,
          isReportedRecently: true,
        ),
      ),
    );

    expect(find.text('Reported'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);

    await tester.tap(find.text('Reported'));
    await tester.pump();
    await tester.tap(find.text('Blocked'));
    await tester.pump();

    expect(reportTapped, 0);
    expect(blockTapped, 0);
  });
}
