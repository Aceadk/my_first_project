import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';
import 'package:crushhour/features/social/data/models/date_idea.dart';

/// State for date ideas.
class DateIdeasState extends Equatable {
  const DateIdeasState({
    this.ideas = const [],
    this.filteredIdeas = const [],
    this.savedIdeas = const [],
    this.suggestedIdeas = const [],
    this.selectedCategory,
    this.selectedCostLevel,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<DateIdea> ideas;
  final List<DateIdea> filteredIdeas;
  final List<DateIdea> savedIdeas;
  final List<DateIdea> suggestedIdeas;
  final DateCategory? selectedCategory;
  final DateCostLevel? selectedCostLevel;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  List<DateCategory> get categories => DateCategory.values;
  List<DateCostLevel> get costLevels => DateCostLevel.values;

  DateIdeasState copyWith({
    List<DateIdea>? ideas,
    List<DateIdea>? filteredIdeas,
    List<DateIdea>? savedIdeas,
    List<DateIdea>? suggestedIdeas,
    DateCategory? selectedCategory,
    DateCostLevel? selectedCostLevel,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearCategory = false,
    bool clearCostLevel = false,
  }) {
    return DateIdeasState(
      ideas: ideas ?? this.ideas,
      filteredIdeas: filteredIdeas ?? this.filteredIdeas,
      savedIdeas: savedIdeas ?? this.savedIdeas,
      suggestedIdeas: suggestedIdeas ?? this.suggestedIdeas,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedCostLevel: clearCostLevel ? null : (selectedCostLevel ?? this.selectedCostLevel),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        ideas,
        filteredIdeas,
        savedIdeas,
        suggestedIdeas,
        selectedCategory,
        selectedCostLevel,
        searchQuery,
        isLoading,
        errorMessage,
      ];
}

/// Cubit for managing date ideas state.
class DateIdeasCubit extends Cubit<DateIdeasState> {
  DateIdeasCubit({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const DateIdeasState()) {
    _authSubscription = _authRepository.authStateChanges().listen((user) {
      if (user == null) {
        _resetState();
      }
    });
  }

  final AuthRepository _authRepository;
  final _service = DateIdeaService.instance;
  StreamSubscription<List<DateIdea>>? _ideasSubscription;
  StreamSubscription<CrushUser?>? _authSubscription;

  /// Load all date ideas.
  Future<void> loadIdeas() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final ideas = _service.getAllIdeas();

      _ideasSubscription?.cancel();
      _ideasSubscription = _service.ideasStream.listen(
        (suggestedIdeas) {
          emit(state.copyWith(suggestedIdeas: suggestedIdeas));
        },
      );

      emit(state.copyWith(
        ideas: ideas,
        filteredIdeas: ideas,
        savedIdeas: _service.savedIdeas,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load date ideas',
      ));
    }
  }

  /// Get personalized suggestions.
  Future<void> getPersonalizedSuggestions({
    DateType? dateType,
    DateCostLevel? maxBudget,
    List<DateCategory>? preferredCategories,
    int count = 5,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final suggestions = await _service.getPersonalizedSuggestions(
        dateType: dateType,
        maxBudget: maxBudget,
        preferredCategories: preferredCategories,
        currentSeason: _service.getCurrentSeason(),
        count: count,
      );

      emit(state.copyWith(
        suggestedIdeas: suggestions,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Filter ideas by category.
  void filterByCategory(DateCategory? category) {
    emit(state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    ));
    _applyFilters();
  }

  /// Filter ideas by cost level.
  void filterByCostLevel(DateCostLevel? costLevel) {
    emit(state.copyWith(
      selectedCostLevel: costLevel,
      clearCostLevel: costLevel == null,
    ));
    _applyFilters();
  }

  /// Search ideas by query.
  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  /// Clear all filters.
  void clearFilters() {
    emit(state.copyWith(
      clearCategory: true,
      clearCostLevel: true,
      searchQuery: '',
      filteredIdeas: state.ideas,
    ));
  }

  void _applyFilters() {
    var filtered = state.ideas;

    // Filter by category
    if (state.selectedCategory != null) {
      filtered = filtered
          .where((idea) => idea.category == state.selectedCategory)
          .toList();
    }

    // Filter by cost level
    if (state.selectedCostLevel != null) {
      filtered = filtered
          .where((idea) =>
              idea.estimatedCost != null &&
              idea.estimatedCost!.index <= state.selectedCostLevel!.index)
          .toList();
    }

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((idea) {
        return idea.title.toLowerCase().contains(query) ||
            idea.description.toLowerCase().contains(query) ||
            idea.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    emit(state.copyWith(filteredIdeas: filtered));
  }

  /// Save an idea.
  Future<void> saveIdea(DateIdea idea) async {
    await _service.saveIdea(idea);
    emit(state.copyWith(savedIdeas: _service.savedIdeas));
  }

  /// Remove a saved idea.
  Future<void> removeSavedIdea(String ideaId) async {
    await _service.removeSavedIdea(ideaId);
    emit(state.copyWith(savedIdeas: _service.savedIdeas));
  }

  /// Check if an idea is saved.
  bool isIdeaSaved(String ideaId) => _service.isIdeaSaved(ideaId);

  /// Get random suggestions.
  List<DateIdea> getRandomSuggestions(int count) {
    return _service.getRandomSuggestions(count);
  }

  /// Get ideas by category.
  List<DateIdea> getIdeasByCategory(DateCategory category) {
    return _service.getIdeasByCategory(category);
  }

  /// Send idea to match.
  Future<void> sendIdeaToMatch({
    required String matchId,
    required DateIdea idea,
    String? personalMessage,
  }) async {
    await _service.sendIdeaToMatch(
      matchId: matchId,
      idea: idea,
      personalMessage: personalMessage,
    );
  }

  void _resetState() {
    _ideasSubscription?.cancel();
    _ideasSubscription = null;
    _service.clearUserData();
    if (!isClosed) {
      emit(const DateIdeasState());
    }
  }

  @override
  Future<void> close() {
    _ideasSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
