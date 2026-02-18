import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/features/chat/domain/services/ice_breaker_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _prefs = DiscoveryPreferences(
  minAge: 18,
  maxAge: 35,
  maxDistanceKm: 60,
  showMeGenders: ['female', 'male'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'NYC',
);

void main() {
  group('IceBreakerService', () {
    test('returns generic suggestions when profile is null', () {
      final suggestions = IceBreakerService.getSuggestions(maxCount: 4);

      expect(suggestions.length, 4);
      expect(
        suggestions.every(
          (s) => {
            IceBreakerCategory.fun,
            IceBreakerCategory.thisOrThat,
            IceBreakerCategory.getToKnow,
            IceBreakerCategory.compliment,
            IceBreakerCategory.greeting,
          }.contains(s.category),
        ),
        isTrue,
      );
    });

    test('includes profile-based categories when profile has rich data', () {
      const profile = Profile(
        id: 'u1',
        name: 'Alex',
        age: 28,
        gender: 'male',
        sexualOrientation: null,
        bio: 'Bio',
        photoUrls: const [],
        videoUrls: const [],
        isVerified: true,
        jobTitle: 'Designer',
        company: 'Acme',
        school: 'State U',
        interests: const ['Music', 'Travel'],
        profilePrompts: const [
          ProfilePrompt(
            questionId: 'simple_pleasure',
            answer: 'Learning new things',
          ),
        ],
        livingIn: 'Brooklyn',
        pets: 'dog',
        zodiacSign: 'Aries',
        country: 'US',
        city: 'NYC',
        latitude: null,
        longitude: null,
        preferences: _prefs,
      );

      final suggestions = IceBreakerService.getSuggestions(
        otherProfile: profile,
        maxCount: 100,
      );

      // 14 generic + 7 profile-based for this fixture.
      expect(suggestions.length, 21);

      final categories = suggestions.map((s) => s.category).toSet();
      expect(categories, contains(IceBreakerCategory.interest));
      expect(categories, contains(IceBreakerCategory.prompt));
      expect(categories, contains(IceBreakerCategory.work));
      expect(categories, contains(IceBreakerCategory.location));
      expect(categories, contains(IceBreakerCategory.lifestyle));
      expect(categories, contains(IceBreakerCategory.personality));

      expect(
        suggestions.any((s) => s.text.contains("Love your answer about '")),
        isTrue,
      );
    });

    test('respects maxCount cap', () {
      const profile = Profile(
        id: 'u2',
        name: 'Taylor',
        age: 26,
        gender: 'female',
        sexualOrientation: null,
        bio: 'Hello',
        photoUrls: const [],
        videoUrls: const [],
        isVerified: false,
        jobTitle: null,
        company: null,
        school: null,
        interests: const ['Hiking'],
        country: 'US',
        city: 'LA',
        latitude: null,
        longitude: null,
        preferences: _prefs,
      );

      final suggestions = IceBreakerService.getSuggestions(
        otherProfile: profile,
        maxCount: 2,
      );

      expect(suggestions.length, 2);
    });
  });
}
