import 'dart:async';

import 'package:crushhour/core/utils/auth_state_reset_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/boost_repository.dart';

/// State for boost feature.
class BoostState extends Equatable {
  const BoostState({
    this.status = const BoostStatus(
      canBoost: false,
      nextBoostAvailableAt: null,
    ),
    this.isLoading = false,
    this.errorMessage,
    this.tick = 0,
  });

  final BoostStatus status;
  final bool isLoading;
  final String? errorMessage;

  /// Tick counter that increments each second to force UI rebuilds for countdown
  final int tick;

  /// Whether the user can activate a boost right now.
  bool get canBoost => status.canBoost && !isLoading;

  /// Whether a boost is currently active.
  bool get isBoostActive => status.isBoostActive;

  /// Remaining duration of active boost.
  Duration get boostRemaining =>
      status.activeSession?.remainingDuration ?? Duration.zero;

  /// Remaining cooldown until next boost is available.
  Duration get cooldownRemaining => status.cooldownRemaining;

  BoostState copyWith({
    BoostStatus? status,
    bool? isLoading,
    String? errorMessage,
    int? tick,
  }) {
    return BoostState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      tick: tick ?? this.tick,
    );
  }

  @override
  List<Object?> get props => [status, isLoading, errorMessage, tick];
}

/// Cubit for managing boost feature.
class BoostCubit extends Cubit<BoostState> {
  BoostCubit({
    required BoostRepository boostRepository,
    required AuthRepository authRepository,
  }) : _boostRepository = boostRepository,
       super(const BoostState()) {
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (_authResetPolicy.shouldResetFor(user)) {
        _resetOnLogout();
      }
    });
  }

  final BoostRepository _boostRepository;
  final AuthStateResetPolicy _authResetPolicy = AuthStateResetPolicy();
  StreamSubscription? _authSubscription;
  Timer? _countdownTimer;
  String? _userId;
  bool _isRefreshing = false;

  /// Initialize boost status for a user.
  Future<void> initialize(String userId) async {
    _userId = userId;
    await _refreshStatus(showLoading: true);
  }

  /// Activate a boost for the current user.
  Future<void> activateBoost() async {
    if (_userId == null || !state.canBoost) return;

    emit(state.copyWith(isLoading: true));

    final result = await Result.guard(
      () => _boostRepository.activateBoost(_userId!),
      logLabel: 'BoostRepository.activateBoost',
      fallbackError: 'Could not activate boost. Please try again.',
    );

    if (result.isSuccess && result.data != null) {
      final session = result.data!;
      emit(
        state.copyWith(
          status: BoostStatus(
            canBoost: false,
            nextBoostAvailableAt: session.endsAt,
            activeSession: session,
            boostsRemaining: 0,
          ),
          isLoading: false,
        ),
      );

      // Track boost activation
      AnalyticsService.instance.logBoostActivated();

      // Start countdown timer
      _startCountdownTimer(state.status);
    } else {
      emit(state.copyWith(isLoading: false, errorMessage: result.errorMessage));
    }
  }

  Future<void> _refreshStatus({bool showLoading = false}) async {
    if (_userId == null || _isRefreshing) return;
    _isRefreshing = true;

    if (showLoading) {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    try {
      final result = await Result.guard(
        () => _boostRepository.getBoostStatus(_userId!),
        logLabel: 'BoostRepository.getBoostStatus',
        fallbackError: 'Could not load boost status.',
      );

      if (isClosed) return;

      if (result.isSuccess && result.data != null) {
        final status = result.data!;
        emit(
          state.copyWith(status: status, isLoading: false, errorMessage: null),
        );

        _startCountdownTimer(status);
      } else {
        _countdownTimer?.cancel();
        emit(
          state.copyWith(isLoading: false, errorMessage: result.errorMessage),
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Start a timer to update the countdown.
  void _startCountdownTimer(BoostStatus status) {
    _countdownTimer?.cancel();

    if (!_shouldStartCountdown(status)) {
      return;
    }

    // Update every second while boost is active or on cooldown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed || _isRefreshing) return;

      final currentStatus = state.status;

      // Check if boost just ended
      if (currentStatus.activeSession != null &&
          currentStatus.activeSession!.hasExpired) {
        _countdownTimer?.cancel();
        _refreshStatus();
        return;
      }

      // Check if cooldown just ended
      if (!currentStatus.canBoost &&
          currentStatus.cooldownRemaining == Duration.zero &&
          currentStatus.activeSession == null) {
        _countdownTimer?.cancel();
        _refreshStatus();
        return;
      }

      // Increment tick to force UI rebuild for countdown display
      // This is needed because Equatable compares object references,
      // not the dynamic getter values like remainingDuration
      emit(state.copyWith(tick: state.tick + 1));
    });
  }

  bool _shouldStartCountdown(BoostStatus status) {
    if (status.activeSession != null && !status.activeSession!.hasExpired) {
      return true;
    }
    return !status.canBoost && status.cooldownRemaining > Duration.zero;
  }

  /// Reset all user-specific state on logout to prevent data leakage.
  void _resetOnLogout() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _userId = null;
    _isRefreshing = false;
    emit(const BoostState());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
