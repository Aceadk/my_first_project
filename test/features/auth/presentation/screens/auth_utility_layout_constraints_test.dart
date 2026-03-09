import 'package:crushhour/features/auth/presentation/screens/new_device_screen.dart';
import 'package:crushhour/features/auth/presentation/widgets/auth_utility_layout_constraints.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authUtilityMaxWidthFor', () {
    test('maps widths using responsive breakpoints', () {
      expect(authUtilityMaxWidthFor(390), double.infinity);
      expect(authUtilityMaxWidthFor(820), 600);
      expect(authUtilityMaxWidthFor(1280), 680);
    });
  });

  group('NewDeviceScreen responsive utility constraint', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required double width,
    }) async {
      tester.view
        ..physicalSize = Size(width, 1000)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NewDeviceScreen(),
        ),
      );
      await tester.pumpAndSettle();
    }

    ConstrainedBox utilityConstrainedBox(WidgetTester tester) {
      final finder = find.byKey(authUtilityContentConstraintKey);
      expect(finder, findsOneWidget);
      return tester.widget<ConstrainedBox>(finder);
    }

    testWidgets('keeps mobile utility layout unconstrained', (tester) async {
      await pumpScreen(tester, width: 390);
      expect(utilityConstrainedBox(tester).constraints.maxWidth, double.infinity);
    });

    testWidgets('caps utility layout width on tablet and desktop', (
      tester,
    ) async {
      await pumpScreen(tester, width: 820);
      expect(utilityConstrainedBox(tester).constraints.maxWidth, 600);

      await pumpScreen(tester, width: 1280);
      expect(utilityConstrainedBox(tester).constraints.maxWidth, 680);
    });
  });
}
