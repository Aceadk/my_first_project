import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders localized chat report sheet reason labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en', 'XA'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatReportSheetContent(
            matchId: 'match-123',
            onReasonSelected: _noopSelect,
            onViewGuidelines: _noop,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Last match: match-123 xxxx'), findsOneWidget);
    expect(find.text('Spam or scams xxxx'), findsOneWidget);
    expect(find.text('Harassment or hate xxxx'), findsOneWidget);
    expect(find.text('Inappropriate content xxxx'), findsOneWidget);
    expect(find.text('Fake profile xxxx'), findsOneWidget);
    expect(find.text('Other xxxx'), findsOneWidget);
  });
}

Future<void> _noopSelect(ChatReportReasonOption _) async {}

void _noop() {}
