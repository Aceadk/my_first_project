import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('otherUserProfileMaxWidthFor', () {
    test('returns breakpoint content max widths', () {
      expect(otherUserProfileMaxWidthFor(390), double.infinity);
      expect(otherUserProfileMaxWidthFor(820), 720);
      expect(otherUserProfileMaxWidthFor(1200), 960);
    });
  });

  group('OtherUserProfileScreen responsive constraints', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required double width,
    }) async {
      tester.view
        ..physicalSize = Size(width, 1200)
        ..devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OtherUserProfileScreen(
            args: OtherUserProfileArgs(
              profile: _testProfile(),
              isMatch: true,
              matchId: 'match-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.dragFrom(
        Offset(width / 2, 320),
        const Offset(0, -260),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();
    }

    ConstrainedBox actionConstrainedBox(WidgetTester tester) {
      final finder = find.byKey(otherUserProfileActionsConstraintKey);
      expect(finder, findsOneWidget);
      return tester.widget<ConstrainedBox>(finder);
    }

    testWidgets('keeps mobile actions unconstrained', (tester) async {
      await pumpScreen(tester, width: 390);

      final actions = actionConstrainedBox(tester);

      expect(actions.constraints.maxWidth, double.infinity);
    });

    testWidgets('caps actions to tablet max width', (tester) async {
      await pumpScreen(tester, width: 820);

      final actions = actionConstrainedBox(tester);

      expect(actions.constraints.maxWidth, 720);
    });

    testWidgets('caps actions to desktop max width', (tester) async {
      await pumpScreen(tester, width: 1200);

      final actions = actionConstrainedBox(tester);

      expect(actions.constraints.maxWidth, 960);
    });
  });
}

Profile _testProfile() {
  return const Profile(
    id: 'profile-1',
    name: 'Taylor',
    age: 27,
    gender: 'female',
    photoUrls: <String>[],
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
