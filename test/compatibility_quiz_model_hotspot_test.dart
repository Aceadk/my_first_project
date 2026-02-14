import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/social/data/models/compatibility_quiz.dart';

void main() {
  group('CompatibilityQuiz model', () {
    test('fromJson falls back to default category and estimated minutes', () {
      final quiz = CompatibilityQuiz.fromJson({
        'id': 'quiz-1',
        'title': 'Quiz',
        'description': 'Desc',
        'questions': [
          {
            'id': 'q1',
            'question': 'Q?',
            'options': [
              {'id': 'a', 'text': 'A'},
            ],
          },
        ],
        'category': 'unknown-category',
      });

      expect(quiz.category, QuizCategory.general);
      expect(quiz.estimatedMinutes, 5);
      expect(quiz.questions.single.options.single.text, 'A');
    });

    test('QuizQuestion fromJson handles null/unknown category values', () {
      final nullCategory = QuizQuestion.fromJson({
        'id': 'q1',
        'question': 'Q1',
        'options': [
          {'id': 'a', 'text': 'A'},
        ],
      });
      expect(nullCategory.category, isNull);

      final unknownCategory = QuizQuestion.fromJson({
        'id': 'q2',
        'question': 'Q2',
        'options': [
          {'id': 'b', 'text': 'B'},
        ],
        'category': 'not-a-real-category',
      });
      expect(unknownCategory.category, QuestionCategory.lifestyle);
    });

    test('QuizResult rating, score display, and fromJson defaults', () {
      QuizResult resultForScore(int? score) => QuizResult(
        quizId: 'quiz-1',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: const {'q1': 'a'},
        user2Answers: const {'q1': 'a'},
        completedAt: DateTime(2026, 2, 13),
        overallScore: score,
      );

      expect(resultForScore(null).scoreDisplay, 'Calculating...');
      expect(resultForScore(95).rating, ScoreRating.excellent);
      expect(resultForScore(80).rating, ScoreRating.great);
      expect(resultForScore(65).rating, ScoreRating.good);
      expect(resultForScore(45).rating, ScoreRating.moderate);
      expect(resultForScore(20).rating, ScoreRating.low);

      final restored = QuizResult.fromJson({
        'quizId': 'quiz-2',
        'user1Id': 'u1',
        'user2Id': 'u2',
        'user1Answers': {'q1': 'a'},
        'user2Answers': {'q1': 'b'},
        'completedAt': DateTime(2026, 2, 13).toIso8601String(),
      });
      expect(restored.categoryScores, isEmpty);
      expect(restored.insights, isEmpty);
      expect(restored.overallScore, isNull);
    });

    test(
      'CompatibilityInsight fromJson falls back to general insight type',
      () {
        final insight = CompatibilityInsight.fromJson({
          'type': 'not-real',
          'title': 'Insight',
          'description': 'Desc',
        });

        expect(insight.type, InsightType.general);
        expect(insight.isPositive, isTrue);
      },
    );
  });

  group('Compatibility enums/extensions', () {
    test('QuestionCategory displayName maps each enum value', () {
      expect(QuestionCategory.lifestyle.displayName, 'Lifestyle');
      expect(QuestionCategory.coreValues.displayName, 'Core Values');
      expect(QuestionCategory.communication.displayName, 'Communication');
      expect(QuestionCategory.intimacy.displayName, 'Intimacy');
      expect(QuestionCategory.family.displayName, 'Family');
      expect(QuestionCategory.career.displayName, 'Career');
      expect(QuestionCategory.leisure.displayName, 'Leisure');
    });

    test('ScoreRating extension returns expected labels and emoji', () {
      expect(ScoreRating.excellent.displayText, 'Excellent Match!');
      expect(ScoreRating.great.displayText, 'Great Compatibility');
      expect(ScoreRating.good.displayText, 'Good Connection');
      expect(ScoreRating.moderate.displayText, 'Room to Grow');
      expect(ScoreRating.low.displayText, 'Different Perspectives');
      expect(ScoreRating.unknown.displayText, 'Calculating...');

      expect(ScoreRating.excellent.emoji, '🌟');
      expect(ScoreRating.great.emoji, '✨');
      expect(ScoreRating.good.emoji, '👍');
      expect(ScoreRating.moderate.emoji, '🌱');
      expect(ScoreRating.low.emoji, '🔮');
      expect(ScoreRating.unknown.emoji, '⏳');
    });

    test('predefined quizzes are exposed', () {
      final quizzes = CompatibilityQuizzes.all;
      expect(quizzes, hasLength(2));
      expect(quizzes.first.id, 'basic_compatibility');
      expect(quizzes.last.id, 'lifestyle');
      expect(quizzes.last.category, QuizCategory.lifestyle);
    });
  });
}
