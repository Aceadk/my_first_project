import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

/// Parameters for getting quiz result.
class GetQuizResultParams {
  final String matchId;
  final String quizId;

  const GetQuizResultParams({required this.matchId, required this.quizId});
}

/// Use case for getting quiz result for a match.
class GetQuizResultUseCase extends UseCase<QuizResult?, GetQuizResultParams>
    with ValidatingUseCase<QuizResult?, GetQuizResultParams> {
  final CompatibilityQuizService _service;

  GetQuizResultUseCase([CompatibilityQuizService? service])
    : _service = service ?? CompatibilityQuizService.instance;

  @override
  String? validate(GetQuizResultParams params) {
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    if (params.quizId.trim().isEmpty) {
      return 'Quiz ID is required';
    }
    return null;
  }

  @override
  Future<Result<QuizResult?>> execute(GetQuizResultParams params) {
    return Result.guard(
      () async => _service.getResult(params.matchId, params.quizId),
      logLabel: 'GetQuizResultUseCase',
      fallbackError: 'Unable to load quiz result.',
    );
  }
}
