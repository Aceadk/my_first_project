import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/profile_completeness.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';

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

  test('evaluateProfileCompleteness returns 0 for null', () {
    expect(evaluateProfileCompleteness(null).score, 0.0);
  });

  test('weights bio length and photos more heavily', () {
    final profile = Profile(
      id: '1',
      name: 'Alice',
      age: 25,
      gender: 'female',
      sexualOrientation: 'straight',
      bio: 'This is a longer bio with more than forty characters.',
      photoUrls: const ['a.jpg', 'b.jpg', 'c.jpg'],
      videoUrls: const [],
      prompts: const ['p1', 'p2'],
      isVerified: false,
      jobTitle: 'Engineer',
      company: 'Acme',
      school: null,
      interests: const ['music', 'travel', 'tech'],
      country: 'US',
      city: 'NYC',
      latitude: null,
      longitude: null,
      preferences: prefs,
      dateOfBirth: DateTime(1998, 5, 15),
    );

    final summary = evaluateProfileCompleteness(profile);
    expect(summary.score, closeTo(1.0, 0.01));
    expect(summary.missing, isEmpty);
    expect(summary.requiredMissing, isEmpty);
  });

  test('reports missing pieces', () {
    const profile = Profile(
      id: '2',
      name: '',
      age: 25,
      gender: 'female',
      sexualOrientation: null,
      bio: '',
      photoUrls:  ['a.jpg'],
      videoUrls:  [],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests:  ['music'],
      country: '',
      city: '',
      latitude: null,
      longitude: null,
      preferences: prefs,
    );

    final summary = evaluateProfileCompleteness(profile);
    expect(summary.score, lessThan(kSwipeMinimumCompleteness));
    expect(summary.missing, contains('Write about yourself for a better profile'));
    expect(summary.missing, contains('Add interests to find better matches'));
  });
}
