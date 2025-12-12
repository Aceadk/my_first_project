import 'package:equatable/equatable.dart';
import '../../data/models/profile.dart';

class DiscoveryState extends Equatable {
  final List<Profile> deck;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;

  const DiscoveryState({
    this.deck = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  DiscoveryState copyWith({
    List<Profile>? deck,
    int? currentIndex,
    bool? isLoading,
    String? errorMessage, // pass null explicitly to clear
  }) {
    return DiscoveryState(
      deck: deck ?? this.deck,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [deck, currentIndex, isLoading, errorMessage];
}
