import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/domain/models/date_idea.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';

/// Parameters for sending a date idea to a match.
class SendIdeaToMatchParams {
  final String matchId;
  final DateIdea idea;
  final String? personalMessage;

  const SendIdeaToMatchParams({
    required this.matchId,
    required this.idea,
    this.personalMessage,
  });
}

/// Use case for sending a date idea to a match.
class SendIdeaToMatchUseCase extends UseCase<void, SendIdeaToMatchParams>
    with ValidatingUseCase<void, SendIdeaToMatchParams> {
  final DateIdeaService _service;

  SendIdeaToMatchUseCase([DateIdeaService? service])
    : _service = service ?? DateIdeaService.instance;

  @override
  String? validate(SendIdeaToMatchParams params) {
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(SendIdeaToMatchParams params) {
    return Result.guard(
      () => _service.sendIdeaToMatch(
        matchId: params.matchId,
        idea: params.idea,
        personalMessage: params.personalMessage,
      ),
      logLabel: 'SendIdeaToMatchUseCase',
      fallbackError: 'Unable to send date idea.',
    );
  }
}
