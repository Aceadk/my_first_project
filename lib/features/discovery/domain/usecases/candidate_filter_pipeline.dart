import 'package:equatable/equatable.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/usecases/matching_decision_engine.dart';

/// The reason a candidate profile was removed from the discovery deck.
///
/// Every rejected candidate is tagged with exactly one reason — the first one
/// that applies in the documented precedence order (see
/// [CandidateFilterPipeline.apply]). Surfacing a typed reason for every
/// removal is what lets us *prove* there is no candidate leakage (MATCH-002)
/// and lets [MatchQualityAnalytics] report rejection causes (MATCH-003).
enum FilterRejectionReason {
  /// The candidate is the viewer themselves.
  selfProfile,

  /// The viewer has blocked, or been blocked by, this candidate. Safety filter.
  blocked,

  /// The viewer has already swiped on this candidate in the current session.
  alreadySwiped,

  /// The candidate opted out of discovery (`hideFromDiscovery`).
  hiddenFromDiscovery,

  /// The candidate is in incognito mode and the viewer is not on their
  /// visibility allowlist (e.g. has not been liked by the candidate).
  incognito,

  /// The candidate's age falls outside the viewer's configured range.
  ageOutOfRange,

  /// The candidate's gender is not in the viewer's "show me" preferences.
  genderNotPreferred,

  /// The candidate shares fewer interests than the viewer's hard minimum.
  insufficientSharedInterests,

  /// The candidate is farther than the viewer's maximum distance.
  outOfDistance,

  /// A distance filter is active but the candidate has no location, and the
  /// caller asked to exclude location-less candidates.
  missingLocation,
}

/// Stable snake_case key for a [FilterRejectionReason], suitable for analytics
/// parameter names. Kept here (next to the enum) so the telemetry layer never
/// hard-codes string literals that could drift from the enum.
extension FilterRejectionReasonKey on FilterRejectionReason {
  String get analyticsKey {
    switch (this) {
      case FilterRejectionReason.selfProfile:
        return 'self_profile';
      case FilterRejectionReason.blocked:
        return 'blocked';
      case FilterRejectionReason.alreadySwiped:
        return 'already_swiped';
      case FilterRejectionReason.hiddenFromDiscovery:
        return 'hidden_from_discovery';
      case FilterRejectionReason.incognito:
        return 'incognito';
      case FilterRejectionReason.ageOutOfRange:
        return 'age_out_of_range';
      case FilterRejectionReason.genderNotPreferred:
        return 'gender_not_preferred';
      case FilterRejectionReason.insufficientSharedInterests:
        return 'insufficient_shared_interests';
      case FilterRejectionReason.outOfDistance:
        return 'out_of_distance';
      case FilterRejectionReason.missingLocation:
        return 'missing_location';
    }
  }
}

/// A single rejected candidate paired with the reason it was removed.
class CandidateRejection extends Equatable {
  const CandidateRejection({required this.profileId, required this.reason});

  final String profileId;
  final FilterRejectionReason reason;

  @override
  List<Object?> get props => [profileId, reason];

  @override
  String toString() => 'CandidateRejection($profileId, ${reason.name})';
}

/// The complete, immutable set of constraints applied to a candidate batch.
///
/// Bundling every input into one object (rather than a long parameter list)
/// keeps the pipeline call site readable and makes the filter contract
/// self-documenting. All collections are defensively normalized inside the
/// pipeline, so callers may pass raw user data.
class CandidateFilterCriteria extends Equatable {
  const CandidateFilterCriteria({
    this.viewerId,
    this.minAge = 18,
    this.maxAge = 100,
    this.showMeGenders = const <String>[],
    this.viewerInterests = const <String>[],
    this.minSharedInterests = 0,
    this.distanceFilter = const DiscoveryFilter(),
    this.blockedProfileIds = const <String>{},
    this.alreadySwipedProfileIds = const <String>{},
    this.incognitoVisibleToViewerIds = const <String>{},
    this.includeProfilesWithoutLocation = true,
  });

  /// The viewer's profile id, used to drop their own card from the deck.
  final String? viewerId;

  /// Inclusive lower age bound. If [minAge] > [maxAge] the two are swapped
  /// (defensive normalization) rather than rejecting everything.
  final int minAge;

  /// Inclusive upper age bound.
  final int maxAge;

  /// Genders the viewer wants to see. Empty means "no gender restriction".
  final List<String> showMeGenders;

  /// The viewer's own interests, used when [minSharedInterests] > 0.
  final List<String> viewerInterests;

  /// Hard minimum number of shared interests. Defaults to 0 (interests are a
  /// ranking signal, not a hard filter, unless the caller opts in).
  final int minSharedInterests;

  /// Distance / passport constraints. Reuses the existing [DiscoveryFilter].
  final DiscoveryFilter distanceFilter;

  /// Ids the viewer has blocked or been blocked by. Always removed (safety).
  final Set<String> blockedProfileIds;

  /// Ids already swiped this session, removed to avoid repeats.
  final Set<String> alreadySwipedProfileIds;

  /// Ids of incognito candidates that should still be visible to this viewer
  /// (e.g. candidates who already liked the viewer).
  final Set<String> incognitoVisibleToViewerIds;

  /// Whether candidates without a location pass an active distance filter.
  final bool includeProfilesWithoutLocation;

  @override
  List<Object?> get props => [
    viewerId,
    minAge,
    maxAge,
    showMeGenders,
    viewerInterests,
    minSharedInterests,
    distanceFilter.maxDistanceKm,
    distanceFilter.passportModeEnabled,
    distanceFilter.effectiveLatitude,
    distanceFilter.effectiveLongitude,
    blockedProfileIds,
    alreadySwipedProfileIds,
    incognitoVisibleToViewerIds,
    includeProfilesWithoutLocation,
  ];
}

/// The outcome of running a candidate batch through the filter pipeline.
class CandidateFilterResult extends Equatable {
  const CandidateFilterResult({
    required this.accepted,
    required this.rejections,
  });

  /// Candidates that passed every filter, in their original input order.
  final List<Profile> accepted;

  /// One [CandidateRejection] per removed candidate, in input order.
  final List<CandidateRejection> rejections;

  /// Aggregated count of rejections by reason. Useful for telemetry and for
  /// asserting "nothing leaked" in tests.
  Map<FilterRejectionReason, int> get rejectionCounts {
    final counts = <FilterRejectionReason, int>{};
    for (final rejection in rejections) {
      counts.update(rejection.reason, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// Total number of candidates evaluated (accepted + rejected).
  int get evaluatedCount => accepted.length + rejections.length;

  @override
  List<Object?> get props => [accepted, rejections];
}

/// Composes every discovery filter — safety, visibility, and preference — into
/// a single, predictable pipeline (MATCH-002).
///
/// ## Precedence (conflict handling)
///
/// Filters are evaluated in a fixed order and the **first** failing filter is
/// the recorded reason. Order is chosen so that safety and the candidate's own
/// privacy choices always win over the viewer's preferences:
///
///   1. [FilterRejectionReason.selfProfile]
///   2. [FilterRejectionReason.blocked]            (safety — never leaks)
///   3. [FilterRejectionReason.alreadySwiped]
///   4. [FilterRejectionReason.hiddenFromDiscovery] (candidate opted out)
///   5. [FilterRejectionReason.incognito]           (candidate privacy)
///   6. [FilterRejectionReason.ageOutOfRange]
///   7. [FilterRejectionReason.genderNotPreferred]
///   8. [FilterRejectionReason.insufficientSharedInterests]
///   9. distance: [FilterRejectionReason.missingLocation] /
///      [FilterRejectionReason.outOfDistance]
///
/// ## Documented conflict resolutions
///
/// * **Passport vs distance** — when [DiscoveryFilter.passportModeEnabled] is
///   true the distance filter is bypassed entirely (handled inside
///   [MatchingDecisionEngine.passesDistanceFilter] semantics, reproduced here
///   so we can distinguish "missing location" from "too far").
/// * **Invalid age range** — if `minAge > maxAge` the bounds are swapped rather
///   than silently rejecting every candidate.
/// * **Empty gender preference** — treated as "show all genders", not "show
///   none".
/// * **Incognito allowlist** — an incognito candidate is only shown when their
///   id is in [CandidateFilterCriteria.incognitoVisibleToViewerIds].
class CandidateFilterPipeline {
  const CandidateFilterPipeline._();

  /// Runs [candidates] through every filter described by [criteria].
  static CandidateFilterResult apply({
    required Iterable<Profile> candidates,
    required CandidateFilterCriteria criteria,
  }) {
    // Normalize the viewer-supplied collections once, up front.
    final normalizedShowMe = criteria.showMeGenders
        .map((gender) => gender.trim().toLowerCase())
        .where((gender) => gender.isNotEmpty)
        .toSet();
    final normalizedViewerInterests = criteria.viewerInterests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    // Defensive age-range normalization (invalid ranges are swapped).
    final lowerAge = criteria.minAge <= criteria.maxAge
        ? criteria.minAge
        : criteria.maxAge;
    final upperAge = criteria.minAge <= criteria.maxAge
        ? criteria.maxAge
        : criteria.minAge;

    final accepted = <Profile>[];
    final rejections = <CandidateRejection>[];

    for (final candidate in candidates) {
      final reason = _evaluate(
        candidate: candidate,
        criteria: criteria,
        normalizedShowMe: normalizedShowMe,
        normalizedViewerInterests: normalizedViewerInterests,
        lowerAge: lowerAge,
        upperAge: upperAge,
      );

      if (reason == null) {
        accepted.add(candidate);
      } else {
        rejections.add(
          CandidateRejection(profileId: candidate.id, reason: reason),
        );
      }
    }

    return CandidateFilterResult(accepted: accepted, rejections: rejections);
  }

  /// Returns the first failing [FilterRejectionReason], or null if the
  /// candidate passes every filter. The ordering of the checks below is the
  /// public precedence contract documented on [CandidateFilterPipeline].
  static FilterRejectionReason? _evaluate({
    required Profile candidate,
    required CandidateFilterCriteria criteria,
    required Set<String> normalizedShowMe,
    required Set<String> normalizedViewerInterests,
    required int lowerAge,
    required int upperAge,
  }) {
    // 1. Self.
    if (criteria.viewerId != null && candidate.id == criteria.viewerId) {
      return FilterRejectionReason.selfProfile;
    }

    // 2. Blocked (safety — highest priority after self).
    if (criteria.blockedProfileIds.contains(candidate.id)) {
      return FilterRejectionReason.blocked;
    }

    // 3. Already swiped this session.
    if (criteria.alreadySwipedProfileIds.contains(candidate.id)) {
      return FilterRejectionReason.alreadySwiped;
    }

    // 4. Candidate opted out of discovery.
    if (candidate.preferences.hideFromDiscovery) {
      return FilterRejectionReason.hiddenFromDiscovery;
    }

    // 5. Candidate is incognito and the viewer is not allowlisted.
    if (candidate.preferences.incognitoMode &&
        !criteria.incognitoVisibleToViewerIds.contains(candidate.id)) {
      return FilterRejectionReason.incognito;
    }

    // 6. Age range (bounds already normalized by the caller).
    if (candidate.age < lowerAge || candidate.age > upperAge) {
      return FilterRejectionReason.ageOutOfRange;
    }

    // 7. Gender preference (empty set = no restriction).
    if (normalizedShowMe.isNotEmpty &&
        !normalizedShowMe.contains(candidate.gender.trim().toLowerCase())) {
      return FilterRejectionReason.genderNotPreferred;
    }

    // 8. Shared-interest hard minimum (opt-in; default threshold 0 = off).
    if (criteria.minSharedInterests > 0) {
      final shared = _sharedInterestCount(
        candidate: candidate,
        normalizedViewerInterests: normalizedViewerInterests,
      );
      if (shared < criteria.minSharedInterests) {
        return FilterRejectionReason.insufficientSharedInterests;
      }
    }

    // 9. Distance / passport (last, since it is the most expensive check).
    return _distanceRejection(
      candidate: candidate,
      filter: criteria.distanceFilter,
      includeProfilesWithoutLocation: criteria.includeProfilesWithoutLocation,
    );
  }

  /// Number of normalized interests shared between candidate and viewer.
  static int _sharedInterestCount({
    required Profile candidate,
    required Set<String> normalizedViewerInterests,
  }) {
    if (normalizedViewerInterests.isEmpty) {
      return 0;
    }
    final candidateInterests = candidate.interests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();
    return candidateInterests
        .where(normalizedViewerInterests.contains)
        .length;
  }

  /// Distance check that distinguishes "missing location" from "too far",
  /// mirroring the bypass rules in [MatchingDecisionEngine.passesDistanceFilter]
  /// (passport mode and absent user location both bypass the filter).
  static FilterRejectionReason? _distanceRejection({
    required Profile candidate,
    required DiscoveryFilter filter,
    required bool includeProfilesWithoutLocation,
  }) {
    if (filter.passportModeEnabled || filter.maxDistanceKm == null) {
      return null;
    }

    final userLat = filter.effectiveLatitude;
    final userLng = filter.effectiveLongitude;
    if (userLat == null || userLng == null) {
      // We cannot compute distance without the viewer's location, so we do not
      // reject on distance grounds.
      return null;
    }

    final candidateLat = candidate.latitude;
    final candidateLng = candidate.longitude;
    if (candidateLat == null || candidateLng == null) {
      return includeProfilesWithoutLocation
          ? null
          : FilterRejectionReason.missingLocation;
    }

    final distanceKm = MatchingDecisionEngine.haversineDistanceKm(
      lat1: userLat,
      lon1: userLng,
      lat2: candidateLat,
      lon2: candidateLng,
    );
    return distanceKm <= filter.maxDistanceKm!
        ? null
        : FilterRejectionReason.outOfDistance;
  }
}
