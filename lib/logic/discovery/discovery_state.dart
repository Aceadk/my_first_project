import 'package:equatable/equatable.dart';
import '../../data/models/profile.dart';

enum DeckStatus { initial, loading, ready, empty, error }

class DiscoveryState extends Equatable {
  final List<Profile> deck;
  final int currentIndex;
  final bool isLoading;
  final DeckStatus status;
  final String? errorMessage;
  final int? nextRetrySeconds;

  const DiscoveryState({
    this.deck = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.status = DeckStatus.initial,
    this.errorMessage,
    this.nextRetrySeconds,
  });

  DiscoveryState copyWith({
    List<Profile>? deck,
    int? currentIndex,
    bool? isLoading,
    DeckStatus? status,
    String? errorMessage, // pass null explicitly to clear
    int? nextRetrySeconds,
  }) {
    return DiscoveryState(
      deck: deck ?? this.deck,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      errorMessage: errorMessage,
      nextRetrySeconds: nextRetrySeconds,
    );
  }

  @override
  List<Object?> get props =>
      [deck, currentIndex, isLoading, status, errorMessage, nextRetrySeconds];
}
