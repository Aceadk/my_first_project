import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/features/discovery/data/repositories/boost_repository.dart';

/// State for boost feature.
class BoostState extends Equatable {
  const BoostState({
    this.status = const BoostStatus(canBoost: false, nextBoostAvailableAt: null),
    this.isLoading = false,
    this.errorMessage,
  });

  final BoostStatus status;
  final bool isLoading;
  final String? errorMessage;

  /// Whether the user can activate a boost right now.
  bool get canBoost => status.canBoost && !isLoading;

  /// Whether a boost is currently active.
  bool get isBoostActive => status.isBoostActive;

  /// Remaining duration of active boost.
  Duration get boostRemaining => status.activeSession?.remainingDuration ?? Duration.zero;

  /// Remaining cooldown until next boost is available.
  Duration get cooldownRemaining => status.cooldownRemaining;

  BoostState copyWith({
    BoostStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BoostState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isLoading, errorMessage];
}

/// Cubit for managing boost feature.
class BoostCubit extends Cubit<BoostState> {
  BoostCubit({
    required BoostRepository boostRepository,
  })  : _boostRepository = boostRepository,
        super(const BoostState());

  final BoostRepository _boostRepository;
  Timer? _countdownTimer;
  String? _userId;

  /// Initialize boost status for a user.
  Future<void> initialize(String userId) async {
    _userId = userId;
    emit(state.copyWith(isLoading: true));

    final result = await Result.guard(
      () => _boostRepository.getBoostStatus(userId),
      logLabel: 'BoostRepository.getBoostStatus',
      fallbackError: 'Could not load boost status.',
    );

    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(
        status: result.data,
        isLoading: false,
      ));

      // Start countdown timer if boost is active or on cooldown
      _startCountdownTimer();
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
    }
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
      emit(state.copyWith(
        status: BoostStatus(
          canBoost: false,
          nextBoostAvailableAt: session.endsAt,
          activeSession: session,
          boostsRemaining: 0,
        ),
        isLoading: false,
      ));

      // Track boost activation
      AnalyticsService.instance.logBoostActivated();

      // Start countdown timer
      _startCountdownTimer();
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  /// Start a timer to update the countdown.
  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    // Update every second while boost is active or on cooldown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;

      final currentStatus = state.status;

      // Check if boost just ended
      if (currentStatus.activeSession != null &&
          currentStatus.activeSession!.hasExpired) {
        // Boost ended - refresh status
        if (_userId != null) {
          initialize(_userId!);
        }
        return;
      }

      // Check if cooldown just ended
      if (!currentStatus.canBoost &&
          currentStatus.cooldownRemaining == Duration.zero &&
          currentStatus.activeSession == null) {
        // Cooldown ended - refresh status
        if (_userId != null) {
          initialize(_userId!);
        }
        return;
      }

      // Just emit to trigger rebuild for countdown display
      emit(state.copyWith(status: currentStatus));
    });
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
