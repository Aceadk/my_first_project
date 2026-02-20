import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

/// Parameters for completing a quiz.
class CompleteQuizParams {
  final String quizId;
  final String matchId;
  final String user1Id;
  final String user2Id;
  final Map<String, String> user1Answers;
  final Map<String, String> user2Answers;

  const CompleteQuizParams({
    required this.quizId,
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    required this.user1Answers,
    required this.user2Answers,
  });
}

/// Use case for completing a quiz and calculating results.
class CompleteQuizUseCase extends UseCase<QuizResult, CompleteQuizParams>
    with ValidatingUseCase<QuizResult, CompleteQuizParams> {
  final CompatibilityQuizService _service;

  CompleteQuizUseCase([CompatibilityQuizService? service])
    : _service = service ?? CompatibilityQuizService.instance;

  @override
  String? validate(CompleteQuizParams params) {
    if (params.quizId.trim().isEmpty) {
      return 'Quiz ID is required';
    }
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    if (params.user1Id.trim().isEmpty || params.user2Id.trim().isEmpty) {
      return 'Both user IDs are required';
    }
    if (params.user1Answers.isEmpty) {
      return 'User 1 must provide answers';
    }
    if (params.user2Answers.isEmpty) {
      return 'User 2 must provide answers';
    }
    return null;
  }

  @override
  Future<Result<QuizResult>> execute(CompleteQuizParams params) {
    return Result.guard(
      () => _service.completeQuiz(
        quizId: params.quizId,
        matchId: params.matchId,
        user1Id: params.user1Id,
        user2Id: params.user2Id,
        user1Answers: params.user1Answers,
        user2Answers: params.user2Answers,
      ),
      logLabel: 'CompleteQuizUseCase',
      fallbackError: 'Unable to complete quiz. Please try again.',
    );
  }
}
