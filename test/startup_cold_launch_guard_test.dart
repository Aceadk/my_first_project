import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Startup Cold Launch Guard', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'first frame marker is visible within timeout',
      (tester) async {
        // Save the original ErrorWidget.builder — app.main() installs a custom
        // one via installErrorWidgetBuilder(). The framework verifies it hasn't
        // changed before tearDown runs, so we must restore inside the body.
        final originalErrorBuilder = ErrorWidget.builder;
        try {
          await app.main();
          await _pumpUntilFound(
            tester: tester,
            finder: find.byKey(const Key('startup_loading_content')),
            // Full-suite coverage runs can be slower than isolated test runs;
            // this still guards cold-start regressions while reducing flakes.
            timeout: const Duration(seconds: 10),
          );
        } finally {
          // Always restore ErrorWidget.builder, even if the assertion above
          // fails. This prevents secondary framework failures in tearDown.
          ErrorWidget.builder = originalErrorBuilder;

          // Allow startup timeout-guarded tasks to finish so the test binding
          // does not fail on pending timers from app bootstrap.
          await tester.pump(const Duration(seconds: 20));
          await tester.pumpAndSettle(const Duration(milliseconds: 50));
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
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
