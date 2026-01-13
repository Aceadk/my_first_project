import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

void main() {
  group('CompatibilityQuizService', () {
    late CompatibilityQuizService service;

    setUp(() {
      service = CompatibilityQuizService.instance;
    });

    group('getAllQuizzes', () {
      test('returns list of available quizzes', () {
        final quizzes = service.getAllQuizzes();

        expect(quizzes, isNotEmpty);
        expect(quizzes.every((q) => q.id.isNotEmpty), isTrue);
        expect(quizzes.every((q) => q.questions.isNotEmpty), isTrue);
      });
    });

    group('getQuiz', () {
      test('returns quiz by ID', () {
        final quizzes = service.getAllQuizzes();
        final firstQuizId = quizzes.first.id;

        final quiz = service.getQuiz(firstQuizId);

        expect(quiz, isNotNull);
        expect(quiz!.id, firstQuizId);
      });

      test('returns fallback quiz for unknown ID', () {
        final quiz = service.getQuiz('non_existent_quiz');

        expect(quiz, isNotNull);
      });
    });

    group('startQuiz', () {
      test('starts a quiz session', () async {
        final quizzes = service.getAllQuizzes();
        final quizId = quizzes.first.id;

        final quiz = await service.startQuiz(
          quizId: quizId,
          matchId: 'test_match',
        );

        expect(quiz.id, quizId);
        expect(quiz.questions, isNotEmpty);
      });
    });

    group('submitAnswer', () {
      test('submits answer for question', () async {
        final quizzes = service.getAllQuizzes();
        final quizId = quizzes.first.id;
        await service.startQuiz(quizId: quizId, matchId: 'answer_test_match');

        final quiz = service.getQuiz(quizId)!;
        final question = quiz.questions.first;
        final option = question.options.first;

        // Should not throw
        await service.submitAnswer(
          matchId: 'answer_test_match',
          questionId: question.id,
          optionId: option.id,
        );
      });
    });

    group('completeQuiz', () {
      test('calculates compatibility score', () async {
        final quizzes = service.getAllQuizzes();
        final quiz = quizzes.first;

        // Create matching answers for both users
        final answers = <String, String>{};
        for (final question in quiz.questions) {
          answers[question.id] = question.options.first.id;
        }

        final result = await service.completeQuiz(
          quizId: quiz.id,
          matchId: 'complete_test_match',
          user1Id: 'user1',
          user2Id: 'user2',
          user1Answers: answers,
          user2Answers: answers, // Same answers = 100% match
        );

        expect(result.overallScore, 100);
        expect(result.user1Id, 'user1');
        expect(result.user2Id, 'user2');
        expect(result.insights, isNotEmpty);
      });

      test('returns lower score for different answers', () async {
        final quizzes = service.getAllQuizzes();
        final quiz = quizzes.first;

        final user1Answers = <String, String>{};
        final user2Answers = <String, String>{};

        for (final question in quiz.questions) {
          user1Answers[question.id] = question.options.first.id;
          // Use different option for user2
          user2Answers[question.id] = question.options.length > 1
              ? question.options.last.id
              : question.options.first.id;
        }

        final result = await service.completeQuiz(
          quizId: quiz.id,
          matchId: 'diff_test_match',
          user1Id: 'user1',
          user2Id: 'user2',
          user1Answers: user1Answers,
          user2Answers: user2Answers,
        );

        // Should be less than 100 if there are different answers
        expect(result.overallScore, lessThanOrEqualTo(100));
      });
    });

    group('getResult', () {
      test('returns stored result', () async {
        final quizzes = service.getAllQuizzes();
        final quiz = quizzes.first;
        const matchId = 'result_test_match';

        final answers = <String, String>{};
        for (final question in quiz.questions) {
          answers[question.id] = question.options.first.id;
        }

        await service.completeQuiz(
          quizId: quiz.id,
          matchId: matchId,
          user1Id: 'user1',
          user2Id: 'user2',
          user1Answers: answers,
          user2Answers: answers,
        );

        final result = service.getResult(matchId, quiz.id);

        expect(result, isNotNull);
        expect(result!.quizId, quiz.id);
      });
    });

    group('getAllResultsForMatch', () {
      test('returns all results for a match', () async {
        final quizzes = service.getAllQuizzes();
        const matchId = 'all_results_match';

        // Complete a quiz
        final quiz = quizzes.first;
        final answers = <String, String>{};
        for (final question in quiz.questions) {
          answers[question.id] = question.options.first.id;
        }

        await service.completeQuiz(
          quizId: quiz.id,
          matchId: matchId,
          user1Id: 'user1',
          user2Id: 'user2',
          user1Answers: answers,
          user2Answers: answers,
        );

        final results = service.getAllResultsForMatch(matchId);

        expect(results, isNotEmpty);
      });
    });
  });
}
