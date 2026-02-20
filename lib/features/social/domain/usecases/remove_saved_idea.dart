import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';

/// Parameters for removing a saved date idea.
class RemoveSavedIdeaParams {
  final String ideaId;

  const RemoveSavedIdeaParams({required this.ideaId});
}

/// Use case for removing a saved date idea.
class RemoveSavedIdeaUseCase extends UseCase<void, RemoveSavedIdeaParams>
    with ValidatingUseCase<void, RemoveSavedIdeaParams> {
  final DateIdeaService _service;

  RemoveSavedIdeaUseCase([DateIdeaService? service])
    : _service = service ?? DateIdeaService.instance;

  @override
  String? validate(RemoveSavedIdeaParams params) {
    if (params.ideaId.trim().isEmpty) {
      return 'Idea ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(RemoveSavedIdeaParams params) {
    return Result.guard(
      () => _service.removeSavedIdea(params.ideaId),
      logLabel: 'RemoveSavedIdeaUseCase',
      fallbackError: 'Unable to remove saved idea.',
    );
  }
}
