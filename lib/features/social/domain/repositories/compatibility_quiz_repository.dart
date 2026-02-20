import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';

/// Abstract interface for compatibility quiz operations.
abstract class CompatibilityQuizRepository {
  Stream<CompatibilityQuiz> get quizStream;
  Stream<QuizResult> get resultStream;

  List<CompatibilityQuiz> getAllQuizzes();
  CompatibilityQuiz? getQuiz(String quizId);

  Future<CompatibilityQuiz> startQuiz({
    required String quizId,
    required String matchId,
  });

  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  });

  Future<QuizResult> completeQuiz({
    required String quizId,
    required String matchId,
    required String user1Id,
    required String user2Id,
    required Map<String, String> user1Answers,
    required Map<String, String> user2Answers,
  });

  QuizResult? getResult(String matchId, String quizId);
  List<QuizResult> getAllResultsForMatch(String matchId);

  Future<void> inviteToQuiz({
    required String matchId,
    required String quizId,
    String? message,
  });

  void clearUserData();
  void dispose();
}
