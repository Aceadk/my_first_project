import 'package:crushhour/core/services/app_update_service.dart';
import 'package:crushhour/core/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
    return hostContext;
  }

  Future<void> showAndCloseDialog(
    WidgetTester tester, {
    required BuildContext context,
    required UpdateStatus status,
  }) async {
    final showFuture = UpdateDialog.show(
      context,
      result: UpdateCheckResult(
        status: status,
        currentVersion: '1.0.0',
        minVersion: '2.0.0',
      ),
      onUpdate: () => Navigator.of(context).pop(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();
    await showFuture;
  }

  testWidgets('force update default message uses Crush brand', (tester) async {
    final context = await pumpHost(tester);

    final showFuture = UpdateDialog.show(
      context,
      result: const UpdateCheckResult(
        status: UpdateStatus.forceUpdate,
        currentVersion: '1.0.0',
        minVersion: '2.0.0',
      ),
      onUpdate: () => Navigator.of(context).pop(),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('continue using Crush.'), findsOneWidget);
    expect(find.textContaining('continue using CRUSH.'), findsNothing);

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();
    await showFuture;
  });

  testWidgets('required update default message uses Crush brand', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    final showFuture = UpdateDialog.show(
      context,
      result: const UpdateCheckResult(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        minVersion: '2.0.0',
      ),
      onUpdate: () => Navigator.of(context).pop(),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('A new version of Crush is available.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('A new version of CRUSH is available.'),
      findsNothing,
    );

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();
    await showFuture;
  });

  testWidgets('optional update default message uses Crush brand', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    final showFuture = UpdateDialog.show(
      context,
      result: const UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        currentVersion: '1.0.0',
        minVersion: '2.0.0',
      ),
      onUpdate: () => Navigator.of(context).pop(),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('A new version of Crush is available with new'),
      findsOneWidget,
    );
    expect(
      find.textContaining('A new version of CRUSH is available with new'),
      findsNothing,
    );

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();
    await showFuture;
  });

  testWidgets('helper open-close flow supports branding regression checks', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await showAndCloseDialog(
      tester,
      context: context,
      status: UpdateStatus.updateAvailable,
    );
    expect(find.byType(UpdateDialog), findsNothing);
  });
}
