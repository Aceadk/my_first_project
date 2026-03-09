import 'package:crushhour/features/calls/presentation/widgets/call_safety_controls.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders localized call safety controls labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en', 'XA'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CallSafetyControls(
            showSafetyTip: true,
            onDismissTip: _noop,
            onOpenGuidelines: _noop,
            onReportPressed: _noop,
            onBlockPressed: _noop,
            isBlocked: true,
            isReportedRecently: true,
            matchName: 'Alex',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Safety reminder xxxx'), findsOneWidget);
    expect(
      find.textContaining(
        'On your first call with Alex, avoid sharing private',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Dismiss safety tip xxxx'), findsOneWidget);
    expect(find.text('Reported xxxx'), findsOneWidget);
    expect(find.text('Blocked xxxx'), findsOneWidget);
  });
}

void _noop() {}
