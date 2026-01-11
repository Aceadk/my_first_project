import 'package:equatable/equatable.dart';
import '../../data/models/profile.dart';

enum DeckStatus { initial, loading, ready, empty, error }

class DiscoveryState extends Equatable {
  final List<Profile> deck;
  final int currentIndex;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreProfiles;
  final DeckStatus status;
  final String? errorMessage;
  final int? nextRetrySeconds;

  const DiscoveryState({
    this.deck = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreProfiles = true,
    this.status = DeckStatus.initial,
    this.errorMessage,
    this.nextRetrySeconds,
  });

  /// Number of profiles remaining in the deck
  int get remainingProfiles => deck.length - currentIndex;

  /// Whether we should preload more profiles (when < 5 remaining)
  bool get shouldLoadMore => remainingProfiles < 5 && hasMoreProfiles && !isLoadingMore;

  DiscoveryState copyWith({
    List<Profile>? deck,
    int? currentIndex,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreProfiles,
    DeckStatus? status,
    String? errorMessage, // pass null explicitly to clear
    int? nextRetrySeconds,
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
    );
  }

  @override
  List<Object?> get props =>
      [deck, currentIndex, isLoading, isLoadingMore, hasMoreProfiles, status, errorMessage, nextRetrySeconds];
}
