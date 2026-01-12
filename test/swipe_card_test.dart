import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/presentation/widgets/swipe_card.dart';

const _prefs = DiscoveryPreferences(
  minAge: 18,
  maxAge: 30,
  maxDistanceKm: 50,
  showMeGenders: ['female', 'male'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'NYC',
);

void main() {
  testWidgets('SwipeCard shows verified badge', (tester) async {
    const profile = Profile(
      id: 'p1',
      name: 'Alex',
      age: 25,
      gender: 'other',
      sexualOrientation: null,
      bio: 'Hello',
      photoUrls: [],
      videoUrls: [],
      isVerified: true,
      jobTitle: 'Engineer',
      company: 'Acme',
      school: 'State U',
      interests: ['music'],
      country: 'US',
      city: 'NYC',
      latitude: null,
      longitude: null,
      preferences: _prefs,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SwipeCard(profile: profile),
      ),
    );

    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('SwipeCard shows fallbacks when data is missing', (tester) async {
    const profile = Profile(
      id: 'p2',
      name: '',
      age: 0,
      gender: 'other',
      sexualOrientation: null,
      bio: '',
      photoUrls: [],
      videoUrls: [],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests: [],
      country: '',
      city: '',
      latitude: null,
      longitude: null,
      preferences: _prefs,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SwipeCard(profile: profile),
      ),
    );

    expect(find.textContaining('Someone new'), findsOneWidget);
    expect(find.text('Location unavailable'), findsOneWidget);
    expect(find.textContaining('has not added a bio'), findsOneWidget);
  });
}
