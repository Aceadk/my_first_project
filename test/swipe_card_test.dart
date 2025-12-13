import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_project/data/models/preferences.dart';
import 'package:my_first_project/data/models/profile.dart';
import 'package:my_first_project/presentation/widgets/swipe_card.dart';

void main() {
  testWidgets('SwipeCard shows verified badge', (tester) async {
    const prefs = DiscoveryPreferences(
      minAge: 18,
      maxAge: 30,
      maxDistanceKm: 50,
      showMeGenders: ['women', 'men'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'US',
      city: 'NYC',
    );

    final profile = Profile(
      id: 'p1',
      name: 'Alex',
      age: 25,
      gender: 'other',
      sexualOrientation: null,
      bio: 'Hello',
      photoUrls: const [],
      videoUrls: const [],
      isVerified: true,
      jobTitle: 'Engineer',
      company: 'Acme',
      school: 'State U',
      interests: const ['music'],
      country: 'US',
      city: 'NYC',
      latitude: null,
      longitude: null,
      preferences: prefs,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwipeCard(profile: profile),
      ),
    );

    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });
}
