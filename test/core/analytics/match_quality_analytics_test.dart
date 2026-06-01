import 'package:crushhour/core/analytics/match_quality_analytics.dart';
import 'package:crushhour/features/discovery/domain/usecases/candidate_filter_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts that an event satisfies Firebase Analytics' structural limits:
/// event name ≤ 40 chars, ≤ 25 parameters, each key ≤ 40 chars, and each value
/// a `num` or `String` (Firebase rejects other types — booleans must be encoded
/// as 1/0). There is no validator class in the codebase, so the constraints are
/// checked inline here.
void _expectFirebaseValid(MatchQualityEvent event) {
  expect(
    event.name.length,
    lessThanOrEqualTo(40),
    reason: 'event name "${event.name}" exceeds 40 chars',
  );
  expect(
    event.parameters.length,
    lessThanOrEqualTo(25),
    reason: 'event "${event.name}" has too many parameters',
  );
  for (final entry in event.parameters.entries) {
    expect(
      entry.key.length,
      lessThanOrEqualTo(40),
      reason: 'param key "${entry.key}" exceeds 40 chars',
    );
    expect(
      entry.value is num || entry.value is String,
      isTrue,
      reason: 'param "${entry.key}" has unsupported type '
          '${entry.value.runtimeType}',
    );
  }
}

void main() {
  group('MatchQualityEvents.deckDepleted', () {
    test('emits deck depth, swipes, and a rejection breakdown', () {
      final event = MatchQualityEvents.deckDepleted(
        deckDepth: 24,
        swipesBeforeEmpty: 22,
        rejectionCounts: const {
          FilterRejectionReason.outOfDistance: 5,
          FilterRejectionReason.ageOutOfRange: 3,
        },
      );

      expect(event.name, MatchQualityEvents.eventDeckDepleted);
      expect(event.parameters['deck_depth'], 24);
      expect(event.parameters['swipes_before_empty'], 22);
      expect(event.parameters['total_rejected'], 8);
      expect(event.parameters['reject_out_of_distance'], 5);
      expect(event.parameters['reject_age_out_of_range'], 3);
    });

    test('omits zero-count reasons from the payload', () {
      final event = MatchQualityEvents.deckDepleted(
        deckDepth: 10,
        swipesBeforeEmpty: 10,
        rejectionCounts: const {
          FilterRejectionReason.blocked: 0,
          FilterRejectionReason.incognito: 2,
        },
      );

      expect(event.parameters.containsKey('reject_blocked'), isFalse);
      expect(event.parameters['reject_incognito'], 2);
      expect(event.parameters['total_rejected'], 2);
    });
  });

  group('MatchQualityEvents.candidateRejections', () {
    test('reports acceptance counts and per-reason breakdown', () {
      final event = MatchQualityEvents.candidateRejections(
        evaluatedCount: 10,
        acceptedCount: 6,
        rejectionCounts: const {
          FilterRejectionReason.genderNotPreferred: 3,
          FilterRejectionReason.hiddenFromDiscovery: 1,
        },
      );

      expect(event.name, MatchQualityEvents.eventCandidateRejections);
      expect(event.parameters['evaluated_count'], 10);
      expect(event.parameters['accepted_count'], 6);
      expect(event.parameters['rejected_count'], 4);
      expect(event.parameters['reject_gender_not_preferred'], 3);
      expect(event.parameters['reject_hidden_from_discovery'], 1);
    });

    test('integrates with a real pipeline result without leakage', () {
      // Drive the builder straight off a pipeline result to prove the two
      // layers compose (MATCH-002 → MATCH-003).
      const result = CandidateFilterResult(
        accepted: [],
        rejections: [
          CandidateRejection(
            profileId: 'a',
            reason: FilterRejectionReason.outOfDistance,
          ),
          CandidateRejection(
            profileId: 'b',
            reason: FilterRejectionReason.outOfDistance,
          ),
          CandidateRejection(
            profileId: 'c',
            reason: FilterRejectionReason.blocked,
          ),
        ],
      );

      final event = MatchQualityEvents.candidateRejections(
        evaluatedCount: result.evaluatedCount,
        acceptedCount: result.accepted.length,
        rejectionCounts: result.rejectionCounts,
      );

      expect(event.parameters['evaluated_count'], 3);
      expect(event.parameters['rejected_count'], 3);
      expect(event.parameters['reject_out_of_distance'], 2);
      expect(event.parameters['reject_blocked'], 1);
    });
  });

  group('MatchQualityEvents.rankingQuality', () {
    test('rounds scores and reports cold-start share', () {
      final event = MatchQualityEvents.rankingQuality(
        candidateCount: 12,
        topScore: 92.6,
        averageScore: 47.4,
        coldStartCount: 3,
      );

      expect(event.name, MatchQualityEvents.eventRankingQuality);
      expect(event.parameters['candidate_count'], 12);
      expect(event.parameters['top_score'], 93);
      expect(event.parameters['average_score'], 47);
      expect(event.parameters['cold_start_count'], 3);
    });
  });

  group('MatchQualityEvents.matchConversion', () {
    test('encodes converted=1 with the time when a message was sent', () {
      final event = MatchQualityEvents.matchConversion(
        matchId: 'match_1',
        secondsToFirstMessage: 120,
      );

      expect(event.name, MatchQualityEvents.eventMatchConversion);
      expect(event.parameters['match_id'], 'match_1');
      expect(event.parameters['converted'], 1);
      expect(event.parameters['seconds_to_first_message'], 120);
    });

    test('encodes converted=0 and omits time when no message was sent', () {
      final event = MatchQualityEvents.matchConversion(matchId: 'match_2');

      expect(event.parameters['converted'], 0);
      expect(
        event.parameters.containsKey('seconds_to_first_message'),
        isFalse,
      );
    });
  });

  group('MatchQualityEvents — Firebase validity', () {
    test('all builders respect Firebase structural limits', () {
      final events = <MatchQualityEvent>[
        MatchQualityEvents.deckDepleted(
          deckDepth: 30,
          swipesBeforeEmpty: 28,
          // Every reason at once — exercises the widest payload.
          rejectionCounts: {
            for (final reason in FilterRejectionReason.values) reason: 1,
          },
        ),
        MatchQualityEvents.candidateRejections(
          evaluatedCount: 30,
          acceptedCount: 2,
          rejectionCounts: {
            for (final reason in FilterRejectionReason.values) reason: 1,
          },
        ),
        MatchQualityEvents.rankingQuality(
          candidateCount: 30,
          topScore: 100,
          averageScore: 50,
          coldStartCount: 4,
        ),
        MatchQualityEvents.matchConversion(
          matchId: 'match_3',
          secondsToFirstMessage: 45,
        ),
      ];

      for (final event in events) {
        _expectFirebaseValid(event);
      }
    });
  });
}
