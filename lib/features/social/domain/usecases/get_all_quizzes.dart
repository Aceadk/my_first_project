import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

/// Use case for getting all available compatibility quizzes.
class GetAllQuizzesUseCase extends UseCase<List<CompatibilityQuiz>, NoParams> {
  final CompatibilityQuizService _service;

  GetAllQuizzesUseCase([CompatibilityQuizService? service])
      : _service = service ?? CompatibilityQuizService.instance;

  @override
  Future<Result<List<CompatibilityQuiz>>> call(NoParams params) {
    return Result.guard(
      () async => _service.getAllQuizzes(),
      logLabel: 'GetAllQuizzesUseCase',
      fallbackError: 'Unable to load quizzes.',
    );
  }
}
