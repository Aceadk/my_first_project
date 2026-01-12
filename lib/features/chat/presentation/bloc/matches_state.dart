import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/match.dart';

class MatchesState extends Equatable {
  final List<CrushMatch> matches;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int total;
  final String? errorMessage;
  static const _unset = Object();

  const MatchesState({
    this.matches = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.total = 0,
    this.errorMessage,
  });

  MatchesState copyWith({
    List<CrushMatch>? matches,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? total,
    Object? errorMessage = _unset,
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
    );
  }

  @override
  List<Object?> get props => [matches, isLoading, isLoadingMore, hasMore, total, errorMessage];
}
