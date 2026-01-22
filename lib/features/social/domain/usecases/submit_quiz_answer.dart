import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

/// Parameters for submitting a quiz answer.
class SubmitQuizAnswerParams {
  final String matchId;
  final String questionId;
  final String optionId;

  const SubmitQuizAnswerParams({
    required this.matchId,
    required this.questionId,
    required this.optionId,
  });
}

/// Use case for submitting an answer to a quiz question.
class SubmitQuizAnswerUseCase extends UseCase<void, SubmitQuizAnswerParams>
    with ValidatingUseCase<void, SubmitQuizAnswerParams> {
  final CompatibilityQuizService _service;

  SubmitQuizAnswerUseCase([CompatibilityQuizService? service])
      : _service = service ?? CompatibilityQuizService.instance;

  @override
  String? validate(SubmitQuizAnswerParams params) {
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    if (params.questionId.trim().isEmpty) {
      return 'Question ID is required';
    }
    if (params.optionId.trim().isEmpty) {
      return 'Option ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(SubmitQuizAnswerParams params) {
    return Result.guard(
      () => _service.submitAnswer(
        matchId: params.matchId,
        questionId: params.questionId,
        optionId: params.optionId,
      ),
      logLabel: 'SubmitQuizAnswerUseCase',
      fallbackError: 'Unable to submit answer.',
    );
  }
}
