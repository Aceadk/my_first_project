import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';
import 'package:crushhour/features/analytics/data/models/profile_insights.dart';

/// State for profile insights.
class ProfileInsightsState extends Equatable {
  const ProfileInsightsState({
    this.insights,
    this.photoPerformance = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final ProfileInsights? insights;
  final List<PhotoPerformance> photoPerformance;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  // Convenience getters
  int get profileViews => insights?.profileViews ?? 0;
  int get likesReceived => insights?.likesReceived ?? 0;
  int get likesSent => insights?.likesSent ?? 0;
  int get superLikesReceived => insights?.superLikesReceived ?? 0;
  double get matchRate => insights?.matchRate ?? 0;
  double get responseRate => insights?.responseRate ?? 0;
  Duration? get averageResponseTime => insights?.averageResponseTime;
  int? get peakActivityHour => insights?.peakActivityHour;
  List<DailyMetric> get weeklyTrend => insights?.weeklyTrend ?? [];

  ProfileInsightsState copyWith({
    ProfileInsights? insights,
    List<PhotoPerformance>? photoPerformance,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return ProfileInsightsState(
      insights: insights ?? this.insights,
      photoPerformance: photoPerformance ?? this.photoPerformance,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        insights,
        photoPerformance,
        isLoading,
        isRefreshing,
        errorMessage,
      ];
}

/// Cubit for managing profile insights state.
class ProfileInsightsCubit extends Cubit<ProfileInsightsState> {
  ProfileInsightsCubit() : super(const ProfileInsightsState());

  final _service = ProfileInsightsService.instance;
  StreamSubscription<ProfileInsights>? _subscription;

  /// Load insights for user.
  Future<void> loadInsights(String userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final insights = await _service.loadInsights(userId);
      final photoPerformance = _service.getPhotoPerformance();

      _subscription?.cancel();
      _subscription = _service.insightsStream.listen(
        (updatedInsights) {
          emit(state.copyWith(
            insights: updatedInsights,
            photoPerformance: _service.getPhotoPerformance(),
          ));
        },
      );

      emit(state.copyWith(
        insights: insights,
        photoPerformance: photoPerformance,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load insights',
      ));
    }
  }

  /// Refresh insights.
  Future<void> refreshInsights(String userId) async {
    emit(state.copyWith(isRefreshing: true, errorMessage: null));

    try {
      final insights = await _service.refreshInsights(userId);
      final photoPerformance = _service.getPhotoPerformance();

      emit(state.copyWith(
        insights: insights,
        photoPerformance: photoPerformance,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh insights',
      ));
    }
  }

  /// Get insights for a specific date range.
  Future<void> getInsightsForRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final insights = await _service.getInsightsForRange(
        userId: userId,
        start: start,
        end: end,
      );

      emit(state.copyWith(
        insights: insights,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load insights for date range',
      ));
    }
  }

  /// Record a profile view.
  Future<void> recordProfileView(String viewerUserId) async {
    await _service.recordProfileView(viewerUserId);
  }

  /// Record a like received.
  Future<void> recordLikeReceived({bool isSuperLike = false}) async {
    await _service.recordLikeReceived(isSuperLike: isSuperLike);
  }

  /// Record a like sent.
  Future<void> recordLikeSent() async {
    await _service.recordLikeSent();
  }

  /// Get best time to be active.
  String getBestTimeToBeActive() => _service.getBestTimeToBeActive();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
