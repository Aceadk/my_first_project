import 'package:crushhour/design_system/widgets/match_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget host(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  MatchCelebration buildCelebration({
    VoidCallback? onSendMessage,
    VoidCallback? onKeepSwiping,
    VoidCallback? onDismiss,
  }) {
    return MatchCelebration(
      yourImageUrl: 'bad://your-image',
      matchImageUrl: 'bad://match-image',
      matchName: 'Alex',
      onSendMessage: onSendMessage,
      onKeepSwiping: onKeepSwiping,
      onDismiss: onDismiss,
    );
  }

  group('MatchCelebration', () {
    testWidgets('renders core copy and action buttons', (tester) async {
      await tester.pumpWidget(host(buildCelebration()));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("It's a Match!"), findsOneWidget);
      expect(find.text('You and Alex liked each other'), findsOneWidget);
      expect(find.text('Send a Message'), findsOneWidget);
      expect(find.text('Keep Swiping'), findsOneWidget);
    });

    testWidgets('invokes action and dismiss callbacks', (tester) async {
      var sent = 0;
      var kept = 0;
      var dismissed = 0;

      await tester.pumpWidget(
        host(
          buildCelebration(
            onSendMessage: () => sent++,
            onKeepSwiping: () => kept++,
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text('Send a Message'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Keep Swiping'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(4, 4));
      await tester.pump(const Duration(milliseconds: 100));

      expect(sent, 1);
      expect(kept, 1);
      expect(dismissed, 1);
    });

    testWidgets('show opens dialog and closes through keep swiping', (
      tester,
    ) async {
      var kept = 0;
      var sent = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    MatchCelebration.show(
                      context: context,
                      yourImageUrl: 'bad://your-image',
                      matchImageUrl: 'bad://match-image',
                      matchName: 'Jordan',
                      onSendMessage: () => sent++,
                      onKeepSwiping: () => kept++,
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text("It's a Match!"), findsOneWidget);
      expect(find.text('You and Jordan liked each other'), findsOneWidget);

      await tester.tap(find.text('Keep Swiping'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(kept, 1);
      expect(sent, 0);
      expect(find.text('You and Jordan liked each other'), findsNothing);
    });
  });
}
