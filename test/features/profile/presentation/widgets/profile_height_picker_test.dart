import 'package:crushhour/features/profile/presentation/widgets/profile_height_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ProfileHeightPicker', () {
    testWidgets('shows default value and returns current height on done', (
      tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        host(ProfileHeightPicker(onSelected: (value) => selected = value)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Height'), findsOneWidget);
      expect(find.text('170 cm'), findsOneWidget);
      expect(find.text('Clear'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(selected, 170);
    });

    testWidgets('shows clear button for initial value and returns null', (
      tester,
    ) async {
      int? selected = -1;
      await tester.pumpWidget(
        host(
          ProfileHeightPicker(
            initialHeightCm: 180,
            onSelected: (value) => selected = value,
          ),
        ),
      );

      expect(find.text('180 cm'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(selected, isNull);
    });

    testWidgets('cm picker drag updates selected height', (tester) async {
      int? selected;
      await tester.pumpWidget(
        host(
          ProfileHeightPicker(
            initialHeightCm: 170,
            onSelected: (value) => selected = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cmPicker = find.byType(ListWheelScrollView).first;
      await tester.drag(cmPicker, const Offset(0, -220));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(selected, isNotNull);
      expect(selected, isNot(170));
    });

    testWidgets('ft picker toggle and drag updates selected height', (
      tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        host(
          ProfileHeightPicker(
            initialHeightCm: 170,
            onSelected: (value) => selected = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ft'));
      await tester.pumpAndSettle();
      expect(find.textContaining("'"), findsWidgets);
      expect(find.byType(ListWheelScrollView), findsNWidgets(2));

      final wheels = find.byType(ListWheelScrollView);
      await tester.drag(wheels.at(0), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.drag(wheels.at(1), const Offset(0, -120));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(selected, isNotNull);
      expect(selected, isNot(170));
    });
  });
}
