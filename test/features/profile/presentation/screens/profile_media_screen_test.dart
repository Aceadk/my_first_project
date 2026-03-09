import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileMediaScreen photo grid', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileMediaScreen(profile: _testProfile()),
        ),
      );
      await tester.pumpAndSettle();
    }

    SliverGridDelegateWithFixedCrossAxisCount gridDelegate(
      WidgetTester tester,
    ) {
      final grid = tester.widget<GridView>(find.byType(GridView));
      return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    }

    testWidgets('uses 2 columns on phone widths', (tester) async {
      await pumpScreen(tester, width: 390);

      expect(gridDelegate(tester).crossAxisCount, 2);
    });

    testWidgets('uses 3 columns on tablet widths', (tester) async {
      await pumpScreen(tester, width: 820);

      expect(gridDelegate(tester).crossAxisCount, 3);
    });

    testWidgets('uses 4 columns on large tablet widths', (tester) async {
      await pumpScreen(tester, width: 1200);

      expect(gridDelegate(tester).crossAxisCount, 4);
    });
  });
}

Profile _testProfile() {
  return const Profile(
    id: 'profile-1',
    name: 'Taylor',
    age: 27,
    gender: 'female',
    photoUrls: <String>[
      'https://example.com/photo-1.jpg',
      'https://example.com/photo-2.jpg',
      'https://example.com/photo-3.jpg',
      'https://example.com/photo-4.jpg',
    ],
    videoUrls: <String>[],
    bio: 'Bio',
    interests: <String>['music'],
    country: 'US',
    city: 'Austin',
    isVerified: false,
    preferences: DiscoveryPreferences(
      minAge: 18,
      maxAge: 40,
      maxDistanceKm: 50,
      showMeGenders: <String>['male', 'female'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'US',
      city: 'Austin',
    ),
  );
}
