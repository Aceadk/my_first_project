import 'package:crushhour/features/social/domain/models/date_idea.dart';

/// Abstract interface for date idea operations.
abstract class DateIdeaRepository {
  Stream<List<DateIdea>> get ideasStream;
  List<DateIdea> get savedIdeas;
  List<DateIdea> get suggestedIdeas;

  List<DateIdea> getAllIdeas();
  List<DateIdea> getIdeasByCategory(DateCategory category);
  List<DateIdea> getIdeasForDateType(DateType type);
  List<DateIdea> getIdeasByBudget(DateCostLevel maxCost);
  List<DateIdea> getRandomSuggestions(int count);

  Future<List<DateIdea>> getPersonalizedSuggestions({
    DateType? dateType,
    DateCostLevel? maxBudget,
    List<DateCategory>? preferredCategories,
    Season? currentSeason,
    int count = 5,
  });

  Future<void> saveIdea(DateIdea idea);
  Future<void> removeSavedIdea(String ideaId);
  bool isIdeaSaved(String ideaId);

  Future<void> sendIdeaToMatch({
    required String matchId,
    required DateIdea idea,
    String? personalMessage,
  });

  Season getCurrentSeason();
  List<DateIdea> searchIdeas(String query);

  void clearUserData();
  void dispose();
}
