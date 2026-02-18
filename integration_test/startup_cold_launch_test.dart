import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:crushhour/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Startup Cold Launch', () {
    testWidgets(
      'renders first frame within timeout',
      (tester) async {
        final stopwatch = Stopwatch()..start();

        await app.main();
        await _pumpUntilFound(
          tester: tester,
          finder: find.byKey(const Key('startup_loading_content')),
          timeout: const Duration(seconds: 2),
        );

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'Cold launch first frame exceeded timeout. App may be blocking before render.',
        );

        // Allow startup timeout-guarded tasks to complete before test teardown.
        await tester.pump(const Duration(seconds: 20));
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

Future<void> _pumpUntilFound({
  required WidgetTester tester,
  required Finder finder,
  required Duration timeout,
  Duration step = const Duration(milliseconds: 50),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure(
    'Expected startup first frame marker was not visible within ${timeout.inMilliseconds}ms.',
  );
}
