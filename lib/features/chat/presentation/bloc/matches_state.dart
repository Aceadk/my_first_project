import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/match.dart';

/// Matches loading status.
enum MatchesStatus {
  /// Initial state, no load attempted yet.
  initial,

  /// Loading matches from server.
  loading,

  /// Matches loaded successfully.
  loaded,

  /// No matches found (empty state).
  empty,

  /// Error loading matches (after retries exhausted).
  error,
}

class MatchesState extends Equatable {
  final List<CrushMatch> matches;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int total;
  final String? errorMessage;
  final MatchesStatus status;
  final int? nextRetrySeconds;
  static const _unset = Object();

  const MatchesState({
    this.matches = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.total = 0,
    this.errorMessage,
    this.status = MatchesStatus.initial,
    this.nextRetrySeconds,
  });

  MatchesState copyWith({
    List<CrushMatch>? matches,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? total,
    Object? errorMessage = _unset,
    MatchesStatus? status,
    Object? nextRetrySeconds = _unset,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      status: status ?? this.status,
      nextRetrySeconds: identical(nextRetrySeconds, _unset)
          ? this.nextRetrySeconds
          : nextRetrySeconds as int?,
    );
  }

  @override
  List<Object?> get props => [
        matches,
        isLoading,
        isLoadingMore,
        hasMore,
        total,
        errorMessage,
        status,
        nextRetrySeconds,
      ];
}
