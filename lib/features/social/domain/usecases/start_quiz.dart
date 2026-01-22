import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

/// Parameters for starting a quiz.
class StartQuizParams {
  final String quizId;
  final String matchId;

  const StartQuizParams({
    required this.quizId,
    required this.matchId,
  });
}

/// Use case for starting a compatibility quiz session.
class StartQuizUseCase extends UseCase<CompatibilityQuiz, StartQuizParams>
    with ValidatingUseCase<CompatibilityQuiz, StartQuizParams> {
  final CompatibilityQuizService _service;

  StartQuizUseCase([CompatibilityQuizService? service])
      : _service = service ?? CompatibilityQuizService.instance;

  @override
  String? validate(StartQuizParams params) {
    if (params.quizId.trim().isEmpty) {
      return 'Quiz ID is required';
    }
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    return null;
  }

  @override
  Future<Result<CompatibilityQuiz>> execute(StartQuizParams params) {
    return Result.guard(
      () => _service.startQuiz(
        quizId: params.quizId,
        matchId: params.matchId,
      ),
      logLabel: 'StartQuizUseCase',
      fallbackError: 'Unable to start quiz. Please try again.',
    );
  }
}
