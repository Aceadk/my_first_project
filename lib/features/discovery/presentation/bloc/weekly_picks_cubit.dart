import 'dart:async';

import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/domain/models/weekly_picks.dart';
import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for weekly picks.
class WeeklyPicksState extends Equatable {
  const WeeklyPicksState({
    this.picks,
    this.isLoading = false,
    this.errorMessage,
    this.currentIndex = 0,
  });

  final WeeklyPicks? picks;
  final bool isLoading;
  final String? errorMessage;
  final int currentIndex;

  List<WeeklyPick> get picksList => picks?.picks ?? [];
  int get unseenCount => picks?.unseenCount ?? 0;
  bool get hasUnseenPicks => unseenCount > 0;
  String get newPicksTimeDisplay => picks?.newPicksTimeDisplay ?? '';
  WeeklyPick? get currentPick =>
      currentIndex < picksList.length ? picksList[currentIndex] : null;

  WeeklyPicksState copyWith({
    WeeklyPicks? picks,
    bool? isLoading,
    String? errorMessage,
    int? currentIndex,
  }) {
    return WeeklyPicksState(
      picks: picks ?? this.picks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [picks, isLoading, errorMessage, currentIndex];
}

/// Cubit for managing weekly picks state.
class WeeklyPicksCubit extends Cubit<WeeklyPicksState> {
  final WeeklyPicksRepository _service;

  WeeklyPicksCubit({
    required AuthRepository authRepository,
    required WeeklyPicksRepository weeklyPicksRepository,
  }) : _service = weeklyPicksRepository,
       _authRepository = authRepository,
       super(const WeeklyPicksState()) {
    _authSubscription = _authRepository.authStateChanges().listen((user) {
      if (user == null) {
        _resetState();
      }
    });
  }

  final AuthRepository _authRepository;

  StreamSubscription<WeeklyPicks>? _subscription;
  StreamSubscription<CrushUser?>? _authSubscription;

  /// Load weekly picks for user.
  Future<void> loadPicks(String userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final picks = await _service.loadPicks(userId);

      _subscription?.cancel();
      _subscription = _service.picksStream.listen((updatedPicks) {
        emit(state.copyWith(picks: updatedPicks));
      });

      emit(state.copyWith(picks: picks, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorMessages.loadDeckFailed,
        ),
      );
    }
  }

  /// Mark current pick as viewed and move to next.
  void viewCurrentPick() {
    final currentPick = state.currentPick;
    if (currentPick != null) {
      _service.markPickViewed(currentPick.id);
    }
  }

  /// Like current pick and move to next.
  void likeCurrentPick() {
    final currentPick = state.currentPick;
    if (currentPick != null) {
      _service.markPickLiked(currentPick.id);
      moveToNextPick();
    }
  }

  /// Pass on current pick and move to next.
  void passCurrentPick() {
    moveToNextPick();
  }

  /// Move to the next pick.
  void moveToNextPick() {
    if (state.currentIndex < state.picksList.length - 1) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }

  /// Move to a specific pick.
  void goToPick(int index) {
    if (index >= 0 && index < state.picksList.length) {
      emit(state.copyWith(currentIndex: index));
      final pick = state.picksList[index];
      _service.markPickViewed(pick.id);
    }
  }

  /// Check if a pick has been viewed.
  bool isPickViewed(String pickId) => _service.isPickViewed(pickId);

  /// Check if a pick has been liked.
  bool isPickLiked(String pickId) => _service.isPickLiked(pickId);

  void _resetState() {
    _subscription?.cancel();
    _subscription = null;
    _service.clearUserData();
    if (!isClosed) {
      emit(const WeeklyPicksState());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
