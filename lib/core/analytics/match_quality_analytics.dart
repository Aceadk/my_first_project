import 'package:crushhour/features/discovery/domain/usecases/candidate_filter_pipeline.dart';

/// An analytics event ready to forward to the underlying analytics backend.
///
/// Parameters are typed `Map<String, Object>` (non-null values) because
/// Firebase Analytics only accepts `num` / `String` values — booleans are
/// encoded as `1`/`0` by the builders below, matching the convention used
/// throughout `AnalyticsService`.
class MatchQualityEvent {
  const MatchQualityEvent({required this.name, required this.parameters});

  final String name;
  final Map<String, Object> parameters;
}

/// Pure builders for discovery & match-quality telemetry (MATCH-003).
///
/// These functions contain *only* the event-shaping logic — no Firebase, no
/// I/O — so they are exhaustively unit-testable in isolation. `AnalyticsService`
/// exposes thin wrappers (`logDiscoveryDeckDepleted`, …) that emit the events
/// these builders produce.
///
/// The events focus on the *quality* signals needed to diagnose poor discovery
/// and prioritize backlog:
///
/// * [deckDepleted] — how deep the deck got before running out, and *why*
///   candidates were filtered away.
/// * [candidateRejections] — the aggregated reason breakdown for a single
///   fetch, so we can see whether (say) distance or age is starving the deck.
/// * [rankingQuality] — score distribution and cold-start share of a ranked
///   deck.
/// * [matchConversion] — whether a match turned into a conversation.
///
/// All rejection reasons are keyed off [FilterRejectionReason.analyticsKey], so
/// event parameters never drift from the enum, and every key stays within
/// Firebase's 40-character limit by construction (verified in tests).
class MatchQualityEvents {
  const MatchQualityEvents._();

  static const String eventDeckDepleted = 'discovery_deck_depleted';
  static const String eventCandidateRejections =
      'discovery_candidate_rejections';
  static const String eventRankingQuality = 'discovery_ranking_quality';
  static const String eventMatchConversion = 'discovery_match_conversion';

  /// Prefix applied to each rejection-reason count parameter.
  static const String rejectionParamPrefix = 'reject_';

  /// Builds the deck-depletion event, including the rejection breakdown.
  static MatchQualityEvent deckDepleted({
    required int deckDepth,
    required int swipesBeforeEmpty,
    Map<FilterRejectionReason, int> rejectionCounts =
        const <FilterRejectionReason, int>{},
  }) {
    return MatchQualityEvent(
      name: eventDeckDepleted,
      parameters: <String, Object>{
        'deck_depth': deckDepth,
        'swipes_before_empty': swipesBeforeEmpty,
        'total_rejected': _sum(rejectionCounts),
        ..._flattenRejections(rejectionCounts),
      },
    );
  }

  /// Builds the per-fetch candidate-rejection breakdown event.
  static MatchQualityEvent candidateRejections({
    required int evaluatedCount,
    required int acceptedCount,
    required Map<FilterRejectionReason, int> rejectionCounts,
  }) {
    return MatchQualityEvent(
      name: eventCandidateRejections,
      parameters: <String, Object>{
        'evaluated_count': evaluatedCount,
        'accepted_count': acceptedCount,
        'rejected_count': _sum(rejectionCounts),
        ..._flattenRejections(rejectionCounts),
      },
    );
  }

  /// Builds a quality snapshot of a freshly-ranked deck. Scores are expected on
  /// the 0–100 scale produced by the ranking engine and are rounded to ints.
  static MatchQualityEvent rankingQuality({
    required int candidateCount,
    required double topScore,
    required double averageScore,
    required int coldStartCount,
  }) {
    return MatchQualityEvent(
      name: eventRankingQuality,
      parameters: <String, Object>{
        'candidate_count': candidateCount,
        'top_score': topScore.round(),
        'average_score': averageScore.round(),
        'cold_start_count': coldStartCount,
      },
    );
  }

  /// Builds the post-match conversion event. [secondsToFirstMessage] is null
  /// when no message was sent; `converted` is encoded as `1`/`0` (Firebase
  /// does not accept boolean parameter values).
  static MatchQualityEvent matchConversion({
    required String matchId,
    int? secondsToFirstMessage,
  }) {
    return MatchQualityEvent(
      name: eventMatchConversion,
      parameters: <String, Object>{
        'match_id': matchId,
        'converted': secondsToFirstMessage != null ? 1 : 0,
        'seconds_to_first_message': ?secondsToFirstMessage,
      },
    );
  }

  /// Flattens a rejection-count map into `reject_<reason>: count` parameters,
  /// omitting reasons with a zero count to keep payloads compact.
  static Map<String, Object> _flattenRejections(
    Map<FilterRejectionReason, int> rejectionCounts,
  ) {
    final flattened = <String, Object>{};
    for (final entry in rejectionCounts.entries) {
      if (entry.value <= 0) {
        continue;
      }
      flattened['$rejectionParamPrefix${entry.key.analyticsKey}'] = entry.value;
    }
    return flattened;
  }

  static int _sum(Map<FilterRejectionReason, int> counts) {
    var total = 0;
    for (final value in counts.values) {
      if (value > 0) {
        total += value;
      }
    }
    return total;
  }
}
