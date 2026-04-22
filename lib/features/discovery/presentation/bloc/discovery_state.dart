import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/profile.dart';

enum DeckStatus { initial, loading, ready, empty, error }

/// Represents a match that just occurred.
class MatchResult {
  const MatchResult({required this.matchId, required this.matchedProfile});

  final String matchId;
  final Profile matchedProfile;
}

class DiscoveryState extends Equatable {
  final List<Profile> deck;
  final int currentIndex;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreProfiles;
  final String? nextCursor;
  final DeckStatus status;
  final String? errorMessage;
  final int? nextRetrySeconds;
  final String? premiumGateSource;

  /// Set when a match occurs, should be cleared after showing celebration.
  final MatchResult? newMatch;

  /// Whether local deck (within 220km) has been exhausted.
  /// When true, users can see people beyond 220km.
  final bool localDeckExhausted;

  /// Whether Passport mode is active (Plus feature).
  /// When true, shows global profiles regardless of distance.
  final bool passportModeActive;

  /// Current effective distance limit in km.
  final double currentDistanceLimitKm;

  /// Super Likes remaining today (1 free, 7 premium).
  final int superLikesRemaining;

  /// Date when super likes count was last reset.
  final DateTime? superLikesResetDate;

  /// Last swiped profile for rewind feature (premium only).
  final Profile? lastSwipedProfile;

  /// Direction of last swipe ('left' or 'right') for rewind.
  final String? lastSwipeDirection;

  /// Whether rewind is available (premium only, within time limit).
  final bool canRewind;

  /// Whether free user has used their daily undo.
  final bool freeUndoUsedToday;

  /// Date when free undo was last used (for daily reset).
  final DateTime? freeUndoLastUsedDate;

  const DiscoveryState({
    this.deck = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreProfiles = true,
    this.nextCursor,
    this.status = DeckStatus.initial,
    this.errorMessage,
    this.nextRetrySeconds,
    this.premiumGateSource,
    this.newMatch,
    this.localDeckExhausted = false,
    this.passportModeActive = false,
    this.currentDistanceLimitKm = 220.0,
    this.superLikesRemaining = 1,
    this.superLikesResetDate,
    this.lastSwipedProfile,
    this.lastSwipeDirection,
    this.canRewind = false,
    this.freeUndoUsedToday = false,
    this.freeUndoLastUsedDate,
  });

  /// Number of profiles remaining in the deck
  int get remainingProfiles => deck.length - currentIndex;

  /// Whether we should preload more profiles (when < 5 remaining)
  bool get shouldLoadMore =>
      remainingProfiles < 5 && hasMoreProfiles && !isLoadingMore;

  /// Whether free undo is available today (resets at midnight).
  bool get hasFreeUndoAvailable {
    if (freeUndoLastUsedDate == null) return true;
    final now = DateTime.now();
    final isNewDay =
        now.year != freeUndoLastUsedDate!.year ||
        now.month != freeUndoLastUsedDate!.month ||
        now.day != freeUndoLastUsedDate!.day;
    return isNewDay || !freeUndoUsedToday;
  }

  static const _unset = Object();

  DiscoveryState copyWith({
    List<Profile>? deck,
    int? currentIndex,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreProfiles,
    Object? nextCursor = _unset,
    DeckStatus? status,
    String? errorMessage, // pass null explicitly to clear
    int? nextRetrySeconds,
    Object? premiumGateSource = _unset,
    Object? newMatch = _unset,
    bool? localDeckExhausted,
    bool? passportModeActive,
    double? currentDistanceLimitKm,
    int? superLikesRemaining,
    Object? superLikesResetDate = _unset,
    Object? lastSwipedProfile = _unset,
    Object? lastSwipeDirection = _unset,
    bool? canRewind,
    bool? freeUndoUsedToday,
    Object? freeUndoLastUsedDate = _unset,
  }) {
    return DiscoveryState(
      deck: deck ?? this.deck,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreProfiles: hasMoreProfiles ?? this.hasMoreProfiles,
      nextCursor: identical(nextCursor, _unset)
          ? this.nextCursor
          : nextCursor as String?,
      status: status ?? this.status,
      errorMessage: errorMessage,
      nextRetrySeconds: nextRetrySeconds,
      premiumGateSource: identical(premiumGateSource, _unset)
          ? this.premiumGateSource
          : premiumGateSource as String?,
      newMatch: identical(newMatch, _unset)
          ? this.newMatch
          : newMatch as MatchResult?,
      localDeckExhausted: localDeckExhausted ?? this.localDeckExhausted,
      passportModeActive: passportModeActive ?? this.passportModeActive,
      currentDistanceLimitKm:
          currentDistanceLimitKm ?? this.currentDistanceLimitKm,
      superLikesRemaining: superLikesRemaining ?? this.superLikesRemaining,
      superLikesResetDate: identical(superLikesResetDate, _unset)
          ? this.superLikesResetDate
          : superLikesResetDate as DateTime?,
      lastSwipedProfile: identical(lastSwipedProfile, _unset)
          ? this.lastSwipedProfile
          : lastSwipedProfile as Profile?,
      lastSwipeDirection: identical(lastSwipeDirection, _unset)
          ? this.lastSwipeDirection
          : lastSwipeDirection as String?,
      canRewind: canRewind ?? this.canRewind,
      freeUndoUsedToday: freeUndoUsedToday ?? this.freeUndoUsedToday,
      freeUndoLastUsedDate: identical(freeUndoLastUsedDate, _unset)
          ? this.freeUndoLastUsedDate
          : freeUndoLastUsedDate as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    deck,
    currentIndex,
    isLoading,
    isLoadingMore,
    hasMoreProfiles,
    nextCursor,
    status,
    errorMessage,
    nextRetrySeconds,
    premiumGateSource,
    newMatch,
    localDeckExhausted,
    passportModeActive,
    currentDistanceLimitKm,
    superLikesRemaining,
    superLikesResetDate,
    lastSwipedProfile,
    lastSwipeDirection,
    canRewind,
    freeUndoUsedToday,
    freeUndoLastUsedDate,
  ];
}
