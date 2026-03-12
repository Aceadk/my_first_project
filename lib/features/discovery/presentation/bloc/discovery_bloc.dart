import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/performance/performance_monitor.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/usecases/swipe_right.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/domain/usecases/check_entitlement.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository discoveryRepository;
  final SubscriptionRepository subscriptionRepository;
  final ProfileRepository? profileRepository;
  final AuthRepository authRepository;
  final SwipeRightUseCase swipeRightUseCase;
  final CheckEntitlementUseCase checkEntitlementUseCase;

  StreamSubscription? _authSubscription;
  Timer? _retryTimer;
  int _retryDelayMs = 1000;
  int _retryCount = 0;
  static const int _maxAutoRetries = 2;
  String? _lastRequestedUserId;
  bool _isManualRefresh = false;

  /// Cached user preferences for distance filtering.
  DiscoveryPreferences? _cachedPreferences;

  /// User's current location for distance calculation.
  double? _userLatitude;
  double? _userLongitude;

  DiscoveryBloc({
    required this.discoveryRepository,
    required this.subscriptionRepository,
    required this.authRepository,
    required this.swipeRightUseCase,
    CheckEntitlementUseCase? checkEntitlementUseCase,
    this.profileRepository,
  }) : checkEntitlementUseCase =
           checkEntitlementUseCase ??
           CheckEntitlementUseCase(subscriptionRepository),
       super(const DiscoveryState()) {
    on<DiscoveryDeckRequested>(_onDeckRequested);
    on<DiscoverySwipedRight>(_onSwipedRight);
    on<DiscoverySwipedLeft>(_onSwipedLeft);
    on<DiscoveryLoadMoreRequested>(_onLoadMoreRequested);
    on<DiscoveryMatchCelebrationShown>(_onMatchCelebrationShown);
    on<DiscoveryPremiumGateHandled>(_onPremiumGateHandled);
    on<DiscoverySuperLiked>(_onSuperLiked);
    on<DiscoveryRewindRequested>(_onRewindRequested);
    on<DiscoveryResetRequested>(_onResetRequested);

    // Listen to auth state changes to reset on logout
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (user == null) {
        // CRITICAL: Reset state on logout to prevent data leakage to next user
        add(DiscoveryResetRequested());
      }
    });
  }

  void _onMatchCelebrationShown(
    DiscoveryMatchCelebrationShown event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(state.copyWith(newMatch: null));
  }

  void _onPremiumGateHandled(
    DiscoveryPremiumGateHandled event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(state.copyWith(premiumGateSource: null));
  }

  /// Reset discovery state on logout.
  /// CRITICAL: Prevents data leakage to next user.
  void _onResetRequested(
    DiscoveryResetRequested event,
    Emitter<DiscoveryState> emit,
  ) {
    AppLogger.debug('DiscoveryBloc: Resetting discovery state on logout');
    _retryTimer?.cancel();
    _retryCount = 0;
    _retryDelayMs = 1000;
    _lastRequestedUserId = null;
    _isManualRefresh = false;
    swipeRightUseCase.resetDailyCounter();
    checkEntitlementUseCase.clearCache();
    _cachedPreferences = null;
    _userLatitude = null;
    _userLongitude = null;
    emit(const DiscoveryState()); // Reset to initial empty state
  }

  Future<void> _onDeckRequested(
    DiscoveryDeckRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Track if this is a manual refresh (user-triggered) vs auto-retry
    final isManualRefresh =
        _lastRequestedUserId != event.userId ||
        _isManualRefresh ||
        state.status != DeckStatus.error;

    if (isManualRefresh) {
      _retryCount = 0;
      _retryDelayMs = 1000;
    }
    _isManualRefresh = false;

    _lastRequestedUserId = event.userId;
    _retryTimer?.cancel();
    emit(
      state.copyWith(
        isLoading: true,
        status: DeckStatus.loading,
        errorMessage: null,
        nextRetrySeconds: null,
      ),
    );

    // Get subscription plan first to check for Plus/Passport mode
    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not load people. Please try again.',
    );

    if (!planResult.isSuccess) {
      _handleFetchError(planResult.errorMessage, emit);
      return;
    }

    final tier = planResult.data ?? SubscriptionTier.free;

    // Load user profile to get location and preferences
    await _loadUserPreferencesAndLocation();

    final prefs = _cachedPreferences;
    final isPremiumUser = tier.hasPremium;
    final passportModeEnabled =
        isPremiumUser && (prefs?.passportModeEnabled ?? false);

    // Determine distance limit based on subscription and passport mode
    double distanceLimit;
    bool localDeckExhausted = state.localDeckExhausted;

    if (passportModeEnabled) {
      // Plus users with Passport mode can see globally
      distanceLimit = CrushConstants.globalDistanceKm;
    } else if (localDeckExhausted) {
      // Local deck exhausted - extend to 500km
      distanceLimit = CrushConstants.extendedMaxDistanceKm;
    } else {
      // Default: 220km limit
      distanceLimit = CrushConstants.defaultMaxDistanceKm;
    }

    // Build discovery filter
    final filter = DiscoveryFilter(
      maxDistanceKm: distanceLimit.isFinite ? distanceLimit : null,
      passportModeEnabled: passportModeEnabled,
      localDeckExhausted: localDeckExhausted,
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
      passportLatitude: prefs?.passportLatitude,
      passportLongitude: prefs?.passportLongitude,
    );

    // Fetch deck with distance filter
    await PerformanceMonitor.instance.startTrace('deck_fetch');
    final deckResult = await Result.guard(
      () => discoveryRepository.fetchDeck(event.userId, filter: filter),
      logLabel: 'DiscoveryRepository.fetchDeck',
      fallbackError: 'Could not load people. Please try again.',
    );

    if (!deckResult.isSuccess) {
      await PerformanceMonitor.instance.stopTrace(
        'deck_fetch',
        metrics: {'success': 0},
      );
      _handleFetchError(deckResult.errorMessage, emit);
      return;
    }

    var deck = deckResult.data ?? const [];
    await PerformanceMonitor.instance.stopTrace(
      'deck_fetch',
      metrics: {'success': 1, 'card_count': deck.length},
    );

    // If local deck is empty and not yet exhausted, try extended distance
    if (deck.isEmpty && !localDeckExhausted && !passportModeEnabled) {
      localDeckExhausted = true;

      // Retry with extended distance
      final extendedFilter = DiscoveryFilter(
        maxDistanceKm: CrushConstants.extendedMaxDistanceKm,
        passportModeEnabled: false,
        localDeckExhausted: true,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );

      final extendedResult = await Result.guard(
        () =>
            discoveryRepository.fetchDeck(event.userId, filter: extendedFilter),
        logLabel: 'DiscoveryRepository.fetchDeck (extended)',
        fallbackError: 'Could not load people. Please try again.',
      );

      if (extendedResult.isSuccess) {
        deck = extendedResult.data ?? const [];
        distanceLimit = CrushConstants.extendedMaxDistanceKm;
      }
    }

    // Success - reset retry state
    _retryCount = 0;
    _retryDelayMs = 1000;

    // Track deck loaded or empty
    if (deck.isEmpty) {
      AnalyticsService.instance.logDeckEmpty();
    } else {
      AnalyticsService.instance.logDeckLoaded(cardCount: deck.length);
    }

    emit(
      state.copyWith(
        isLoading: false,
        deck: deck,
        currentIndex: 0,
        status: deck.isEmpty ? DeckStatus.empty : DeckStatus.ready,
        errorMessage: null,
        nextRetrySeconds: null,
        localDeckExhausted: localDeckExhausted,
        passportModeActive: passportModeEnabled,
        currentDistanceLimitKm: distanceLimit.isFinite ? distanceLimit : 0,
      ),
    );
  }

  /// Load user preferences and location from profile repository.
  Future<void> _loadUserPreferencesAndLocation() async {
    if (profileRepository == null) return;

    final userResult = await Result.guard(
      () => profileRepository!.getCurrentUser(),
      logLabel: 'ProfileRepository.getCurrentUser',
      fallbackError: 'Could not load user profile.',
    );

    if (userResult.isSuccess && userResult.data != null) {
      final profile = userResult.data!.profile;
      if (profile != null) {
        _cachedPreferences = profile.preferences;
        _userLatitude = profile.latitude;
        _userLongitude = profile.longitude;
      }
    }
  }

  /// Handle fetch errors with retry logic.
  void _handleFetchError(String? errorMsg, Emitter<DiscoveryState> emit) {
    _retryCount++;

    // Check if error indicates "no people" rather than actual failure
    final isNoPeopleError = _isNoPeopleError(errorMsg);

    // If we've retried enough times or error indicates no people, show empty state
    if (_retryCount > _maxAutoRetries || isNoPeopleError) {
      emit(
        state.copyWith(
          isLoading: false,
          status: DeckStatus.empty,
          deck: const [],
          currentIndex: 0,
          errorMessage: null,
          nextRetrySeconds: null,
        ),
      );
      AnalyticsService.instance.logDeckEmpty();
      return;
    }

    // Otherwise show error and schedule retry
    emit(
      state.copyWith(
        isLoading: false,
        status: DeckStatus.error,
        errorMessage: errorMsg,
        nextRetrySeconds: (_retryDelayMs / 1000).ceil(),
      ),
    );
    _scheduleRetry();
  }

  /// Check if error message indicates no people available vs actual error.
  bool _isNoPeopleError(String? errorMsg) {
    if (errorMsg == null) return false;
    final lower = errorMsg.toLowerCase();
    return lower.contains('no people') ||
        lower.contains('no profiles') ||
        lower.contains('no candidates') ||
        lower.contains('no users') ||
        lower.contains('empty') ||
        lower.contains('not found') ||
        lower.contains('no results');
  }

  Future<void> _onSwipedRight(
    DiscoverySwipedRight event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    // Get the profile being swiped on for match celebration
    final swipedProfile = currentIndex < state.deck.length
        ? state.deck[currentIndex]
        : null;

    // Optimistically advance UI
    emit(
      state.copyWith(
        currentIndex: nextIndex,
        status: DeckStatus.ready,
        lastSwipedProfile: swipedProfile,
        lastSwipeDirection: 'right',
        canRewind: true,
        errorMessage: null,
        premiumGateSource: null,
      ),
    );

    // Delegate to use case (handles subscription check, counter, persistence, swipe)
    final result = await swipeRightUseCase.call(
      SwipeRightParams(
        userId: event.userId,
        targetUserId: event.targetUserId,
        attachedMessage: event.attachedMessage,
      ),
    );

    if (result.isSuccess && result.data!.success) {
      final swipeResult = result.data!;

      // Track swipe right
      AnalyticsService.instance.logSwipeRight(
        targetUserId: event.targetUserId,
        withMessage: event.attachedMessage != null,
      );

      // Track match if one was created and emit for celebration
      final match = swipeResult.match;
      if (match != null && swipedProfile != null) {
        AnalyticsService.instance.logMatch(matchId: match.id);
        emit(
          state.copyWith(
            newMatch: MatchResult(
              matchId: match.id,
              matchedProfile: swipedProfile,
            ),
          ),
        );
      }
    } else if (result.isSuccess && !result.data!.success) {
      // Limit reached — rollback UI
      emit(
        state.copyWith(
          currentIndex: currentIndex,
          status: DeckStatus.ready,
          errorMessage:
              result.data?.blockedMessage ?? 'Daily swipe limit reached.',
          canRewind: false,
          lastSwipedProfile: null,
          lastSwipeDirection: null,
          premiumGateSource: result.data?.paywallSource,
        ),
      );
    } else {
      // API failure — rollback UI
      emit(
        state.copyWith(
          currentIndex: currentIndex,
          status: DeckStatus.ready,
          errorMessage: result.errorMessage,
          canRewind: false,
          lastSwipedProfile: null,
          lastSwipeDirection: null,
          premiumGateSource: null,
        ),
      );
    }

    // Preload more profiles if running low
    _maybeLoadMore(event.userId);
  }

  Future<void> _onSwipedLeft(
    DiscoverySwipedLeft event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    // Get the profile being swiped for rewind support
    final swipedProfile = currentIndex < state.deck.length
        ? state.deck[currentIndex]
        : null;

    emit(
      state.copyWith(
        currentIndex: nextIndex,
        status: DeckStatus.ready,
        lastSwipedProfile: swipedProfile,
        lastSwipeDirection: 'left',
        canRewind: true,
        errorMessage: null,
        premiumGateSource: null,
      ),
    );

    final result = await Result.guard(
      () => discoveryRepository.swipeLeft(
        userId: event.userId,
        targetUserId: event.targetUserId,
      ),
      logLabel: 'DiscoveryRepository.swipeLeft',
      fallbackError: 'Could not pass on this profile.',
    );

    if (result.isSuccess) {
      // Track swipe left
      AnalyticsService.instance.logSwipeLeft(targetUserId: event.targetUserId);
    }

    if (!result.isSuccess) {
      emit(
        state.copyWith(
          currentIndex: currentIndex,
          status: DeckStatus.ready,
          errorMessage: result.errorMessage,
          canRewind: false,
          lastSwipedProfile: null,
          lastSwipeDirection: null,
          premiumGateSource: null,
        ),
      );
    }

    // Preload more profiles if running low
    _maybeLoadMore(event.userId);
  }

  /// Handle Super Like - higher priority like with daily limits.
  Future<void> _onSuperLiked(
    DiscoverySuperLiked event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state.deck.isEmpty) return;

    // Check and reset daily super likes if needed
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var superLikesRemaining = state.superLikesRemaining;
    var resetDate = state.superLikesResetDate;

    // Reset super likes if it's a new day
    if (resetDate == null || resetDate.isBefore(today)) {
      // Get subscription to determine daily limit
      final planResult = await Result.guard(
        () => subscriptionRepository.getCurrentPlan(),
        logLabel: 'SubscriptionRepository.getCurrentPlan',
        fallbackError: 'Could not super like. Please try again.',
      );
      final tier = planResult.data ?? SubscriptionTier.free;
      superLikesRemaining = tier.hasPremium
          ? CrushConstants.premiumDailySuperLikes
          : CrushConstants.freeDailySuperLikes;
      resetDate = today;
    }

    // Check if user has super likes remaining
    if (superLikesRemaining <= 0) {
      emit(
        state.copyWith(
          status: DeckStatus.ready,
          errorMessage:
              'No super likes remaining today. Upgrade to Plus for more!',
        ),
      );
      return;
    }

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    // Get the profile being super liked
    final swipedProfile = currentIndex < state.deck.length
        ? state.deck[currentIndex]
        : null;

    // Optimistically update UI
    emit(
      state.copyWith(
        currentIndex: nextIndex,
        status: DeckStatus.ready,
        superLikesRemaining: superLikesRemaining - 1,
        superLikesResetDate: resetDate,
        lastSwipedProfile: swipedProfile,
        lastSwipeDirection: 'superlike',
        canRewind: true,
        errorMessage: null,
      ),
    );

    // Call repository
    final superLikeResult = await Result.guard(
      () => discoveryRepository.superLike(
        userId: event.userId,
        targetUserId: event.targetUserId,
      ),
      logLabel: 'DiscoveryRepository.superLike',
      fallbackError: 'Could not super like. Please try again.',
    );

    if (superLikeResult.isSuccess) {
      // Track super like
      AnalyticsService.instance.logSuperLike(targetUserId: event.targetUserId);

      // Handle match if one occurred
      final match = superLikeResult.data;
      if (match != null && swipedProfile != null) {
        AnalyticsService.instance.logMatch(matchId: match.id);
        emit(
          state.copyWith(
            newMatch: MatchResult(
              matchId: match.id,
              matchedProfile: swipedProfile,
            ),
          ),
        );
      }
    } else {
      // Rollback on error
      emit(
        state.copyWith(
          currentIndex: currentIndex,
          status: DeckStatus.ready,
          superLikesRemaining: superLikesRemaining,
          errorMessage: superLikeResult.errorMessage,
          canRewind: false,
        ),
      );
    }

    // Preload more profiles if running low
    _maybeLoadMore(event.userId);
  }

  /// Handle Rewind - undo last swipe (premium only).
  Future<void> _onRewindRequested(
    DiscoveryRewindRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Check if rewind is available
    if (!state.canRewind || state.lastSwipedProfile == null) {
      emit(
        state.copyWith(
          status: DeckStatus.ready,
          errorMessage: ErrorMessages.noSwipeToUndo,
        ),
      );
      return;
    }

    final entitlementResult = await checkEntitlementUseCase(
      const CheckEntitlementParams(
        feature: SubscriptionEntitlementFeature.rewind,
      ),
    );

    if (!entitlementResult.isSuccess || entitlementResult.data == null) {
      emit(
        state.copyWith(
          status: DeckStatus.ready,
          errorMessage: entitlementResult.errorMessage,
        ),
      );
      return;
    }

    final entitlement = entitlementResult.data!;
    if (!entitlement.isAllowed) {
      emit(
        state.copyWith(
          status: DeckStatus.ready,
          errorMessage: entitlement.blockedMessage,
          premiumGateSource: entitlement.paywallSource,
        ),
      );
      return;
    }

    // Call repository to rewind
    final rewindResult = await Result.guard(
      () => discoveryRepository.rewindLastSwipe(event.userId),
      logLabel: 'DiscoveryRepository.rewindLastSwipe',
      fallbackError: ErrorMessages.rewindFailed,
    );

    if (rewindResult.isSuccess) {
      // Restore the profile to the deck
      final restoredProfile = state.lastSwipedProfile!;
      final newIndex = (state.currentIndex - 1).clamp(0, state.deck.length);

      // If profile was removed from deck, re-insert it (using immutable pattern)
      List<Profile> updatedDeck = state.deck;
      if (newIndex >= state.deck.length ||
          state.deck[newIndex].id != restoredProfile.id) {
        updatedDeck = [
          ...state.deck.sublist(0, newIndex),
          restoredProfile,
          ...state.deck.sublist(newIndex),
        ];
      }

      // Restore super like if that was the last action
      var superLikesRemaining = state.superLikesRemaining;
      if (state.lastSwipeDirection == 'superlike') {
        superLikesRemaining = state.superLikesRemaining + 1;
      }

      emit(
        state.copyWith(
          deck: updatedDeck,
          currentIndex: newIndex,
          status: DeckStatus.ready,
          lastSwipedProfile: null,
          lastSwipeDirection: null,
          canRewind: false,
          superLikesRemaining: superLikesRemaining,
          errorMessage: null,
          premiumGateSource: null,
        ),
      );

      // Track rewind
      AnalyticsService.instance.logRewind();
    } else {
      emit(
        state.copyWith(
          status: DeckStatus.ready,
          errorMessage: rewindResult.errorMessage,
          premiumGateSource: null,
        ),
      );
    }
  }

  /// Load more profiles when approaching end of deck.
  Future<void> _onLoadMoreRequested(
    DiscoveryLoadMoreRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Don't load if already loading or no more profiles
    if (state.isLoadingMore || !state.hasMoreProfiles) return;

    emit(state.copyWith(isLoadingMore: true));

    // Build filter based on current state
    final filter = DiscoveryFilter(
      maxDistanceKm: state.currentDistanceLimitKm > 0
          ? state.currentDistanceLimitKm
          : null,
      passportModeEnabled: state.passportModeActive,
      localDeckExhausted: state.localDeckExhausted,
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
      passportLatitude: _cachedPreferences?.passportLatitude,
      passportLongitude: _cachedPreferences?.passportLongitude,
    );

    final deckResult = await Result.guard(
      () => discoveryRepository.fetchDeck(event.userId, filter: filter),
      logLabel: 'DiscoveryRepository.fetchDeck (pagination)',
      fallbackError: 'Could not load more people.',
    );

    if (!deckResult.isSuccess) {
      emit(state.copyWith(isLoadingMore: false));
      return;
    }

    final newProfiles = deckResult.data ?? const [];

    // Filter out profiles already in the deck
    final existingIds = state.deck.map((p) => p.id).toSet();
    final uniqueNewProfiles = newProfiles
        .where((p) => !existingIds.contains(p.id))
        .toList();

    emit(
      state.copyWith(
        isLoadingMore: false,
        deck: [...state.deck, ...uniqueNewProfiles],
        hasMoreProfiles: uniqueNewProfiles.isNotEmpty,
      ),
    );
  }

  /// Check if we should preload more and trigger loading if needed.
  void _maybeLoadMore(String userId) {
    if (!isClosed && state.shouldLoadMore) {
      add(DiscoveryLoadMoreRequested(userId));
    }
  }

  void _scheduleRetry() {
    final userId = _lastRequestedUserId;
    if (userId == null) return;
    _retryTimer?.cancel();
    final delay = Duration(milliseconds: _retryDelayMs);
    _retryDelayMs = (_retryDelayMs * 2).clamp(1000, 8000);
    _retryTimer = Timer(delay, () {
      if (!isClosed) add(DiscoveryDeckRequested(userId));
    });
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
