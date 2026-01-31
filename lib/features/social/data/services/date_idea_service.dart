import 'dart:async';
import '../models/date_idea.dart';

/// Service for managing date idea suggestions.
class DateIdeaService {
  DateIdeaService._();
  static final DateIdeaService instance = DateIdeaService._();

  final _ideasController = StreamController<List<DateIdea>>.broadcast();
  Stream<List<DateIdea>> get ideasStream => _ideasController.stream;

  final List<DateIdea> _savedIdeas = [];
  List<DateIdea> _suggestedIdeas = [];

  List<DateIdea> get savedIdeas => _savedIdeas;
  List<DateIdea> get suggestedIdeas => _suggestedIdeas;

  /// Get all available date ideas.
  List<DateIdea> getAllIdeas() {
    return DateIdeas.suggestions;
  }

  /// Get date ideas by category.
  List<DateIdea> getIdeasByCategory(DateCategory category) {
    return DateIdeas.byCategory(category);
  }

  /// Get date ideas for a specific date type.
  List<DateIdea> getIdeasForDateType(DateType type) {
    return DateIdeas.forDateType(type);
  }

  /// Get date ideas within a budget.
  List<DateIdea> getIdeasByBudget(DateCostLevel maxCost) {
    return DateIdeas.byCost(maxCost);
  }

  /// Get random suggestions.
  List<DateIdea> getRandomSuggestions(int count) {
    _suggestedIdeas = DateIdeas.random(count);
    _ideasController.add(_suggestedIdeas);
    return _suggestedIdeas;
  }

  /// Get personalized suggestions based on preferences.
  Future<List<DateIdea>> getPersonalizedSuggestions({
    DateType? dateType,
    DateCostLevel? maxBudget,
    List<DateCategory>? preferredCategories,
    Season? currentSeason,
    int count = 5,
  }) async {
    // In production, use ML/backend for personalization
    await Future.delayed(const Duration(milliseconds: 300));

    var ideas = List<DateIdea>.from(DateIdeas.suggestions);

    // Filter by date type
    if (dateType != null) {
      ideas = ideas.where((i) => i.bestFor.contains(dateType)).toList();
    }

    // Filter by budget
    if (maxBudget != null) {
      ideas = ideas
          .where((i) =>
              i.estimatedCost != null &&
              i.estimatedCost!.index <= maxBudget.index)
          .toList();
    }

    // Filter by preferred categories
    if (preferredCategories != null && preferredCategories.isNotEmpty) {
      ideas =
          ideas.where((i) => preferredCategories.contains(i.category)).toList();
    }

    // Filter by season
    if (currentSeason != null) {
      ideas = ideas
          .where((i) =>
              i.seasonalAvailability == null ||
              i.seasonalAvailability!.contains(currentSeason))
          .toList();
    }

    // Shuffle and take count
    ideas.shuffle();
    _suggestedIdeas = ideas.take(count).toList();
    _ideasController.add(_suggestedIdeas);

    return _suggestedIdeas;
  }

  /// Save a date idea.
  Future<void> saveIdea(DateIdea idea) async {
    if (!_savedIdeas.any((i) => i.id == idea.id)) {
      _savedIdeas.add(idea);
      // In production, sync with backend
    }
  }

  /// Remove saved idea.
  Future<void> removeSavedIdea(String ideaId) async {
    _savedIdeas.removeWhere((i) => i.id == ideaId);
    // In production, sync with backend
  }

  /// Check if idea is saved.
  bool isIdeaSaved(String ideaId) {
    return _savedIdeas.any((i) => i.id == ideaId);
  }

  /// Send date idea to match.
  Future<void> sendIdeaToMatch({
    required String matchId,
    required DateIdea idea,
    String? personalMessage,
  }) async {
    // In production, send via chat/notification
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Get current season.
  Season getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.fall;
    return Season.winter;
  }

  /// Search ideas by text.
  List<DateIdea> searchIdeas(String query) {
    final lowerQuery = query.toLowerCase();
    return DateIdeas.suggestions.where((idea) {
      return idea.title.toLowerCase().contains(lowerQuery) ||
          idea.description.toLowerCase().contains(lowerQuery) ||
          idea.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  void clearUserData() {
    _savedIdeas.clear();
    _suggestedIdeas = [];
    _ideasController.add(_suggestedIdeas);
  }

  void dispose() {
    _ideasController.close();
  }
}
