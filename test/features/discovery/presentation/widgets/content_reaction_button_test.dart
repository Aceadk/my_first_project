import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:crushhour/features/discovery/presentation/widgets/content_reaction_button.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

void main() {
  group('ContentReactionButton', () {
    testWidgets('toggles reaction picker visibility', (tester) async {
      await tester.pumpWidget(
        _app(
          child: ContentReactionButton(
            onReaction: (_) {},
            onComment: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);

      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('❤️'), findsWidgets);

      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });

    testWidgets('does not render comment action when disabled', (tester) async {
      await tester.pumpWidget(
        _app(
          child: ContentReactionButton(
            onReaction: (_) {},
            onComment: () {},
            showCommentButton: false,
            compact: true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });
  });

  group('SentReactionIndicator', () {
    testWidgets('calls completion callback after animation', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        _app(
          child: SentReactionIndicator(
            emoji: '🎉',
            onAnimationComplete: () => completed++,
          ),
        ),
      );

      expect(find.text('🎉'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(completed, equals(1));
    });
  });

  group('ReactionCommentDialog', () {
    testWidgets('returns selected reaction and comment payload on send', (
      tester,
    ) async {
      dynamic dialogResult;
      await tester.pumpWidget(
        _app(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<dynamic>(
                    context: context,
                    builder: (_) => const ReactionCommentDialog(
                      contentPreview: 'Great answer',
                      contentType: ReactionContentType.prompt,
                      initialReaction: 'like',
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('React to this answer'), findsOneWidget);
      await tester.tap(find.text('😂'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nice one!');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(dialogResult, isA<Map<String, dynamic>>());
      expect(dialogResult['reaction'], equals('laugh'));
      expect(dialogResult['comment'], equals('Nice one!'));
    });
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 120, top: 120),
          child: child,
        ),
      ),
    ),
  );
}
