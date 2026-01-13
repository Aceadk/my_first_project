import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/features/discovery/data/services/daily_likes_service.dart';
import 'package:crushhour/features/discovery/data/models/daily_likes_limit.dart';

/// State for daily likes limit.
class DailyLikesState extends Equatable {
  const DailyLikesState({
    this.limit,
    this.isLoading = false,
    this.errorMessage,
    this.lastLikeResult,
  });

  final DailyLikesLimit? limit;
  final bool isLoading;
  final String? errorMessage;
  final LikeResult? lastLikeResult;

  bool get canLike => limit?.canLike ?? false;
  bool get canSuperLike => limit?.canSuperLike ?? false;
  int get remainingLikes => limit?.remainingLikes ?? 0;
  int get remainingSuperLikes => limit?.remainingSuperLikes ?? 0;
  bool get isPremium => limit?.isPremium ?? false;
  double get usagePercentage => limit?.usagePercentage ?? 0.0;
  String get resetTimeDisplay => limit?.resetTimeDisplay ?? '';
  Duration get timeUntilReset => limit?.timeUntilReset ?? Duration.zero;

  DailyLikesState copyWith({
    DailyLikesLimit? limit,
    bool? isLoading,
    String? errorMessage,
    LikeResult? lastLikeResult,
  }) {
    return DailyLikesState(
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastLikeResult: lastLikeResult ?? this.lastLikeResult,
    );
  }

  @override
  List<Object?> get props => [limit, isLoading, errorMessage, lastLikeResult];
}

/// Cubit for managing daily likes limit state.
class DailyLikesCubit extends Cubit<DailyLikesState> {
  DailyLikesCubit() : super(const DailyLikesState());

  final _service = DailyLikesService.instance;
  StreamSubscription<DailyLikesLimit>? _limitSubscription;

  /// Initialize and load likes limit.
  Future<void> loadLimit({
    required String userId,
    bool isPremium = false,
    int bonusLikes = 0,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final limit = await _service.loadLimit(
        userId: userId,
        isPremium: isPremium,
        bonusLikes: bonusLikes,
      );

      // Subscribe to limit updates
      _limitSubscription?.cancel();
      _limitSubscription = _service.limitStream.listen(
        (updatedLimit) {
          emit(state.copyWith(limit: updatedLimit));
        },
      );

      emit(state.copyWith(limit: limit, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load likes limit',
      ));
    }
  }

  /// Use a like and get the result.
  Future<LikeResult> useLike() async {
    final result = await _service.useLike();
    emit(state.copyWith(lastLikeResult: result));
    return result;
  }

  /// Use a super like and get the result.
  Future<LikeResult> useSuperLike() async {
    final result = await _service.useSuperLike();
    emit(state.copyWith(lastLikeResult: result));
    return result;
  }

  /// Upgrade to premium (unlimited likes).
  Future<void> upgradeToPremium() async {
    await _service.upgradeToPremium();
  }

  /// Add bonus likes.
  Future<void> addBonusLikes(int count) async {
    await _service.addBonusLikes(count);
  }

  /// Clear last like result message.
  void clearLastResult() {
    emit(state.copyWith(lastLikeResult: null));
  }

  @override
  Future<void> close() {
    _limitSubscription?.cancel();
    return super.close();
  }
}
