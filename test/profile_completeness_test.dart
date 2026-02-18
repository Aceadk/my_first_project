import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
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
      photoUrls: ['a.jpg'],
      videoUrls: [],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests: ['music'],
      country: '',
      city: '',
      latitude: null,
      longitude: null,
      preferences: prefs,
    );

    final summary = evaluateProfileCompleteness(profile);
    expect(summary.score, lessThan(kSwipeMinimumCompleteness));
    // Required fields: 1 photo, 10 char bio, 3 interests, city + country
    expect(
      summary.missing,
      contains('Write a bio (at least $kMinBioLength characters)'),
    );
    expect(summary.missing, contains('Add at least $kMinInterests interests'));
    expect(summary.missing, contains('Add your city and country'));
    // Prompts are optional - shown in recommended
    expect(summary.recommended, contains('Answer prompts to stand out'));
  });

  test(
    'summary convenience getters reflect thresholds and breakdown flags',
    () {
      const completeSummary = ProfileCompletenessSummary(
        score: 1.0,
        breakdown: {
          'photos': 0.30,
          'bio': 0.25,
          'interests': 0.25,
          'location': 0.20,
          'prompts': 1.0,
        },
        missing: [],
        requiredMissing: [],
        recommended: [],
      );

      expect(completeSummary.meetsSwipeMinimum, isTrue);
      expect(completeSummary.meetsMessagingMinimum, isTrue);
      expect(completeSummary.meetsRequiredFields, isTrue);
      expect(completeSummary.hasMinPhotos, isTrue);
      expect(completeSummary.hasBio, isTrue);
      expect(completeSummary.hasPrompts, isTrue);

      const incompleteSummary = ProfileCompletenessSummary(
        score: 0.5,
        breakdown: {'photos': 0.0, 'bio': 0.0, 'prompts': 0.0},
        missing: ['x'],
        requiredMissing: ['x'],
        recommended: ['y'],
      );

      expect(incompleteSummary.meetsSwipeMinimum, isFalse);
      expect(incompleteSummary.meetsMessagingMinimum, isFalse);
      expect(incompleteSummary.meetsRequiredFields, isFalse);
      expect(incompleteSummary.hasMinPhotos, isFalse);
      expect(incompleteSummary.hasBio, isFalse);
      expect(incompleteSummary.hasPrompts, isFalse);
    },
  );

  test('legacy prompts fallback contributes to prompts tracking', () {
    const profile = Profile(
      id: 'legacy-prompts',
      name: 'Legacy',
      age: 27,
      gender: 'female',
      sexualOrientation: null,
      bio: 'This bio is long enough.',
      photoUrls: ['a.jpg'],
      videoUrls: [],
      prompts: ['one', 'two'],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests: ['music', 'travel', 'fitness'],
      country: 'US',
      city: 'NYC',
      latitude: null,
      longitude: null,
      preferences: prefs,
    );

    final summary = evaluateProfileCompleteness(profile);
    expect(summary.breakdown['prompts'], 1.0);
    expect(summary.recommended, isEmpty);
  });

  test(
    'top-level helper functions delegate to evaluateProfileCompleteness',
    () {
      const completeProfile = Profile(
        id: 'helpers-1',
        name: 'Alex',
        age: 28,
        gender: 'male',
        sexualOrientation: null,
        bio: 'Long enough biography text.',
        photoUrls: ['a.jpg'],
        videoUrls: [],
        prompts: ['p1', 'p2'],
        isVerified: false,
        jobTitle: null,
        company: null,
        school: null,
        interests: ['music', 'reading', 'running'],
        country: 'US',
        city: 'Austin',
        latitude: null,
        longitude: null,
        preferences: prefs,
      );

      const incompleteProfile = Profile(
        id: 'helpers-2',
        name: 'Sam',
        age: 24,
        gender: 'female',
        sexualOrientation: null,
        bio: 'short',
        photoUrls: [],
        videoUrls: [],
        prompts: [],
        isVerified: false,
        jobTitle: null,
        company: null,
        school: null,
        interests: ['music'],
        country: '',
        city: '',
        latitude: null,
        longitude: null,
        preferences: prefs,
      );

      final completeScore = computeProfileCompleteness(completeProfile);
      final completeBreakdown = computeProfileCompletenessBreakdown(
        completeProfile,
      );

      expect(completeScore, closeTo(1.0, 0.001));
      expect(completeBreakdown['photos'], greaterThan(0));
      expect(isProfileComplete(completeProfile), isTrue);
      expect(isProfileComplete(incompleteProfile), isFalse);
      expect(computeProfileCompleteness(null), 0);
      expect(computeProfileCompletenessBreakdown(null), isEmpty);
    },
  );
}
