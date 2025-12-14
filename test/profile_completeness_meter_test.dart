import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_project/data/models/preferences.dart';
import 'package:my_first_project/data/models/profile.dart';
import 'package:my_first_project/presentation/widgets/profile_completeness_meter.dart';

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
    expect(find.textContaining('Add at least'), findsWidgets);
    expect(find.textContaining('Finish profile'), findsOneWidget);
  });
}
