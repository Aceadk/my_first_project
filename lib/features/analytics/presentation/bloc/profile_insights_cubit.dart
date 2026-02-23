import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';
import 'package:crushhour/features/analytics/domain/repositories/profile_insights_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  ProfileInsightsCubit({
    required AuthRepository authRepository,
    required ProfileInsightsRepository insightsRepository,
  }) : _authRepository = authRepository,
       _service = insightsRepository,
       super(const ProfileInsightsState()) {
    _authSubscription = _authRepository.authStateChanges().listen((user) {
      if (user == null) {
        _resetState();
      }
    });
  }

  final AuthRepository _authRepository;
  final ProfileInsightsRepository _service;
  StreamSubscription<ProfileInsights>? _subscription;
  StreamSubscription<CrushUser?>? _authSubscription;

  /// Load insights for user.
  Future<void> loadInsights(String userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final insights = await _service.loadInsights(userId);
      final photoPerformance = _service.getPhotoPerformance();

      _subscription?.cancel();
      _subscription = _service.insightsStream.listen((updatedInsights) {
        emit(
          state.copyWith(
            insights: updatedInsights,
            photoPerformance: _service.getPhotoPerformance(),
          ),
        );
      });

      emit(
        state.copyWith(
          insights: insights,
          photoPerformance: photoPerformance,
          isLoading: false,
        ),
      );
    } catch (e, s) {
      AppLogger.blocError(
        bloc: 'ProfileInsightsCubit',
        action: 'loadInsights',
        error: e,
        stackTrace: s,
      );
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorMessages.loadInsightsFailed,
        ),
      );
    }
  }

  /// Refresh insights.
  Future<void> refreshInsights(String userId) async {
    emit(state.copyWith(isRefreshing: true, errorMessage: null));

    try {
      final insights = await _service.refreshInsights(userId);
      final photoPerformance = _service.getPhotoPerformance();

      emit(
        state.copyWith(
          insights: insights,
          photoPerformance: photoPerformance,
          isRefreshing: false,
        ),
      );
    } catch (e, s) {
      AppLogger.blocError(
        bloc: 'ProfileInsightsCubit',
        action: 'refreshInsights',
        error: e,
        stackTrace: s,
      );
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: ErrorMessages.loadInsightsFailed,
        ),
      );
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

      emit(state.copyWith(insights: insights, isLoading: false));
    } catch (e, s) {
      AppLogger.blocError(
        bloc: 'ProfileInsightsCubit',
        action: 'getInsightsForRange',
        error: e,
        stackTrace: s,
      );
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load insights for date range',
        ),
      );
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

  void _resetState() {
    _subscription?.cancel();
    _subscription = null;
    _service.clearUserData();
    if (!isClosed) {
      emit(const ProfileInsightsState());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
