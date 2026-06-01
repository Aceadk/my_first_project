import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/usecases/matching_decision_engine.dart';

/// Relative weights for the four compatibility signals (MATCH-003 default
/// scheme: distance-first).
///
/// Each weight is a fraction in `[0, 1]`; the four are expected to sum to ~1.0
/// so the resulting [CompatibilityBreakdown.total] lands on a clean 0–100
/// scale. The defaults are intentionally distance-first because the product is
/// local-first (a 220 km radius), with interests a close second.
class CompatibilityWeights extends Equatable {
  const CompatibilityWeights({
    required this.distance,
    required this.interests,
    required this.activity,
    required this.preferences,
  });

  /// The shipped default: Distance 0.35 / Interests 0.30 / Activity 0.20 /
  /// Preferences 0.15.
  const CompatibilityWeights.balanced()
    : distance = 0.35,
      interests = 0.30,
      activity = 0.20,
      preferences = 0.15;

  final double distance;
  final double interests;
  final double activity;
  final double preferences;

  /// Sum of all weights; used to keep the final score on a 0–100 scale even if
  /// a caller supplies weights that do not sum to exactly 1.0.
  double get total => distance + interests + activity + preferences;

  @override
  List<Object?> get props => [distance, interests, activity, preferences];
}

/// Per-candidate, per-signal score breakdown. Every component is normalized to
/// `[0, 1]`; [total] is the weighted blend scaled to `[0, 100]` (including any
/// [coldStartBoost] and exposure penalty already folded in).
///
/// Exposing the breakdown (rather than just a number) makes ranking auditable —
/// the MATCH-001 acceptance criterion "ranking inputs are documented" — and
/// feeds quality telemetry in MATCH-003.
class CompatibilityBreakdown extends Equatable {
  const CompatibilityBreakdown({
    required this.distanceScore,
    required this.interestScore,
    required this.activityScore,
    required this.preferenceScore,
    required this.coldStartBoost,
    required this.exposurePenalty,
    required this.total,
  });

  final double distanceScore;
  final double interestScore;
  final double activityScore;
  final double preferenceScore;

  /// Fairness boost (0..1 of the cold-start allowance) applied to brand-new
  /// candidates so they get initial exposure despite sparse data.
  final double coldStartBoost;

  /// Penalty (0..1) subtracted for candidates already shown recently, so
  /// repeated deck refreshes surface fresh faces.
  final double exposurePenalty;

  /// Final blended score on a 0–100 scale.
  final double total;

  @override
  List<Object?> get props => [
    distanceScore,
    interestScore,
    activityScore,
    preferenceScore,
    coldStartBoost,
    exposurePenalty,
    total,
  ];
}

/// A candidate paired with its score breakdown and final deck position.
class RankedCandidate extends Equatable {
  const RankedCandidate({
    required this.profile,
    required this.breakdown,
    required this.rank,
  });

  final Profile profile;
  final CompatibilityBreakdown breakdown;

  /// Zero-based final position in the ranked, diversity-adjusted deck.
  final int rank;

  @override
  List<Object?> get props => [profile.id, breakdown, rank];
}

/// Immutable viewer context used to score candidates.
class RankingContext extends Equatable {
  const RankingContext({
    this.viewerLatitude,
    this.viewerLongitude,
    this.viewerInterests = const <String>[],
    this.minAge = 18,
    this.maxAge = 100,
    this.referenceDistanceKm = 220.0,
  });

  final double? viewerLatitude;
  final double? viewerLongitude;
  final List<String> viewerInterests;
  final int minAge;
  final int maxAge;

  /// Distance at which the distance score decays to 0. Defaults to the app's
  /// 220 km local radius.
  final double referenceDistanceKm;

  @override
  List<Object?> get props => [
    viewerLatitude,
    viewerLongitude,
    viewerInterests,
    minAge,
    maxAge,
    referenceDistanceKm,
  ];
}

/// Deterministic, fairness-aware ranking for the discovery deck (MATCH-001).
///
/// ## Documented ranking inputs
///
/// * **Distance (weight 0.35)** — linear decay from 1.0 at 0 km to 0.0 at
///   [RankingContext.referenceDistanceKm]. Missing either location yields a
///   neutral 0.5 so location-less profiles are neither buried nor boosted
///   (cold-start safe).
/// * **Interests (weight 0.30)** — Jaccard similarity (shared / union) of
///   normalized interest sets. If either side has no interests, a neutral 0.5
///   is used instead of 0.0 (cold-start safe).
/// * **Activity (weight 0.20)** — [Profile.isActive] maps to 1.0, otherwise a
///   baseline 0.35; brand-new accounts ([Profile.isNewUser]) get the baseline
///   lifted to 0.5 so they are not penalized for having no activity history.
/// * **Preferences (weight 0.15)** — how centered the candidate's age is within
///   the viewer's range (1.0 at the center, decaying to ~0.5 at the edges) plus
///   a small verified-profile bonus.
///
/// ## Cold-start & fairness
///
/// * New candidates receive an additive [coldStartBoost] (default 0.08, i.e.
///   up to 8 points) so freshly-joined users get exposure before they have
///   accumulated signal. The boost is bounded and folded into the breakdown.
/// * Candidates listed in `recentlyShownIds` get an [exposurePenalty] (default
///   0.10) subtracted, so repeated deck refreshes rotate fresh candidates to
///   the top instead of re-showing the same faces.
///
/// ## Diversity
///
/// After scoring, an optional greedy pass prevents more than
/// [maxConsecutiveSameCity] candidates from the same city appearing
/// back-to-back, improving candidate diversity in dense single-city regions
/// without disturbing the global score order more than necessary.
///
/// ## Determinism
///
/// Ties (equal final score) break on ascending profile id, so the same inputs
/// always yield the same deck — a hard requirement for the MATCH-001 test
/// fixtures.
class MatchRankingEngine {
  const MatchRankingEngine._();

  /// Default additive cold-start boost (fraction of the 0–1 scale, i.e. 0.08 →
  /// up to 8 points on the 0–100 total).
  static const double defaultColdStartBoost = 0.08;

  /// Default exposure penalty for recently-shown candidates.
  static const double defaultExposurePenalty = 0.10;

  /// Scores and ranks [candidates] for the given viewer [context].
  ///
  /// [recentlyShownIds] are de-prioritized via [exposurePenalty]. [weights]
  /// default to the shipped [CompatibilityWeights.balanced]. Set
  /// [maxConsecutiveSameCity] to 0 to disable the diversity pass.
  static List<RankedCandidate> rankCandidates({
    required Iterable<Profile> candidates,
    required RankingContext context,
    CompatibilityWeights weights = const CompatibilityWeights.balanced(),
    Set<String> recentlyShownIds = const <String>{},
    double coldStartBoost = defaultColdStartBoost,
    double exposurePenalty = defaultExposurePenalty,
    int maxConsecutiveSameCity = 2,
  }) {
    final normalizedViewerInterests = context.viewerInterests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    // 1. Score every candidate into an intermediate scored list.
    final scored = <RankedCandidate>[];
    for (final candidate in candidates) {
      final breakdown = scoreCandidate(
        candidate: candidate,
        context: context,
        weights: weights,
        normalizedViewerInterests: normalizedViewerInterests,
        coldStartBoost: coldStartBoost,
        exposurePenalty: recentlyShownIds.contains(candidate.id)
            ? exposurePenalty
            : 0.0,
      );
      // rank is assigned after sorting; use a placeholder for now.
      scored.add(
        RankedCandidate(profile: candidate, breakdown: breakdown, rank: -1),
      );
    }

    // 2. Sort by final score descending, deterministic id tie-break ascending.
    scored.sort((left, right) {
      final scoreDiff = right.breakdown.total.compareTo(left.breakdown.total);
      if (scoreDiff != 0) return scoreDiff;
      return left.profile.id.compareTo(right.profile.id);
    });

    // 3. Diversity pass (optional) over the score-ordered list.
    final ordered = maxConsecutiveSameCity > 0
        ? _applyCityDiversity(scored, maxConsecutiveSameCity)
        : scored;

    // 4. Assign final ranks.
    final result = <RankedCandidate>[];
    for (var index = 0; index < ordered.length; index++) {
      final entry = ordered[index];
      result.add(
        RankedCandidate(
          profile: entry.profile,
          breakdown: entry.breakdown,
          rank: index,
        ),
      );
    }
    return result;
  }

  /// Computes the full [CompatibilityBreakdown] for one candidate.
  ///
  /// [normalizedViewerInterests] is passed in (rather than recomputed) so batch
  /// ranking normalizes the viewer's interests exactly once.
  static CompatibilityBreakdown scoreCandidate({
    required Profile candidate,
    required RankingContext context,
    required CompatibilityWeights weights,
    required Set<String> normalizedViewerInterests,
    double coldStartBoost = defaultColdStartBoost,
    double exposurePenalty = 0.0,
  }) {
    final distanceScore = _distanceScore(candidate, context);
    final interestScore = _interestScore(candidate, normalizedViewerInterests);
    final activityScore = _activityScore(candidate);
    final preferenceScore = _preferenceScore(candidate, context);

    final weightTotal = weights.total == 0 ? 1.0 : weights.total;
    final blended =
        (distanceScore * weights.distance +
            interestScore * weights.interests +
            activityScore * weights.activity +
            preferenceScore * weights.preferences) /
        weightTotal;

    final appliedColdStart = candidate.isNewUser ? coldStartBoost : 0.0;

    // Combine, clamp to [0, 1], then scale to [0, 100].
    final adjusted = (blended + appliedColdStart - exposurePenalty).clamp(
      0.0,
      1.0,
    );

    return CompatibilityBreakdown(
      distanceScore: distanceScore,
      interestScore: interestScore,
      activityScore: activityScore,
      preferenceScore: preferenceScore,
      coldStartBoost: appliedColdStart,
      exposurePenalty: exposurePenalty,
      total: adjusted * 100.0,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Individual signal scorers (all return values in [0, 1]).
  // ───────────────────────────────────────────────────────────────────────

  /// Linear distance decay; neutral 0.5 when either location is unknown.
  static double _distanceScore(Profile candidate, RankingContext context) {
    final viewerLat = context.viewerLatitude;
    final viewerLng = context.viewerLongitude;
    final candidateLat = candidate.latitude;
    final candidateLng = candidate.longitude;

    if (viewerLat == null ||
        viewerLng == null ||
        candidateLat == null ||
        candidateLng == null) {
      return 0.5;
    }

    final distanceKm = MatchingDecisionEngine.haversineDistanceKm(
      lat1: viewerLat,
      lon1: viewerLng,
      lat2: candidateLat,
      lon2: candidateLng,
    );

    final reference = context.referenceDistanceKm <= 0
        ? 1.0
        : context.referenceDistanceKm;
    final normalized = 1.0 - (distanceKm / reference);
    return normalized.clamp(0.0, 1.0);
  }

  /// Jaccard similarity of interest sets; neutral 0.5 when either set is empty.
  static double _interestScore(
    Profile candidate,
    Set<String> normalizedViewerInterests,
  ) {
    final candidateInterests = candidate.interests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    if (normalizedViewerInterests.isEmpty || candidateInterests.isEmpty) {
      return 0.5;
    }

    final intersection = candidateInterests
        .where(normalizedViewerInterests.contains)
        .length;
    final union = <String>{
      ...candidateInterests,
      ...normalizedViewerInterests,
    }.length;
    if (union == 0) return 0.5;
    return intersection / union;
  }

  /// Activity recency proxy from [Profile.isActive] / [Profile.isNewUser].
  static double _activityScore(Profile candidate) {
    if (candidate.isActive) {
      return 1.0;
    }
    // New accounts have no activity history yet — give them the cold-start
    // baseline rather than the inactive baseline so they aren't buried.
    return candidate.isNewUser ? 0.5 : 0.35;
  }

  /// How well the candidate fits the viewer's stated preferences: age
  /// centeredness plus a small verified bonus.
  static double _preferenceScore(Profile candidate, RankingContext context) {
    final lower = math.min(context.minAge, context.maxAge);
    final upper = math.max(context.minAge, context.maxAge);
    final center = (lower + upper) / 2.0;
    final halfSpan = (upper - lower) / 2.0;

    final double ageScore;
    if (halfSpan <= 0) {
      ageScore = candidate.age == lower ? 1.0 : 0.5;
    } else {
      final distanceFromCenter = (candidate.age - center).abs();
      // 1.0 at the center, decaying linearly to 0.5 at the range edge, and
      // continuing to decay (clamped at 0) beyond the edge.
      ageScore = (1.0 - 0.5 * (distanceFromCenter / halfSpan)).clamp(0.0, 1.0);
    }

    final verifiedBonus = candidate.isVerified ? 0.1 : 0.0;
    return (ageScore + verifiedBonus).clamp(0.0, 1.0);
  }

  // ───────────────────────────────────────────────────────────────────────
  // Diversity
  // ───────────────────────────────────────────────────────────────────────

  /// Greedy reordering that avoids more than [maxConsecutive] candidates from
  /// the same (normalized) city appearing consecutively, while otherwise
  /// preserving the score order. Deterministic.
  static List<RankedCandidate> _applyCityDiversity(
    List<RankedCandidate> sorted,
    int maxConsecutive,
  ) {
    if (sorted.length <= maxConsecutive) {
      return List<RankedCandidate>.from(sorted);
    }

    final remaining = List<RankedCandidate>.from(sorted);
    final output = <RankedCandidate>[];

    String? currentCity;
    var runLength = 0;

    while (remaining.isNotEmpty) {
      var pickIndex = 0;

      final wouldExtendRun =
          currentCity != null &&
          _cityKey(remaining.first.profile) == currentCity &&
          runLength >= maxConsecutive;

      if (wouldExtendRun) {
        // Find the highest-ranked candidate from a different city.
        final alternativeIndex = remaining.indexWhere(
          (entry) => _cityKey(entry.profile) != currentCity,
        );
        // If everyone left is from the same city, we have no choice.
        pickIndex = alternativeIndex == -1 ? 0 : alternativeIndex;
      }

      final picked = remaining.removeAt(pickIndex);
      final pickedCity = _cityKey(picked.profile);

      if (pickedCity == currentCity) {
        runLength += 1;
      } else {
        currentCity = pickedCity;
        runLength = 1;
      }

      output.add(picked);
    }

    return output;
  }

  static String _cityKey(Profile profile) => profile.city.trim().toLowerCase();
}
