import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/profile.dart';

enum DeckStatus { initial, loading, ready, empty, error }

/// Represents a match that just occurred.
class MatchResult {
  const MatchResult({
    required this.matchId,
    required this.matchedProfile,
  });

  final String matchId;
  final Profile matchedProfile;
}

class DiscoveryState extends Equatable {
  final List<Profile> deck;
  final int currentIndex;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreProfiles;
  final DeckStatus status;
  final String? errorMessage;
  final int? nextRetrySeconds;
  /// Set when a match occurs, should be cleared after showing celebration.
  final MatchResult? newMatch;

  const DiscoveryState({
    this.deck = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreProfiles = true,
    this.status = DeckStatus.initial,
    this.errorMessage,
    this.nextRetrySeconds,
    this.newMatch,
  });

  /// Number of profiles remaining in the deck
  int get remainingProfiles => deck.length - currentIndex;

  /// Whether we should preload more profiles (when < 5 remaining)
  bool get shouldLoadMore => remainingProfiles < 5 && hasMoreProfiles && !isLoadingMore;

  static const _unset = Object();

  DiscoveryState copyWith({
    List<Profile>? deck,
    int? currentIndex,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreProfiles,
    DeckStatus? status,
    String? errorMessage, // pass null explicitly to clear
    int? nextRetrySeconds,
    Object? newMatch = _unset,
  }) {
    return DiscoveryState(
      deck: deck ?? this.deck,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreProfiles: hasMoreProfiles ?? this.hasMoreProfiles,
      status: status ?? this.status,
      errorMessage: errorMessage,
      nextRetrySeconds: nextRetrySeconds,
      newMatch: identical(newMatch, _unset) ? this.newMatch : newMatch as MatchResult?,
    );
  }

  @override
  List<Object?> get props =>
      [deck, currentIndex, isLoading, isLoadingMore, hasMoreProfiles, status, errorMessage, nextRetrySeconds, newMatch];
}
