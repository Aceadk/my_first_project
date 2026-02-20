import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';

/// Parameters for inviting to quiz.
class InviteToQuizParams {
  final String matchId;
  final String quizId;
  final String? message;

  const InviteToQuizParams({
    required this.matchId,
    required this.quizId,
    this.message,
  });
}

/// Use case for inviting a match to take a quiz.
class InviteToQuizUseCase extends UseCase<void, InviteToQuizParams>
    with ValidatingUseCase<void, InviteToQuizParams> {
  final CompatibilityQuizService _service;

  InviteToQuizUseCase([CompatibilityQuizService? service])
    : _service = service ?? CompatibilityQuizService.instance;

  @override
  String? validate(InviteToQuizParams params) {
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    if (params.quizId.trim().isEmpty) {
      return 'Quiz ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(InviteToQuizParams params) {
    return Result.guard(
      () => _service.inviteToQuiz(
        matchId: params.matchId,
        quizId: params.quizId,
        message: params.message,
      ),
      logLabel: 'InviteToQuizUseCase',
      fallbackError: 'Unable to send quiz invitation.',
    );
  }
}
