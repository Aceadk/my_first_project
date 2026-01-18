import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/profile/presentation/widgets/profile_completeness_meter.dart';

void main() {
const prefs = DiscoveryPreferences(
  minAge: 18,
  maxAge: 45,
  maxDistanceKm: 50,
  showMeGenders: ['female', 'male'],
    showMyDistance: true,
    showMyAge: true,
    hideFromDiscovery: false,
    incognitoMode: false,
    country: 'US',
    city: 'NYC',
  );

  testWidgets('shows missing items and percent', (tester) async {
    const profile = Profile(
      id: 'p1',
      name: '',
      age: 24,
      gender: 'other',
      sexualOrientation: null,
      bio: '',
      photoUrls: ['a.jpg'],
      videoUrls: [],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests: ['music'],
      country: 'US',
      city: 'NYC',
      latitude: null,
      longitude: null,
      preferences: prefs,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileCompletenessMeter(
            profile: profile,
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Profile completeness'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Profile is missing: bio (40 chars), prompts (2), interests (need 3, has 1)
    // The widget shows up to 3 missing items as chips
    expect(find.textContaining('bio'), findsOneWidget);
    expect(find.textContaining('Finish profile'), findsOneWidget);
  });
}
