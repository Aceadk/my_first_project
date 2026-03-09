import 'package:crushhour/features/profile/presentation/widgets/profile_media_picker.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileMediaPicker source selection UI', () {
    Future<void> pumpPicker(
      WidgetTester tester, {
      required TargetPlatform platform,
      required double width,
    }) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileMediaPicker(
              initialPhotos: const <String>[],
              initialVideos: const <String>[],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'opens anchored popup source menu on iPad width with iOS platform',
      (tester) async {
        await pumpPicker(
          tester,
          platform: TargetPlatform.iOS,
          width: 820,
        );

        await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
      },
    );

    testWidgets('opens bottom-sheet source menu on Android', (tester) async {
      await pumpPicker(
        tester,
        platform: TargetPlatform.android,
        width: 820,
      );

      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });
  });
}
