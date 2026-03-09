import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/usecases/matching_decision_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _candidatePreferences = DiscoveryPreferences(
  minAge: 18,
  maxAge: 60,
  maxDistanceKm: 100,
  showMeGenders: ['Woman', 'Man', 'Non-binary'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'United States',
  city: 'San Francisco',
);

Profile _profile({
  required String id,
  int age = 28,
  String gender = 'Woman',
  List<String> interests = const ['Music'],
  String city = 'San Francisco',
  String country = 'United States',
  double? latitude,
  double? longitude,
  double? distance,
}) {
  return Profile(
    id: id,
    name: id,
    age: age,
    gender: gender,
    bio: 'Bio for $id',
    photoUrls: const [],
    videoUrls: const [],
    interests: interests,
    country: country,
    city: city,
    latitude: latitude,
    longitude: longitude,
    distance: distance,
    isVerified: true,
    preferences: _candidatePreferences,
  );
}

void main() {
  group('MatchingDecisionEngine.filterCandidates', () {
    test('applies distance and excluded-id constraints', () {
      const filter = DiscoveryFilter(
        maxDistanceKm: 20,
        userLatitude: 37.7749,
        userLongitude: -122.4194,
      );

      final candidates = [
        _profile(id: 'near', latitude: 37.7790, longitude: -122.4194),
        _profile(id: 'far', latitude: 34.0522, longitude: -118.2437),
        _profile(id: 'excluded', latitude: 37.7760, longitude: -122.4190),
      ];

      final result = MatchingDecisionEngine.filterCandidates(
        candidates: candidates,
        filter: filter,
        excludedProfileIds: const {'excluded'},
      );

      expect(result.map((profile) => profile.id), equals(['near']));
    });

    test('includes profiles without location by default', () {
      final result = MatchingDecisionEngine.filterCandidates(
        candidates: [_profile(id: 'no_location')],
        filter: const DiscoveryFilter(
          maxDistanceKm: 5,
          userLatitude: 37.7749,
          userLongitude: -122.4194,
        ),
      );

      expect(result.map((profile) => profile.id), equals(['no_location']));
    });

    test('can exclude profiles without location', () {
      final result = MatchingDecisionEngine.filterCandidates(
        candidates: [_profile(id: 'no_location')],
        filter: const DiscoveryFilter(
          maxDistanceKm: 5,
          userLatitude: 37.7749,
          userLongitude: -122.4194,
        ),
        includeProfilesWithoutLocation: false,
      );

      expect(result, isEmpty);
    });

    test('bypasses distance filter in passport mode', () {
      final result = MatchingDecisionEngine.filterCandidates(
        candidates: [
          _profile(id: 'global', latitude: 48.8566, longitude: 2.3522),
        ],
        filter: const DiscoveryFilter(
          maxDistanceKm: 1,
          passportModeEnabled: true,
          userLatitude: 37.7749,
          userLongitude: -122.4194,
        ),
      );

      expect(result.map((profile) => profile.id), equals(['global']));
    });

    test('bypasses distance filter when user location is unavailable', () {
      final result = MatchingDecisionEngine.filterCandidates(
        candidates: [
          _profile(id: 'far', latitude: 34.0522, longitude: -118.2437),
        ],
        filter: const DiscoveryFilter(maxDistanceKm: 5),
      );

      expect(result.map((profile) => profile.id), equals(['far']));
    });
  });

  group('MatchingDecisionEngine.rankTopPicks', () {
    const preferences = DiscoveryPreferences(
      minAge: 24,
      maxAge: 34,
      maxDistanceKm: 50,
      showMeGenders: ['Woman'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'United States',
      city: 'San Francisco',
    );

    test('filters by preferences and ranks by score descending', () {
      final picks = MatchingDecisionEngine.rankTopPicks(
        candidates: [
          _profile(
            id: 'best',
            age: 29,
            gender: 'Woman',
            city: 'San Francisco',
            interests: const ['Music', 'Hiking'],
          ),
          _profile(
            id: 'good',
            age: 27,
            gender: 'Woman',
            city: 'Los Angeles',
            interests: const ['Music'],
          ),
          _profile(
            id: 'wrong_gender',
            age: 28,
            gender: 'Man',
            city: 'San Francisco',
            interests: const ['Music', 'Hiking'],
          ),
          _profile(
            id: 'out_of_range',
            age: 45,
            gender: 'Woman',
            city: 'San Francisco',
            interests: const ['Music', 'Hiking'],
          ),
        ],
        preferences: preferences,
        userInterests: const ['music', 'hiking'],
      );

      expect(picks.map((profile) => profile.id), equals(['best', 'good']));
    });

    test('uses deterministic id tie-breaker when scores are equal', () {
      final picks = MatchingDecisionEngine.rankTopPicks(
        candidates: [
          _profile(id: 'zeta', age: 29, city: 'San Francisco'),
          _profile(id: 'alpha', age: 29, city: 'San Francisco'),
        ],
        preferences: preferences,
        userInterests: const ['music'],
      );

      expect(picks.map((profile) => profile.id), equals(['alpha', 'zeta']));
    });

    test('normalizes interests for compatibility scoring', () {
      final score = MatchingDecisionEngine.topPickScore(
        candidate: _profile(
          id: 'candidate',
          age: 29,
          city: 'San Francisco',
          interests: const [' Music ', 'Travel'],
        ),
        preferences: preferences,
        normalizedUserInterests: const {'music'},
      );

      expect(score, closeTo(17, 0.001));
    });

    test('enforces top-picks limit', () {
      final picks = MatchingDecisionEngine.rankTopPicks(
        candidates: [
          _profile(id: 'a', age: 29),
          _profile(id: 'b', age: 28),
          _profile(id: 'c', age: 27),
        ],
        preferences: preferences,
        userInterests: const ['music'],
        limit: 2,
      );

      expect(picks.length, 2);
    });
  });
}
