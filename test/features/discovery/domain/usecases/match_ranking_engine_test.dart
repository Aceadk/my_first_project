import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/usecases/match_ranking_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// SF coordinates reused across ranking tests.
const double _sfLat = 37.7749;
const double _sfLng = -122.4194;

Profile _profile({
  required String id,
  int age = 30,
  List<String> interests = const ['Music'],
  String city = 'San Francisco',
  double? latitude = _sfLat,
  double? longitude = _sfLng,
  bool isActive = true,
  bool isVerified = true,
  DateTime? createdAt,
}) {
  return Profile(
    id: id,
    name: id,
    age: age,
    gender: 'Woman',
    bio: 'Bio for $id',
    photoUrls: const [],
    videoUrls: const [],
    interests: interests,
    country: 'United States',
    city: city,
    latitude: latitude,
    longitude: longitude,
    isActive: isActive,
    isVerified: isVerified,
    createdAt: createdAt,
    preferences: const DiscoveryPreferences(
      minAge: 18,
      maxAge: 100,
      maxDistanceKm: 100,
      showMeGenders: [],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'United States',
      city: 'San Francisco',
    ),
  );
}

/// Returns the longest run of consecutive same-city entries in [ranked].
int _maxConsecutiveSameCity(List<RankedCandidate> ranked) {
  var maxRun = 0;
  var run = 0;
  String? current;
  for (final entry in ranked) {
    final city = entry.profile.city.toLowerCase();
    if (city == current) {
      run += 1;
    } else {
      current = city;
      run = 1;
    }
    if (run > maxRun) maxRun = run;
  }
  return maxRun;
}

void main() {
  const context = RankingContext(
    viewerLatitude: _sfLat,
    viewerLongitude: _sfLng,
    viewerInterests: ['music', 'hiking'],
    minAge: 25,
    maxAge: 35,
    referenceDistanceKm: 220,
  );

  group('MatchRankingEngine.scoreCandidate', () {
    test('a perfectly-matched candidate scores 100', () {
      final breakdown = MatchRankingEngine.scoreCandidate(
        candidate: _profile(
          id: 'perfect',
          age: 30,
          interests: const ['music', 'hiking'],
          latitude: _sfLat,
          longitude: _sfLng,
          isActive: true,
          isVerified: true,
        ),
        context: context,
        weights: const CompatibilityWeights.balanced(),
        normalizedViewerInterests: const {'music', 'hiking'},
      );

      expect(breakdown.distanceScore, closeTo(1.0, 0.0001));
      expect(breakdown.interestScore, closeTo(1.0, 0.0001));
      expect(breakdown.activityScore, closeTo(1.0, 0.0001));
      expect(breakdown.preferenceScore, closeTo(1.0, 0.0001));
      expect(breakdown.total, closeTo(100.0, 0.0001));
    });

    test('uses neutral 0.5 distance when a location is missing', () {
      final breakdown = MatchRankingEngine.scoreCandidate(
        candidate: _profile(id: 'no_loc', latitude: null, longitude: null),
        context: context,
        weights: const CompatibilityWeights.balanced(),
        normalizedViewerInterests: const {'music'},
      );
      expect(breakdown.distanceScore, closeTo(0.5, 0.0001));
    });

    test('uses neutral 0.5 interest score when viewer has no interests', () {
      final breakdown = MatchRankingEngine.scoreCandidate(
        candidate: _profile(id: 'c', interests: const ['music']),
        context: context,
        weights: const CompatibilityWeights.balanced(),
        normalizedViewerInterests: const {},
      );
      expect(breakdown.interestScore, closeTo(0.5, 0.0001));
    });

    test('all component scores stay within [0, 1] and total within [0, 100]', () {
      final breakdown = MatchRankingEngine.scoreCandidate(
        candidate: _profile(
          id: 'far_inactive',
          age: 60,
          interests: const ['cooking'],
          latitude: 34.0522,
          longitude: -118.2437,
          isActive: false,
          isVerified: false,
        ),
        context: context,
        weights: const CompatibilityWeights.balanced(),
        normalizedViewerInterests: const {'music', 'hiking'},
      );

      for (final value in [
        breakdown.distanceScore,
        breakdown.interestScore,
        breakdown.activityScore,
        breakdown.preferenceScore,
      ]) {
        expect(value, inInclusiveRange(0.0, 1.0));
      }
      expect(breakdown.total, inInclusiveRange(0.0, 100.0));
    });
  });

  group('MatchRankingEngine.rankCandidates — ordering & determinism', () {
    test('ranks higher-compatibility candidates first', () {
      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [
          _profile(
            id: 'far',
            interests: const ['cooking'],
            latitude: 34.0522,
            longitude: -118.2437,
            isActive: false,
          ),
          _profile(
            id: 'close_match',
            interests: const ['music', 'hiking'],
            latitude: _sfLat,
            longitude: _sfLng,
            isActive: true,
          ),
        ],
        context: context,
      );

      expect(ranked.first.profile.id, 'close_match');
      expect(ranked.first.rank, 0);
      expect(ranked.last.profile.id, 'far');
    });

    test('breaks ties deterministically on ascending id', () {
      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [
          _profile(id: 'zeta'),
          _profile(id: 'alpha'),
          _profile(id: 'mike'),
        ],
        context: context,
        maxConsecutiveSameCity: 0, // disable diversity for a pure score sort
      );
      expect(
        ranked.map((r) => r.profile.id),
        equals(['alpha', 'mike', 'zeta']),
      );
    });
  });

  group('MatchRankingEngine.rankCandidates — cold-start fairness', () {
    test('cold-start boost lifts a new user above an otherwise-equal old one', () {
      final newUser = _profile(
        id: 'z_new', // later id would normally sort last on a tie
        createdAt: DateTime.now(),
      );
      final oldUser = _profile(
        id: 'a_old',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );

      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [oldUser, newUser],
        context: context,
      );

      expect(ranked.first.profile.id, 'z_new');
      expect(ranked.first.breakdown.coldStartBoost, greaterThan(0));
      expect(ranked.last.breakdown.coldStartBoost, 0);
    });

    test('exposure penalty de-prioritizes recently-shown candidates', () {
      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [_profile(id: 'a'), _profile(id: 'b')],
        context: context,
        recentlyShownIds: const {'a'},
      );

      // 'a' would normally win the id tie-break, but the penalty drops it.
      expect(ranked.first.profile.id, 'b');
      expect(ranked.last.profile.id, 'a');
      expect(ranked.last.breakdown.exposurePenalty, greaterThan(0));
    });
  });

  group('MatchRankingEngine.rankCandidates — diversity', () {
    test('caps consecutive same-city candidates', () {
      // Four equal-score candidates, three from SF and one from LA. Without the
      // diversity pass the three SF cards would be consecutive.
      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [
          _profile(id: 'a', city: 'San Francisco'),
          _profile(id: 'b', city: 'San Francisco'),
          _profile(id: 'c', city: 'San Francisco'),
          _profile(id: 'd', city: 'Los Angeles'),
        ],
        context: context,
        maxConsecutiveSameCity: 2,
      );

      expect(ranked.length, 4);
      expect(_maxConsecutiveSameCity(ranked), lessThanOrEqualTo(2));
    });

    test('disabling diversity preserves pure score order', () {
      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [
          _profile(id: 'a', city: 'San Francisco'),
          _profile(id: 'b', city: 'San Francisco'),
          _profile(id: 'c', city: 'San Francisco'),
          _profile(id: 'd', city: 'Los Angeles'),
        ],
        context: context,
        maxConsecutiveSameCity: 0,
      );
      expect(
        ranked.map((r) => r.profile.id),
        equals(['a', 'b', 'c', 'd']),
      );
    });

    test('ranks are contiguous from 0', () {
      final ranked = MatchRankingEngine.rankCandidates(
        candidates: [
          _profile(id: 'a'),
          _profile(id: 'b'),
          _profile(id: 'c'),
        ],
        context: context,
      );
      expect(ranked.map((r) => r.rank), equals([0, 1, 2]));
    });
  });

  group('CompatibilityWeights', () {
    test('balanced weights sum to 1.0', () {
      expect(const CompatibilityWeights.balanced().total, closeTo(1.0, 1e-9));
    });
  });
}
