import 'dart:convert';
import 'dart:io';

import 'package:crushhour/features/profile/presentation/widgets/profile_media_picker.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _transparentPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8AABQMBgAwvq9kAAAAASUVORK5CYII=',
);

void main() {
  group('ProfileMediaPicker source selection UI', () {
    Future<void> pumpPicker(
      WidgetTester tester, {
      required TargetPlatform platform,
      required double width,
      List<String> initialPhotos = const <String>[],
      ValueChanged<ProfileMediaSelection>? onChanged,
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
              initialPhotos: initialPhotos,
              initialVideos: const <String>[],
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'opens anchored popup source menu on iPad width with iOS platform',
      (tester) async {
        await pumpPicker(tester, platform: TargetPlatform.iOS, width: 820);

        await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
      },
    );

    testWidgets('opens bottom-sheet source menu on Android', (tester) async {
      await pumpPicker(tester, platform: TargetPlatform.android, width: 820);

      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('moves photos with explicit reorder buttons', (tester) async {
      ProfileMediaSelection? latestSelection;
      final tempDir = Directory.systemTemp.createTempSync(
        'profile_media_picker_test_',
      );
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
      final firstPhoto = File('${tempDir.path}/photo_a.png')
        ..writeAsBytesSync(_transparentPngBytes);
      final secondPhoto = File('${tempDir.path}/photo_b.png')
        ..writeAsBytesSync(_transparentPngBytes);

      await pumpPicker(
        tester,
        platform: TargetPlatform.android,
        width: 820,
        initialPhotos: <String>[firstPhoto.path, secondPhoto.path],
        onChanged: (selection) => latestSelection = selection,
      );

      await tester.tap(find.byTooltip('Move photo 2 earlier'));
      await tester.pumpAndSettle();

      expect(latestSelection, isNotNull);
      expect(latestSelection!.photos, <String>[
        secondPhoto.path,
        firstPhoto.path,
      ]);
      expect(latestSelection!.primaryPhotoIndex, 1);
    });
  });
}
