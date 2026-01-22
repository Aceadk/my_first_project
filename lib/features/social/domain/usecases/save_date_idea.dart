import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/models/date_idea.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';

/// Parameters for saving a date idea.
class SaveDateIdeaParams {
  final DateIdea idea;

  const SaveDateIdeaParams({required this.idea});
}

/// Use case for saving a date idea.
class SaveDateIdeaUseCase extends UseCase<void, SaveDateIdeaParams> {
  final DateIdeaService _service;

  SaveDateIdeaUseCase([DateIdeaService? service])
      : _service = service ?? DateIdeaService.instance;

  @override
  Future<Result<void>> call(SaveDateIdeaParams params) {
    return Result.guard(
      () => _service.saveIdea(params.idea),
      logLabel: 'SaveDateIdeaUseCase',
      fallbackError: 'Unable to save date idea.',
    );
  }
}
