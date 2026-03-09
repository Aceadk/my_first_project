import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders localized profile report sheet labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en', 'XA'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileReportSheetContent(onReasonSelected: _noopSelect),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Why are you reporting this profile? xxxx'),
      findsOneWidget,
    );
    expect(find.text('Inappropriate photos xxxx'), findsOneWidget);
    expect(find.text('Fake profile xxxx'), findsOneWidget);
    expect(find.text('Harassment xxxx'), findsOneWidget);
    expect(find.text('Scam or spam xxxx'), findsOneWidget);
    expect(find.text('Underage user xxxx'), findsOneWidget);
    expect(find.text('Other xxxx'), findsOneWidget);
  });
}

Future<void> _noopSelect(ProfileReportReasonOption _) async {}
