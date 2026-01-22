import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/data/models/date_idea.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';

/// Parameters for searching date ideas.
class SearchDateIdeasParams {
  final String query;

  const SearchDateIdeasParams({required this.query});
}

/// Use case for searching date ideas by text.
class SearchDateIdeasUseCase extends UseCase<List<DateIdea>, SearchDateIdeasParams>
    with ValidatingUseCase<List<DateIdea>, SearchDateIdeasParams> {
  final DateIdeaService _service;

  SearchDateIdeasUseCase([DateIdeaService? service])
      : _service = service ?? DateIdeaService.instance;

  @override
  String? validate(SearchDateIdeasParams params) {
    if (params.query.trim().isEmpty) {
      return 'Search query is required';
    }
    return null;
  }

  @override
  Future<Result<List<DateIdea>>> execute(SearchDateIdeasParams params) {
    return Result.guard(
      () async => _service.searchIdeas(params.query),
      logLabel: 'SearchDateIdeasUseCase',
      fallbackError: 'Unable to search date ideas.',
    );
  }
}
