import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/usecases/candidate_filter_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a candidate profile with sensible defaults for filter tests.
Profile _candidate({
  required String id,
  int age = 28,
  String gender = 'Woman',
  List<String> interests = const ['Music'],
  String city = 'San Francisco',
  String country = 'United States',
  double? latitude,
  double? longitude,
  bool hideFromDiscovery = false,
  bool incognitoMode = false,
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
    isVerified: true,
    preferences: DiscoveryPreferences(
      minAge: 18,
      maxAge: 100,
      maxDistanceKm: 100,
      showMeGenders: const [],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: hideFromDiscovery,
      incognitoMode: incognitoMode,
      country: country,
      city: city,
    ),
  );
}

void main() {
  group('CandidateFilterPipeline — individual filters', () {
    test('removes the viewer\'s own profile', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'me'), _candidate(id: 'other')],
        criteria: const CandidateFilterCriteria(viewerId: 'me'),
      );

      expect(result.accepted.map((p) => p.id), equals(['other']));
      expect(
        result.rejections,
        contains(
          const CandidateRejection(
            profileId: 'me',
            reason: FilterRejectionReason.selfProfile,
          ),
        ),
      );
    });

    test('removes blocked profiles', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'a'), _candidate(id: 'blocked')],
        criteria: const CandidateFilterCriteria(
          blockedProfileIds: {'blocked'},
        ),
      );

      expect(result.accepted.map((p) => p.id), equals(['a']));
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.blocked,
      );
    });

    test('removes already-swiped profiles', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'fresh'), _candidate(id: 'swiped')],
        criteria: const CandidateFilterCriteria(
          alreadySwipedProfileIds: {'swiped'},
        ),
      );

      expect(result.accepted.map((p) => p.id), equals(['fresh']));
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.alreadySwiped,
      );
    });

    test('removes profiles hidden from discovery', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'hidden', hideFromDiscovery: true)],
        criteria: const CandidateFilterCriteria(),
      );

      expect(result.accepted, isEmpty);
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.hiddenFromDiscovery,
      );
    });

    test('hides incognito profiles unless the viewer is allowlisted', () {
      final candidates = [
        _candidate(id: 'incog_hidden', incognitoMode: true),
        _candidate(id: 'incog_visible', incognitoMode: true),
      ];

      final result = CandidateFilterPipeline.apply(
        candidates: candidates,
        criteria: const CandidateFilterCriteria(
          incognitoVisibleToViewerIds: {'incog_visible'},
        ),
      );

      expect(result.accepted.map((p) => p.id), equals(['incog_visible']));
      expect(
        result.rejections.single,
        const CandidateRejection(
          profileId: 'incog_hidden',
          reason: FilterRejectionReason.incognito,
        ),
      );
    });

    test('enforces the age range', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [
          _candidate(id: 'too_young', age: 19),
          _candidate(id: 'in_range', age: 30),
          _candidate(id: 'too_old', age: 55),
        ],
        criteria: const CandidateFilterCriteria(minAge: 25, maxAge: 40),
      );

      expect(result.accepted.map((p) => p.id), equals(['in_range']));
      expect(
        result.rejectionCounts[FilterRejectionReason.ageOutOfRange],
        2,
      );
    });

    test('normalizes an inverted age range instead of rejecting everyone', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'in_range', age: 30)],
        // min > max — should be swapped to [25, 40].
        criteria: const CandidateFilterCriteria(minAge: 40, maxAge: 25),
      );

      expect(result.accepted.map((p) => p.id), equals(['in_range']));
    });

    test('enforces gender preference, empty set means show all', () {
      final candidates = [
        _candidate(id: 'woman', gender: 'Woman'),
        _candidate(id: 'man', gender: 'Man'),
      ];

      final restricted = CandidateFilterPipeline.apply(
        candidates: candidates,
        criteria: const CandidateFilterCriteria(showMeGenders: ['Woman']),
      );
      expect(restricted.accepted.map((p) => p.id), equals(['woman']));
      expect(
        restricted.rejections.single.reason,
        FilterRejectionReason.genderNotPreferred,
      );

      final unrestricted = CandidateFilterPipeline.apply(
        candidates: candidates,
        criteria: const CandidateFilterCriteria(showMeGenders: []),
      );
      expect(unrestricted.accepted.length, 2);
    });

    test('enforces a shared-interest minimum only when opted in', () {
      final candidates = [
        _candidate(id: 'match', interests: const ['Music', 'Hiking']),
        _candidate(id: 'no_overlap', interests: const ['Cooking']),
      ];

      final withThreshold = CandidateFilterPipeline.apply(
        candidates: candidates,
        criteria: const CandidateFilterCriteria(
          viewerInterests: ['music', 'travel'],
          minSharedInterests: 1,
        ),
      );
      expect(withThreshold.accepted.map((p) => p.id), equals(['match']));
      expect(
        withThreshold.rejections.single.reason,
        FilterRejectionReason.insufficientSharedInterests,
      );

      // Default (threshold 0) keeps both.
      final noThreshold = CandidateFilterPipeline.apply(
        candidates: candidates,
        criteria: const CandidateFilterCriteria(
          viewerInterests: ['music', 'travel'],
        ),
      );
      expect(noThreshold.accepted.length, 2);
    });
  });

  group('CandidateFilterPipeline — distance & passport', () {
    const sfFilter = DiscoveryFilter(
      maxDistanceKm: 20,
      userLatitude: 37.7749,
      userLongitude: -122.4194,
    );

    test('rejects out-of-distance candidates', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [
          _candidate(id: 'near', latitude: 37.7790, longitude: -122.4194),
          _candidate(id: 'far', latitude: 34.0522, longitude: -118.2437),
        ],
        criteria: const CandidateFilterCriteria(distanceFilter: sfFilter),
      );

      expect(result.accepted.map((p) => p.id), equals(['near']));
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.outOfDistance,
      );
    });

    test('includes location-less candidates by default', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'no_loc')],
        criteria: const CandidateFilterCriteria(distanceFilter: sfFilter),
      );
      expect(result.accepted.map((p) => p.id), equals(['no_loc']));
    });

    test('can reject location-less candidates with reason missingLocation', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'no_loc')],
        criteria: const CandidateFilterCriteria(
          distanceFilter: sfFilter,
          includeProfilesWithoutLocation: false,
        ),
      );
      expect(result.accepted, isEmpty);
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.missingLocation,
      );
    });

    test('passport mode bypasses distance entirely', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [
          _candidate(id: 'paris', latitude: 48.8566, longitude: 2.3522),
        ],
        criteria: const CandidateFilterCriteria(
          distanceFilter: DiscoveryFilter(
            maxDistanceKm: 1,
            passportModeEnabled: true,
            userLatitude: 37.7749,
            userLongitude: -122.4194,
          ),
        ),
      );
      expect(result.accepted.map((p) => p.id), equals(['paris']));
    });
  });

  group('CandidateFilterPipeline — precedence & integrity', () {
    test('safety (blocked) wins over attribute filters', () {
      // This candidate is also out of age range, but blocked must be reported.
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'x', age: 99)],
        criteria: const CandidateFilterCriteria(
          minAge: 25,
          maxAge: 40,
          blockedProfileIds: {'x'},
        ),
      );
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.blocked,
      );
    });

    test('self precedence wins over blocked', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [_candidate(id: 'me')],
        criteria: const CandidateFilterCriteria(
          viewerId: 'me',
          blockedProfileIds: {'me'},
        ),
      );
      expect(
        result.rejections.single.reason,
        FilterRejectionReason.selfProfile,
      );
    });

    test('no leakage: accepted + rejected == evaluated, accepted all valid', () {
      final candidates = [
        _candidate(id: 'ok1', age: 30, gender: 'Woman'),
        _candidate(id: 'blocked', age: 30),
        _candidate(id: 'old', age: 80),
        _candidate(id: 'hidden', hideFromDiscovery: true),
        _candidate(id: 'ok2', age: 28, gender: 'Woman'),
        _candidate(id: 'man', gender: 'Man'),
      ];

      final result = CandidateFilterPipeline.apply(
        candidates: candidates,
        criteria: const CandidateFilterCriteria(
          minAge: 25,
          maxAge: 40,
          showMeGenders: ['Woman'],
          blockedProfileIds: {'blocked'},
        ),
      );

      expect(result.evaluatedCount, candidates.length);
      expect(
        result.accepted.length + result.rejections.length,
        candidates.length,
      );
      expect(result.accepted.map((p) => p.id), equals(['ok1', 'ok2']));
      // No rejected id appears in the accepted list.
      final acceptedIds = result.accepted.map((p) => p.id).toSet();
      for (final rejection in result.rejections) {
        expect(acceptedIds.contains(rejection.profileId), isFalse);
      }
    });

    test('rejectionCounts aggregates by reason', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [
          _candidate(id: 'old1', age: 80),
          _candidate(id: 'old2', age: 81),
          _candidate(id: 'man', gender: 'Man'),
        ],
        criteria: const CandidateFilterCriteria(
          minAge: 25,
          maxAge: 40,
          showMeGenders: ['Woman'],
        ),
      );

      expect(
        result.rejectionCounts[FilterRejectionReason.ageOutOfRange],
        2,
      );
      expect(
        result.rejectionCounts[FilterRejectionReason.genderNotPreferred],
        1,
      );
    });

    test('preserves input order of accepted candidates', () {
      final result = CandidateFilterPipeline.apply(
        candidates: [
          _candidate(id: 'c', age: 30),
          _candidate(id: 'a', age: 30),
          _candidate(id: 'b', age: 30),
        ],
        criteria: const CandidateFilterCriteria(minAge: 25, maxAge: 40),
      );
      expect(result.accepted.map((p) => p.id), equals(['c', 'a', 'b']));
    });
  });

  group('FilterRejectionReason analytics keys', () {
    test('every reason has a non-empty key under 40 chars', () {
      for (final reason in FilterRejectionReason.values) {
        expect(reason.analyticsKey, isNotEmpty);
        // Telemetry prefixes with "reject_" (7 chars); stay within Firebase 40.
        expect(('reject_${reason.analyticsKey}').length, lessThanOrEqualTo(40));
      }
    });

    test('keys are unique', () {
      final keys = FilterRejectionReason.values
          .map((reason) => reason.analyticsKey)
          .toSet();
      expect(keys.length, FilterRejectionReason.values.length);
    });
  });
}
