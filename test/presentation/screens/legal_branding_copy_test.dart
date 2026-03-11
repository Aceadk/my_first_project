import 'package:crushhour/presentation/screens/privacy_policy_screen.dart';
import 'package:crushhour/presentation/screens/terms_of_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets(
    'terms of service keeps Crush product name and CrushHour Inc. legal entity',
    (tester) async {
      await tester.pumpWidget(wrap(const TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome to Crush!'), findsOneWidget);
      expect(find.textContaining('operated by CrushHour Inc.'), findsOneWidget);
      expect(find.textContaining('To use Crush, you must:'), findsOneWidget);

      expect(find.textContaining('Welcome to CRUSH!'), findsNothing);
      expect(find.textContaining('To use CRUSH, you must:'), findsNothing);
    },
  );

  testWidgets(
    'privacy policy keeps Crush product name and CrushHour Inc. legal entity',
    (tester) async {
      await tester.pumpWidget(wrap(const PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Crush is operated by CrushHour Inc.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('use the Crush mobile application.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text("Children's Privacy"),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Crush is intended for users 18 years of age'),
        findsOneWidget,
      );

      expect(
        find.textContaining('use the CRUSH mobile application.'),
        findsNothing,
      );
      expect(
        find.textContaining('CRUSH is intended for users 18 years of age'),
        findsNothing,
      );
    },
  );
}
