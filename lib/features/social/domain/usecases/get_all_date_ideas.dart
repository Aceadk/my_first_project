import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/models/date_idea.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';

/// Use case for getting all available date ideas.
class GetAllDateIdeasUseCase extends UseCase<List<DateIdea>, NoParams> {
  final DateIdeaService _service;

  GetAllDateIdeasUseCase([DateIdeaService? service])
      : _service = service ?? DateIdeaService.instance;

  @override
  Future<Result<List<DateIdea>>> call(NoParams params) {
    return Result.guard(
      () async => _service.getAllIdeas(),
      logLabel: 'GetAllDateIdeasUseCase',
      fallbackError: 'Unable to load date ideas.',
    );
  }
}
