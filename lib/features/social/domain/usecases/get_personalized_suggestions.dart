import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/social/domain/models/date_idea.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';

/// Parameters for getting personalized date suggestions.
class GetPersonalizedSuggestionsParams {
  final DateType? dateType;
  final DateCostLevel? maxBudget;
  final List<DateCategory>? preferredCategories;
  final Season? currentSeason;
  final int count;

  const GetPersonalizedSuggestionsParams({
    this.dateType,
    this.maxBudget,
    this.preferredCategories,
    this.currentSeason,
    this.count = 5,
  });
}

/// Use case for getting personalized date suggestions.
class GetPersonalizedSuggestionsUseCase
    extends UseCase<List<DateIdea>, GetPersonalizedSuggestionsParams> {
  final DateIdeaService _service;

  GetPersonalizedSuggestionsUseCase([DateIdeaService? service])
    : _service = service ?? DateIdeaService.instance;

  @override
  Future<Result<List<DateIdea>>> call(GetPersonalizedSuggestionsParams params) {
    return Result.guard(
      () => _service.getPersonalizedSuggestions(
        dateType: params.dateType,
        maxBudget: params.maxBudget,
        preferredCategories: params.preferredCategories,
        currentSeason: params.currentSeason,
        count: params.count,
      ),
      logLabel: 'GetPersonalizedSuggestionsUseCase',
      fallbackError: 'Unable to load personalized suggestions.',
    );
  }
}
