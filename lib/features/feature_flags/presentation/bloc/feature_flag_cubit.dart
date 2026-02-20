import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/features/feature_flags/domain/models/feature_flags.dart';
import '../../domain/repositories/feature_flag_repository.dart';

/// Cubit for managing feature flag state reactively.
///
/// Listens to feature flag updates from the repository and provides
/// easy access to current flags throughout the app.
class FeatureFlagCubit extends Cubit<FeatureFlagState> {
  FeatureFlagCubit({required FeatureFlagRepository repository})
    : _repository = repository,
      super(const FeatureFlagState.initial()) {
    _subscription = _repository.flagsStream.listen(_onFlagsUpdated);
  }

  final FeatureFlagRepository _repository;
  StreamSubscription<FeatureFlags>? _subscription;

  /// Initialize the feature flags
  Future<void> initialize() async {
    emit(state.copyWith(status: FeatureFlagStatus.loading));
    try {
      await _repository.initialize();
      emit(
        state.copyWith(
          status: FeatureFlagStatus.loaded,
          flags: _repository.flags,
          lastFetchTime: _repository.lastFetchTime,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FeatureFlagStatus.error,
          errorMessage: ErrorMessages.generic,
          flags: FeatureFlags.defaults,
        ),
      );
    }
  }

  /// Refresh flags from remote
  Future<void> refresh() async {
    emit(state.copyWith(status: FeatureFlagStatus.refreshing));
    try {
      final success = await _repository.fetchAndActivate();
      emit(
        state.copyWith(
          status: success ? FeatureFlagStatus.loaded : FeatureFlagStatus.error,
          flags: _repository.flags,
          lastFetchTime: _repository.lastFetchTime,
          errorMessage: success ? null : ErrorMessages.generic,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FeatureFlagStatus.error,
          errorMessage: ErrorMessages.generic,
        ),
      );
    }
  }

  /// Force refresh flags (bypasses cache)
  Future<void> forceRefresh() async {
    emit(state.copyWith(status: FeatureFlagStatus.refreshing));
    try {
      await _repository.forceRefresh();
      emit(
        state.copyWith(
          status: FeatureFlagStatus.loaded,
          flags: _repository.flags,
          lastFetchTime: _repository.lastFetchTime,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FeatureFlagStatus.error,
          errorMessage: ErrorMessages.generic,
        ),
      );
    }
  }

  void _onFlagsUpdated(FeatureFlags flags) {
    emit(state.copyWith(flags: flags, lastFetchTime: DateTime.now()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current feature flags
  FeatureFlags get flags => state.flags;

  /// Check if a feature is enabled
  bool isEnabled(String flagName) {
    return _repository.getBool(flagName, defaultValue: false);
  }

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode => flags.maintenanceMode;

  /// Check if force update is required
  bool get requiresForceUpdate => flags.forceUpdate;

  /// Get the maintenance message
  String get maintenanceMessage => flags.maintenanceMessage;

  /// Get the force update message
  String get forceUpdateMessage => flags.forceUpdateMessage;

  /// Get the minimum required app version
  String get minAppVersion => flags.minAppVersion;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

/// Status of feature flag loading
enum FeatureFlagStatus { initial, loading, loaded, refreshing, error }

/// State for the FeatureFlagCubit
class FeatureFlagState {
  const FeatureFlagState({
    required this.status,
    required this.flags,
    this.lastFetchTime,
    this.errorMessage,
  });

  const FeatureFlagState.initial()
    : status = FeatureFlagStatus.initial,
      flags = const FeatureFlags(),
      lastFetchTime = null,
      errorMessage = null;

  final FeatureFlagStatus status;
  final FeatureFlags flags;
  final DateTime? lastFetchTime;
  final String? errorMessage;

  bool get isLoading =>
      status == FeatureFlagStatus.loading ||
      status == FeatureFlagStatus.refreshing;

  bool get hasError => status == FeatureFlagStatus.error;

  bool get isLoaded => status == FeatureFlagStatus.loaded;

  FeatureFlagState copyWith({
    FeatureFlagStatus? status,
    FeatureFlags? flags,
    DateTime? lastFetchTime,
    String? errorMessage,
  }) {
    return FeatureFlagState(
      status: status ?? this.status,
      flags: flags ?? this.flags,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      errorMessage: errorMessage,
    );
  }
}
