import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';

void main() {
  group('CompatibilityQuiz model', () {
    test('fromJson falls back to default category and estimated minutes', () {
      final quiz = CompatibilityQuiz.fromJson(const {
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
      final nullCategory = QuizQuestion.fromJson(const {
        'id': 'q1',
        'question': 'Q1',
        'options': [
          {'id': 'a', 'text': 'A'},
        ],
      });
      expect(nullCategory.category, isNull);

      final unknownCategory = QuizQuestion.fromJson(const {
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
        'user1Answers': const {'q1': 'a'},
        'user2Answers': const {'q1': 'b'},
        'completedAt': DateTime(2026, 2, 13).toIso8601String(),
      });
      expect(restored.categoryScores, isEmpty);
      expect(restored.insights, isEmpty);
      expect(restored.overallScore, isNull);
    });

    test(
      'CompatibilityInsight fromJson falls back to general insight type',
      () {
        final insight = CompatibilityInsight.fromJson(const {
          'type': 'not-real',
          'title': 'Insight',
          'description': 'Desc',
        });

        expect(insight.type, InsightType.general);
        expect(insight.isPositive, isTrue);
      },
    );

    test(
      'quiz/question/option toJson+fromJson round-trip and equatable props',
      () {
        const option = QuizOption(
          id: 'o1',
          text: 'Option',
          emoji: '😀',
          value: 2,
        );
        const question = QuizQuestion(
          id: 'q1',
          question: 'What is your style?',
          options: [option],
          emoji: '🧠',
          category: QuestionCategory.communication,
        );
        const quiz = CompatibilityQuiz(
          id: 'quiz-rt',
          title: 'Round Trip',
          description: 'Round-trip serialization',
          questions: [question],
          category: QuizCategory.communication,
          estimatedMinutes: 7,
          imageUrl: 'https://example.com/quiz.png',
        );

        final json = quiz.toJson();
        expect(json['category'], 'communication');
        expect(json['estimatedMinutes'], 7);
        expect(json['imageUrl'], 'https://example.com/quiz.png');

        final restored = CompatibilityQuiz.fromJson(json);
        expect(restored, equals(quiz));
        expect(
          restored.props,
          containsAll(<Object?>[
            'quiz-rt',
            'Round Trip',
            'Round-trip serialization',
            QuizCategory.communication,
            7,
            'https://example.com/quiz.png',
          ]),
        );

        expect(
          question.props,
          containsAll(<Object?>[
            'q1',
            'What is your style?',
            '🧠',
            QuestionCategory.communication,
          ]),
        );
        expect(option.props, containsAll(<Object?>['o1', 'Option', '😀', 2]));

        final restoredOption = QuizOption.fromJson(option.toJson());
        expect(restoredOption, equals(option));
      },
    );

    test('QuizResult and CompatibilityInsight serialize full payloads', () {
      const insight = CompatibilityInsight(
        type: InsightType.strength,
        title: 'Strong communication',
        description: 'You resolve conflicts quickly.',
        emoji: '💬',
        isPositive: false,
      );

      final result = QuizResult(
        quizId: 'quiz-1',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: const {'q1': 'a', 'q2': 'b'},
        user2Answers: const {'q1': 'a', 'q2': 'c'},
        completedAt: DateTime(2026, 2, 17, 12),
        overallScore: 88,
        categoryScores: const {'communication': 90, 'lifestyle': 80},
        insights: const [insight],
      );

      final insightJson = insight.toJson();
      expect(insightJson['type'], 'strength');
      expect(insightJson['isPositive'], isFalse);
      expect(CompatibilityInsight.fromJson(insightJson), equals(insight));
      expect(
        insight.props,
        containsAll(<Object?>[
          InsightType.strength,
          'Strong communication',
          'You resolve conflicts quickly.',
          '💬',
          false,
        ]),
      );

      final resultJson = result.toJson();
      expect(resultJson['overallScore'], 88);
      expect(resultJson['categoryScores'], containsPair('communication', 90));
      expect((resultJson['insights'] as List<dynamic>).length, 1);

      final restored = QuizResult.fromJson(resultJson);
      expect(restored, equals(result));
      expect(restored.scoreDisplay, '88%');
      expect(restored.rating, ScoreRating.great);
      expect(
        restored.props,
        containsAll(<Object?>[
          'quiz-1',
          'u1',
          'u2',
          const {'communication': 90, 'lifestyle': 80},
        ]),
      );
    });
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

    test('predefined quizzes contain valid non-empty question banks', () {
      const basic = CompatibilityQuizzes.basicCompatibility;
      const lifestyle = CompatibilityQuizzes.lifestyleQuiz;

      expect(basic.questions.length, 5);
      expect(lifestyle.questions.length, 4);
      expect(CompatibilityQuizzes.all, containsAll([basic, lifestyle]));

      for (final quiz in CompatibilityQuizzes.all) {
        expect(quiz.id, isNotEmpty);
        expect(quiz.title, isNotEmpty);
        expect(quiz.description, isNotEmpty);
        expect(quiz.estimatedMinutes, greaterThan(0));
        expect(quiz.questions, isNotEmpty);

        for (final question in quiz.questions) {
          expect(question.id, isNotEmpty);
          expect(question.question, isNotEmpty);
          expect(question.options, isNotEmpty);
          for (final option in question.options) {
            expect(option.id, isNotEmpty);
            expect(option.text, isNotEmpty);
          }
        }
      }
    });
  });
}
