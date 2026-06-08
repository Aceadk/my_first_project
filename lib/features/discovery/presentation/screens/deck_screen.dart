import 'dart:async';

import 'package:crushhour/core/routing/premium_cta_helper.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/services/location_service.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/utils/accessibility.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/discovery/presentation/bloc/boost_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_card_stack.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_error_state_view.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_out_of_people_view.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_screen_app_bar.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_skeleton.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_ui_helpers.dart';
import 'package:crushhour/features/discovery/presentation/widgets/explore_grid_view.dart';
import 'package:crushhour/design_system/widgets/match_celebration.dart';
import 'package:crushhour/features/discovery/presentation/widgets/swipeable_card.dart';
import 'package:crushhour/features/discovery/presentation/widgets/welcome_tutorial_overlay.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/presentation/widgets/upsell_widgets.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, this.validationService});

  final ProfileValidationRepository? validationService;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> with WidgetsBindingObserver {
  static const int _previewCount = 4;
  RemoteProfileCompleteness? _backendCompleteness;
  bool _checkingCompleteness = false;
  String? _completenessError;
  String? _lastProfileSignature;
  bool _backendBlocked = false;
  String? _lastBoostUserId;
  int _lastPreloadedIndex =
      -1; // Track last preloaded index to avoid redundant preloads

  // Explore grid mode (tablet/desktop alternative to swipe)
  bool _exploreMode = false;

  // Welcome tutorial overlay state
  bool _showTutorial = false;

  // Location prompt banner state
  bool _showLocationBanner = false;
  Timer? _locationBannerTimer;
  bool _hasCheckedLocation = false;

  // Last deck status announced to screen readers, so the listener does not
  // repeat an announcement when it fires for an unrelated reason.
  DeckStatus? _lastAnnouncedStatus;

  ProfileValidationRepository get _validationService =>
      widget.validationService ?? context.read<ProfileValidationRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _checkTutorialStatus();
  }

  /// Check if the user has already seen the deck tutorial overlay.
  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_deck_tutorial') ?? false;
    if (!hasSeen && mounted) {
      setState(() => _showTutorial = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationBannerTimer?.cancel();
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    // Respond to memory pressure by trimming the image cache
    NetworkImageCache.instance.trimCache(targetEntries: 15);
  }

  /// Check if user has location permission and show banner if not.
  Future<void> _checkLocationPermission() async {
    if (_hasCheckedLocation) return;
    _hasCheckedLocation = true;

    final locationService = LocationService.instance;
    final hasLocation = await locationService.isLocationAvailable();

    if (!hasLocation && mounted) {
      setState(() => _showLocationBanner = true);

      // Auto-dismiss after 2 seconds
      _locationBannerTimer?.cancel();
      _locationBannerTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showLocationBanner = false);
        }
      });
    }
  }

  /// Request location permission when user taps the banner.
  Future<void> _requestLocationPermission() async {
    final locationService = LocationService.instance;
    final granted = await locationService.requestPermission();

    if (granted && mounted) {
      setState(() => _showLocationBanner = false);

      // Update user's location
      final location = await locationService.getCurrentLocation(
        includeGeocoding: true,
        timeout: const Duration(seconds: 15),
      );

      if (location != null && mounted) {
        context.read<ProfileBloc>().add(
          ProfileLocationUpdateRequested(
            latitude: location.latitude,
            longitude: location.longitude,
            city: location.city,
            country: location.country,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize boost cubit when user ID is available (moved from build to avoid side effects)
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null && userId != _lastBoostUserId) {
      _lastBoostUserId = userId;
      context.read<BoostCubit>().initialize(userId);
    }
  }

  /// Preload images for the next few profiles in the deck for smoother transitions.
  /// Uses priority-based preloading to optimize memory and network usage.
  void _preloadUpcomingProfiles(List<Profile> deck, int currentIndex) {
    if (currentIndex == _lastPreloadedIndex) return;
    _lastPreloadedIndex = currentIndex;

    // Mark current profile's photos as priority (don't evict them first)
    if (currentIndex < deck.length) {
      final currentProfile = deck[currentIndex];
      if (currentProfile.photoUrls.isNotEmpty) {
        NetworkImageCache.instance.markAsPriority([
          currentProfile.photoUrls.first,
        ]);
      }
    }

    // Collect URLs by priority
    String? immediateUrl;
    final highPriorityUrls = <String>[];
    final lowPriorityUrls = <String>[];

    // Current card's first photo - immediate priority
    if (currentIndex < deck.length && deck[currentIndex].photoUrls.isNotEmpty) {
      immediateUrl = deck[currentIndex].photoUrls.first;
    }

    // Next 2 profiles - high priority (most likely to be seen soon)
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < deck.length && deck[nextIndex].photoUrls.isNotEmpty) {
        highPriorityUrls.add(deck[nextIndex].photoUrls.first);
      }
    }

    // Preview stack profiles (3-4) - low priority
    for (int i = 3; i <= _previewCount; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < deck.length && deck[nextIndex].photoUrls.isNotEmpty) {
        lowPriorityUrls.add(deck[nextIndex].photoUrls.first);
      }
    }

    // Use priority-based preloading - immediate loads first, then high, then low
    NetworkImageCache.instance.preloadWithPriority(
      immediateUrls: immediateUrl != null ? [immediateUrl] : null,
      highUrls: highPriorityUrls.isNotEmpty ? highPriorityUrls : null,
      lowUrls: lowPriorityUrls.isNotEmpty ? lowPriorityUrls : null,
    );
  }

  List<Profile> _buildUpcomingProfiles(List<Profile> deck, int currentIndex) {
    if (deck.isEmpty) return [];
    final start = currentIndex + 1;
    final end = (currentIndex + 1 + _previewCount).clamp(0, deck.length);
    if (start >= deck.length) return [];
    return deck.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, dynamic>((bloc) => bloc.state.user);
    final userId = user?.id as String?;
    final isAccountVerified = user?.isAccountVerified ?? false;

    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.newMatch != current.newMatch ||
          previous.premiumGateSource != current.premiumGateSource ||
          previous.status != current.status,
      listener: (context, state) {
        // Announce deck state transitions to screen readers. The deck swaps
        // whole views (loading → ready/empty/error) without any visible text
        // change a screen reader would otherwise pick up, so surface the change
        // explicitly. Errors already raise an (auto-announced) snackbar below,
        // so they are intentionally not re-announced here.
        _announceDeckStatus(context, state.status);

        final premiumGateSource = state.premiumGateSource;
        if (premiumGateSource != null) {
          context.read<DiscoveryBloc>().add(DiscoveryPremiumGateHandled());
          PremiumCtaHelper.showPaywall(context, source: premiumGateSource);
          return;
        }
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        }
        // Show match celebration when a new match occurs
        final newMatch = state.newMatch;
        if (newMatch != null) {
          // Clear the match state immediately to prevent showing twice
          context.read<DiscoveryBloc>().add(DiscoveryMatchCelebrationShown());

          // Get current user's photo for the celebration modal
          final currentProfile = context.read<ProfileBloc>().state.profile;
          final currentUserPhotoUrl =
              currentProfile?.photoUrls.isNotEmpty == true
              ? currentProfile!.photoUrls.first
              : null;

          // Show the celebration modal
          MatchCelebration.show(
            context: context,
            matchName: newMatch.matchedProfile.name,
            matchImageUrl: newMatch.matchedProfile.photoUrls.isNotEmpty
                ? newMatch.matchedProfile.photoUrls.first
                : '',
            yourImageUrl: currentUserPhotoUrl ?? '',
            onKeepSwiping: () {
              // Just close the modal - state already cleared
            },
            onSendMessage: () {
              // Navigate to chat
              final matchedProfile = newMatch.matchedProfile;
              context.push(
                '${CrushRoutes.chat}/${newMatch.matchId}',
                extra: ChatScreenArgs(
                  matchId: newMatch.matchId,
                  currentUserId: userId ?? '',
                  otherUserId: matchedProfile.id,
                  otherName: matchedProfile.publicDisplayName,
                  otherPhotoUrl: matchedProfile.photoUrls.isNotEmpty
                      ? matchedProfile.photoUrls.first
                      : null,
                ),
              );
            },
          );
        }
      },
      builder: (context, state) {
        _requestDeckIfNeeded(context, userId, state);

        final profile = context.select<ProfileBloc, Profile?>(
          (b) => b.state.profile ?? b.state.user?.profile,
        );
        final completeness = evaluateProfileCompleteness(profile);
        _maybeRefreshBackendCompleteness(profile);

        final locationLabel = _locationLabel(profile);
        final radiusKm = profile?.preferences.maxDistanceKm;
        final isPremium = context.select<SubscriptionBloc, bool>(
          (b) => b.state.tier.hasPremium,
        );
        final status = state.status;
        final retryInSeconds = state.nextRetrySeconds;
        final isLoading = status == DeckStatus.loading;

        // Filter out users who should be hidden (blocked or reported within 10 days)
        final safety = context.read<SafetyCubit>();
        final filteredDeck = state.deck
            .where((p) => !safety.shouldHideFromFeed(p.id))
            .toList();

        final isEmptyDeck =
            status == DeckStatus.empty ||
            filteredDeck.isEmpty ||
            state.currentIndex >= filteredDeck.length;

        final currentProfile = isEmptyDeck
            ? null
            : filteredDeck[state.currentIndex.clamp(
                0,
                filteredDeck.length - 1,
              )];
        final upcomingProfiles = isEmptyDeck
            ? const <Profile>[]
            : _buildUpcomingProfiles(filteredDeck, state.currentIndex);

        // Preload images for upcoming profiles
        if (!isEmptyDeck && filteredDeck.isNotEmpty) {
          _preloadUpcomingProfiles(filteredDeck, state.currentIndex);
        }

        final backendSwipeReady =
            _backendCompleteness?.allowsSwipe ??
            (_backendBlocked ? false : _completenessError != null);
        final refreshDeck = userId == null
            ? null
            : () => context.read<DiscoveryBloc>().add(
                DiscoveryDeckRequested(userId),
              );
        final appBar = DeckScreenAppBar(
          exploreMode: _exploreMode,
          onToggleExploreMode: () =>
              setState(() => _exploreMode = !_exploreMode),
        );

        return AsyncStateScaffold(
          appBar: appBar,
          extendBodyBehindAppBar: true,
          isLoading: isLoading && state.deck.isEmpty,
          errorMessage: status == DeckStatus.error ? state.errorMessage : null,
          error: status == DeckStatus.error && state.deck.isEmpty
              ? DeckErrorStateView(
                  appBar: appBar,
                  retryInSeconds: retryInSeconds,
                  isPlus: isPremium,
                  locationLabel: locationLabel,
                  radiusKm: radiusKm,
                  onRetry: refreshDeck,
                  onShowPassportUpsell: () => _showPassportUpsell(context),
                )
              : null,
          empty: isEmptyDeck
              ? DeckOutOfPeopleView(
                  discoveryState: state,
                  isPlus: isPremium,
                  locationLabel: locationLabel,
                  onRefresh: refreshDeck,
                  onShowPassportUpsell: () => _showPassportUpsell(context),
                )
              : null,
          showErrorSnackBar: true,
          showBodyOnLoading: true,
          body: currentProfile == null
              ? (isLoading && state.deck.isEmpty
                    ? const DeckSkeletonList()
                    : const SizedBox.shrink())
              : _exploreMode &&
                    !DsBreakpoints.isMobile(MediaQuery.sizeOf(context).width)
              ? ExploreGridView(
                  profiles: filteredDeck.sublist(
                    state.currentIndex.clamp(0, filteredDeck.length),
                  ),
                  isLoading: isLoading,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cardMaxWidth = DsBreakpoints.responsiveValue<double>(
                      constraints.maxWidth,
                      mobile: double.infinity,
                      tablet: 500,
                      desktop: 500,
                    );
                    return Center(
                      child: Focus(
                        autofocus: true,
                        onKeyEvent: (node, event) {
                          if (event is! KeyDownEvent) {
                            return KeyEventResult.ignored;
                          }
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowLeft) {
                            // ← Pass
                            _handleKeyboardPass(
                              context,
                              userId,
                              currentProfile,
                              completeness,
                              backendSwipeReady,
                              isAccountVerified,
                            );
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowRight) {
                            // → Like
                            _handleKeyboardLike(
                              context,
                              userId,
                              currentProfile,
                              completeness,
                              backendSwipeReady,
                              isAccountVerified,
                            );
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowUp) {
                            // ↑ Super Like
                            _handleKeyboardSuperLike(
                              context,
                              userId,
                              currentProfile,
                              state,
                              completeness,
                              backendSwipeReady,
                              isAccountVerified,
                            );
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                              LogicalKeyboardKey.arrowDown) {
                            // ↓ Rewind
                            _handleKeyboardRewind(context, userId, state);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Full-screen immersive card - edge to edge
                              Positioned.fill(
                                child: DeckPreviewStack(
                                  currentProfile: currentProfile,
                                  upcomingProfiles: upcomingProfiles,
                                  child: SwipeableCard(
                                    profile: currentProfile,
                                    superLikeEnabled:
                                        state.superLikesRemaining > 0,
                                    onTap: () => context.push(
                                      CrushRoutes.userProfile,
                                      extra: OtherUserProfileArgs(
                                        profile: currentProfile,
                                      ),
                                    ),
                                    onSwipeLeft: () => _performSwipe(
                                      context,
                                      action: _SwipeAction.pass,
                                      userId: userId,
                                      target: currentProfile,
                                      completeness: completeness,
                                      backendSwipeReady: backendSwipeReady,
                                      isAccountVerified: isAccountVerified,
                                    ),
                                    onSwipeRight: () => _performSwipe(
                                      context,
                                      action: _SwipeAction.like,
                                      userId: userId,
                                      target: currentProfile,
                                      completeness: completeness,
                                      backendSwipeReady: backendSwipeReady,
                                      isAccountVerified: isAccountVerified,
                                    ),
                                    onSwipeUp: () => _performSwipe(
                                      context,
                                      action: _SwipeAction.superLike,
                                      userId: userId,
                                      target: currentProfile,
                                      completeness: completeness,
                                      backendSwipeReady: backendSwipeReady,
                                      isAccountVerified: isAccountVerified,
                                      superLikesRemaining:
                                          state.superLikesRemaining,
                                    ),
                                  ),
                                ),
                              ),

                              // Safety menu overlay (top-right of card)
                              PositionedDirectional(
                                top: DsSpacing.md,
                                end: DsSpacing.md,
                                child: PopupMenuButton<_DeckSafetyAction>(
                                  tooltip: 'Safety tools',
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: DsColors.ink900.withValues(
                                        alpha: 0.4,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.more_vert,
                                      color: DsColors.surfaceLight,
                                      size: 20,
                                    ),
                                  ),
                                  onSelected: (action) => _handleSafetyAction(
                                    context,
                                    action,
                                    currentProfile: currentProfile,
                                    currentUserId: userId,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: _DeckSafetyAction.viewProfile,
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).viewFullProfile,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _DeckSafetyAction.report,
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).reportProfile,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _DeckSafetyAction.block,
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).blockHideProfile,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status indicators overlay (top-left) - only show when relevant
                              if (isLoading ||
                                  retryInSeconds != null ||
                                  completeness.score < 0.5 ||
                                  state.localDeckExhausted ||
                                  state.passportModeActive ||
                                  _checkingCompleteness ||
                                  _completenessError != null)
                                PositionedDirectional(
                                  top: DsSpacing.md,
                                  start: DsSpacing.md,
                                  end: 60, // Leave space for safety menu
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isLoading ||
                                          retryInSeconds != null ||
                                          completeness.score < 0.5)
                                        DeckStatusBar(
                                          isLoading: isLoading,
                                          retryInSeconds: retryInSeconds,
                                          completeness: completeness,
                                        ),
                                      if (state.localDeckExhausted ||
                                          state.passportModeActive)
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                top: DsSpacing.xs,
                                              ),
                                          child: DeckSearchModeIndicator(
                                            localDeckExhausted:
                                                state.localDeckExhausted,
                                            passportModeActive:
                                                state.passportModeActive,
                                            currentDistanceKm:
                                                state.currentDistanceLimitKm,
                                            onTapPassport: () => context.push(
                                              CrushRoutes.discoverySettings,
                                            ),
                                          ),
                                        ),
                                      if (_checkingCompleteness)
                                        Container(
                                          margin:
                                              const EdgeInsetsDirectional.only(
                                                top: DsSpacing.xs,
                                              ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: DsColors.ink900.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              DsRadius.sm,
                                            ),
                                          ),
                                          child: Text(
                                            'Checking profile...',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: DsColors.surfaceLight
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                        ),
                                      if (_completenessError != null)
                                        Container(
                                          margin:
                                              const EdgeInsetsDirectional.only(
                                                top: DsSpacing.xs,
                                              ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: DsColors.warning.withValues(
                                              alpha: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              DsRadius.sm,
                                            ),
                                          ),
                                          child: Text(
                                            _completenessError!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: DsColors.surfaceLight,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              // Location permission banner (auto-dismisses after 2 seconds)
                              if (_showLocationBanner)
                                PositionedDirectional(
                                  top: DsSpacing.md,
                                  start: DsSpacing.md,
                                  end: DsSpacing.md,
                                  child: Semantics(
                                    button: true,
                                    child: GestureDetector(
                                      onTap: _requestLocationPermission,
                                      child: AnimatedOpacity(
                                        opacity: _showLocationBanner
                                            ? 1.0
                                            : 0.0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: DsSpacing.md,
                                            vertical: DsSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: DsColors.primary.withValues(
                                              alpha: 0.9,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              DsRadius.md,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: DsColors.ink900
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: DsColors.surfaceLight,
                                                size: 20,
                                              ),
                                              const SizedBox(
                                                width: DsSpacing.sm,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Enable location for better matches nearby',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: DsColors
                                                            .surfaceLight,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: DsSpacing.sm,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: DsSpacing.sm,
                                                      vertical: DsSpacing.xs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: DsColors.surfaceLight
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        DsRadius.sm,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Enable',
                                                  style: TextStyle(
                                                    color:
                                                        DsColors.surfaceLight,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Floating action buttons on the right side - vertical layout.
                              // Wrapped in a scroll view so the column never
                              // clips on short viewports (small landscape /
                              // split-screen); it stays centred when there is
                              // room and becomes scrollable when there is not.
                              PositionedDirectional(
                                end: DsSpacing.md,
                                top: 0,
                                bottom: 0,
                                child: LayoutBuilder(
                                  builder: (context, actionConstraints) {
                                    return SingleChildScrollView(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: actionConstraints.maxHeight,
                                        ),
                                        child: IntrinsicHeight(
                                          child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Rewind button (premium only)
                                      DeckActionButton(
                                        icon: Icons.replay,
                                        color: DsColors.actionRewind,
                                        semanticLabel: 'Undo last swipe',
                                        semanticHint: 'Same as swiping down',
                                        size: 44,
                                        enabled: state.canRewind,
                                        onTap: () async {
                                          if (userId == null) return;
                                          final discoveryBloc = context
                                              .read<DiscoveryBloc>();
                                          discoveryBloc.add(
                                            DiscoveryRewindRequested(userId),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: DsSpacing.md),
                                      // Dislike button
                                      DeckActionButton(
                                        icon: Icons.close_rounded,
                                        color: DsColors.actionPass,
                                        semanticLabel: 'Pass on this profile',
                                        semanticHint: 'Same as swiping left',
                                        size: 52,
                                        onTap: () => _performSwipe(
                                          context,
                                          action: _SwipeAction.pass,
                                          userId: userId,
                                          target: currentProfile,
                                          completeness: completeness,
                                          backendSwipeReady: backendSwipeReady,
                                          isAccountVerified: isAccountVerified,
                                        ),
                                      ),
                                      const SizedBox(height: DsSpacing.md),
                                      // Super Like button (with remaining count badge)
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          DeckActionButton(
                                            icon: Icons.star_rounded,
                                            color: DsColors.actionSuperLike,
                                            semanticLabel:
                                                'Super like this profile',
                                            semanticHint: 'Same as swiping up',
                                            size: 48,
                                            enabled:
                                                state.superLikesRemaining > 0,
                                            onTap: () => _performSwipe(
                                              context,
                                              action: _SwipeAction.superLike,
                                              userId: userId,
                                              target: currentProfile,
                                              completeness: completeness,
                                              backendSwipeReady:
                                                  backendSwipeReady,
                                              isAccountVerified:
                                                  isAccountVerified,
                                              superLikesRemaining:
                                                  state.superLikesRemaining,
                                            ),
                                          ),
                                          // Badge showing remaining super likes
                                          PositionedDirectional(
                                            top: -4,
                                            end: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color:
                                                    state.superLikesRemaining >
                                                        0
                                                    ? DsColors.actionSuperLike
                                                    : DsColors.ink300,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: DsColors.ink900
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                '${state.superLikesRemaining}',
                                                style: const TextStyle(
                                                  color: DsColors.surfaceLight,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: DsSpacing.md),
                                      // Like button
                                      DeckActionButton(
                                        icon: Icons.favorite_rounded,
                                        color: DsColors.actionLike,
                                        semanticLabel: 'Like this profile',
                                        semanticHint: 'Same as swiping right',
                                        size: 52,
                                        onTap: () => _performSwipe(
                                          context,
                                          action: _SwipeAction.like,
                                          userId: userId,
                                          target: currentProfile,
                                          completeness: completeness,
                                          backendSwipeReady: backendSwipeReady,
                                          isAccountVerified: isAccountVerified,
                                        ),
                                      ),
                                    ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Welcome tutorial overlay (shown once after onboarding)
                              if (_showTutorial)
                                WelcomeTutorialOverlay(
                                  onDismiss: () {
                                    setState(() => _showTutorial = false);
                                    SharedPreferences.getInstance().then((
                                      prefs,
                                    ) {
                                      prefs.setBool(
                                        'has_seen_deck_tutorial',
                                        true,
                                      );
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  /// Announces a deck status change to assistive technologies, de-duplicating
  /// against the last status announced. Loading/initial are silent (transient);
  /// errors are conveyed by the auto-announced error snackbar instead.
  void _announceDeckStatus(BuildContext context, DeckStatus status) {
    if (status == _lastAnnouncedStatus) return;
    _lastAnnouncedStatus = status;
    switch (status) {
      case DeckStatus.ready:
        DsAccessibility.announce(context, 'Profiles ready');
      case DeckStatus.empty:
        DsAccessibility.announce(context, 'No more profiles nearby');
      case DeckStatus.loading:
      case DeckStatus.initial:
      case DeckStatus.error:
        break;
    }
  }

  void _requestDeckIfNeeded(
    BuildContext context,
    String? userId,
    DiscoveryState state,
  ) {
    if (userId == null) return;
    if (state.isLoading) return;
    if (state.deck.isNotEmpty) return;
    if (state.status == DeckStatus.empty) return;
    // Don't auto-request on error - bloc handles retries with limits
    if (state.status == DeckStatus.error) return;
    context.read<DiscoveryBloc>().add(DiscoveryDeckRequested(userId));
  }

  void _maybeRefreshBackendCompleteness(Profile? profile) {
    final signature = _profileSignature(profile);
    if (_lastProfileSignature == signature) return;
    _lastProfileSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _backendCompleteness = null;
          _completenessError = null;
          _backendBlocked = false;
        });
        return;
      }
      _refreshBackendCompleteness();
    });
  }

  String _profileSignature(Profile? profile) {
    if (profile == null) return 'none';
    return [
      profile.id,
      profile.photoUrls.length,
      profile.profilePrompts.length,
      profile.bio.hashCode,
      profile.interests.length,
      profile.isVerified,
    ].join('|');
  }

  Future<void> _refreshBackendCompleteness({
    String minimum = 'messaging',
  }) async {
    // Single setState at start
    setState(() {
      _checkingCompleteness = true;
      _completenessError = null;
    });

    RemoteProfileCompleteness? result;
    String? error;

    try {
      result = await _validationService.validate(minimum: minimum);
    } catch (e) {
      error = _friendlyError(e);
    }

    // Single setState at end with all updates
    if (mounted) {
      setState(() {
        _checkingCompleteness = false;
        if (error != null) {
          _backendCompleteness = null;
          _completenessError = error;
          _backendBlocked = false;
        } else {
          _backendCompleteness = result;
          _completenessError = null;
          _backendBlocked = false;
        }
      });
    }
  }

  Future<_BackendCheckOutcome> _evaluateBackendAllowance({
    required String minimum,
    required ProfileCompletenessSummary local,
    required bool isAccountVerified,
  }) async {
    // First check local requirements - fast path
    if (minimum == 'swipe' &&
        !_canSwipe(local, true, isAccountVerified: isAccountVerified)) {
      return const _BackendCheckOutcome(allowed: false, blocked: true);
    }

    // If local checks pass and we already have backend result, use it
    final backend = _backendCompleteness;
    if (backend != null) {
      final allowed = minimum == 'messaging'
          ? backend.allowsMessaging
          : backend.allowsSwipe;
      return _BackendCheckOutcome(
        allowed: allowed,
        remote: backend,
        blocked: !allowed,
      );
    }

    // If local checks pass but no backend result yet, allow the action
    // and trigger a non-blocking backend refresh for future swipes
    if (local.meetsSwipeMinimum && local.meetsRequiredFields) {
      // Trigger backend refresh in background (don't await)
      if (!_checkingCompleteness) {
        _refreshBackendCompleteness(minimum: minimum);
      }
      // Allow swipe based on local checks - don't block the user
      return const _BackendCheckOutcome(allowed: true);
    }

    // Local checks failed and no backend - block the user
    if (_backendBlocked) {
      return _BackendCheckOutcome(
        allowed: false,
        blocked: true,
        message: _completenessError,
      );
    }
    if (_completenessError != null) {
      return const _BackendCheckOutcome(
        allowed: true,
        message:
            'Could not verify profile completeness with the server. Using local checks.',
      );
    }
    if (_checkingCompleteness) {
      // Still checking - allow based on local since local passed above
      return const _BackendCheckOutcome(allowed: true);
    }
    return const _BackendCheckOutcome(allowed: false);
  }

  bool _handleBackendOutcome(
    BuildContext context,
    _BackendCheckOutcome outcome, {
    required String minimum,
    required ProfileCompletenessSummary completeness,
    required bool isAccountVerified,
  }) {
    if (!outcome.allowed) {
      if (outcome.blocked) {
        _showProfileIncompleteDialog(
          context,
          completeness,
          remote: outcome.remote ?? _backendCompleteness,
          minimum: minimum,
          isAccountVerified: isAccountVerified,
        );
      }
      if (outcome.message != null) {
        showErrorSnackBar(context, outcome.message!);
      }
      return false;
    }
    if (outcome.message != null) {
      showErrorSnackBar(context, outcome.message!);
    }
    return true;
  }

  List<String> _missingMessages(
    ProfileCompletenessSummary local,
    RemoteProfileCompleteness? remote, {
    required String minimum,
  }) {
    final remoteMissing = minimum == 'messaging'
        ? remote?.missingForMessaging
        : remote?.missingForSwipe;
    if (remoteMissing != null && remoteMissing.isNotEmpty) {
      return remoteMissing;
    }
    if (local.requiredMissing.isNotEmpty) return local.requiredMissing;
    return local.missing;
  }

  bool _canSwipe(
    ProfileCompletenessSummary local,
    bool backendAllowed, {
    required bool isAccountVerified,
  }) {
    // User must have EITHER email OR phone verified to swipe
    if (!isAccountVerified) return false;
    return local.meetsSwipeMinimum &&
        local.meetsRequiredFields &&
        backendAllowed;
  }

  String _friendlyError(Object error) {
    if (error is Exception) {
      return error.toString();
    }
    return 'Could not verify profile completeness. Check your connection.';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED SWIPE ACTION PIPELINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Runs the shared gating pipeline for a like / pass / super-like and, when
  /// permitted, dispatches the matching [DiscoveryBloc] event.
  ///
  /// This is the single source of truth behind every way a user can act on the
  /// current profile — drag gestures ([SwipeableCard]), the on-screen
  /// [DeckActionButton]s, and keyboard shortcuts — so the completeness checks,
  /// the backend allowance round-trip, and the dispatched events stay identical
  /// across all of them (DISC-UI-003). Previously this logic was copy-pasted at
  /// nine call sites.
  ///
  /// [announceBlock] mirrors the previous per-entry-point behaviour: the
  /// gesture and button paths surface the "complete your profile" dialog when a
  /// completeness check fails, whereas the keyboard path returns silently.
  /// [superLikesRemaining] is only consulted for [_SwipeAction.superLike].
  Future<void> _performSwipe(
    BuildContext context, {
    required _SwipeAction action,
    required String? userId,
    required Profile target,
    required ProfileCompletenessSummary completeness,
    required bool backendSwipeReady,
    required bool isAccountVerified,
    int superLikesRemaining = 1,
    bool announceBlock = true,
  }) async {
    if (userId == null) return;
    if (action == _SwipeAction.superLike && superLikesRemaining <= 0) return;

    // Capture the bloc before any await so we never touch a stale context.
    final discoveryBloc = context.read<DiscoveryBloc>();

    if (!_canSwipe(
      completeness,
      backendSwipeReady,
      isAccountVerified: isAccountVerified,
    )) {
      if (announceBlock) {
        _showProfileIncompleteDialog(
          context,
          completeness,
          remote: _backendCompleteness,
          minimum: 'swipe',
          isAccountVerified: isAccountVerified,
        );
      }
      return;
    }

    final outcome = await _evaluateBackendAllowance(
      minimum: 'swipe',
      local: completeness,
      isAccountVerified: isAccountVerified,
    );
    if (!context.mounted) return;
    final allowed = _handleBackendOutcome(
      context,
      outcome,
      minimum: 'swipe',
      completeness: completeness,
      isAccountVerified: isAccountVerified,
    );
    if (!allowed) return;

    switch (action) {
      case _SwipeAction.pass:
        discoveryBloc.add(
          DiscoverySwipedLeft(userId: userId, targetUserId: target.id),
        );
      case _SwipeAction.like:
        discoveryBloc.add(
          DiscoverySwipedRight(userId: userId, targetUserId: target.id),
        );
      case _SwipeAction.superLike:
        discoveryBloc.add(
          DiscoverySuperLiked(userId: userId, targetUserId: target.id),
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYBOARD SHORTCUT HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleKeyboardPass(
    BuildContext context,
    String? userId,
    Profile target,
    ProfileCompletenessSummary completeness,
    bool backendSwipeReady,
    bool isAccountVerified,
  ) {
    // Keyboard path stays silent on an incomplete profile (announceBlock:
    // false) instead of surfacing the completeness dialog.
    return _performSwipe(
      context,
      action: _SwipeAction.pass,
      userId: userId,
      target: target,
      completeness: completeness,
      backendSwipeReady: backendSwipeReady,
      isAccountVerified: isAccountVerified,
      announceBlock: false,
    );
  }

  Future<void> _handleKeyboardLike(
    BuildContext context,
    String? userId,
    Profile target,
    ProfileCompletenessSummary completeness,
    bool backendSwipeReady,
    bool isAccountVerified,
  ) {
    return _performSwipe(
      context,
      action: _SwipeAction.like,
      userId: userId,
      target: target,
      completeness: completeness,
      backendSwipeReady: backendSwipeReady,
      isAccountVerified: isAccountVerified,
      announceBlock: false,
    );
  }

  Future<void> _handleKeyboardSuperLike(
    BuildContext context,
    String? userId,
    Profile target,
    DiscoveryState state,
    ProfileCompletenessSummary completeness,
    bool backendSwipeReady,
    bool isAccountVerified,
  ) {
    return _performSwipe(
      context,
      action: _SwipeAction.superLike,
      userId: userId,
      target: target,
      completeness: completeness,
      backendSwipeReady: backendSwipeReady,
      isAccountVerified: isAccountVerified,
      superLikesRemaining: state.superLikesRemaining,
      announceBlock: false,
    );
  }

  void _handleKeyboardRewind(
    BuildContext context,
    String? userId,
    DiscoveryState state,
  ) {
    if (userId == null || !state.canRewind) return;
    context.read<DiscoveryBloc>().add(DiscoveryRewindRequested(userId));
  }

  void _showProfileIncompleteDialog(
    BuildContext context,
    ProfileCompletenessSummary completeness, {
    RemoteProfileCompleteness? remote,
    String minimum = 'swipe',
    bool isAccountVerified = true,
  }) {
    final percent = ((remote?.score ?? completeness.score) * 100).round();
    final missingList = _missingMessages(
      completeness,
      remote,
      minimum: minimum,
    );
    final missing = missingList.take(3).join('\n• ');

    // Check if account verification is the issue
    if (!isAccountVerified) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context).verifyYourAccount),
          content: Text(AppLocalizations.of(context).pleaseVerifyYourEmailOr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).later),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(CrushRoutes.emailProtection);
              },
              child: Text(AppLocalizations.of(context).verifyNow),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).completeYourProfile),
        content: Text(
          percent >= 100
              ? 'Your profile looks good.'
              : 'Your profile is $percent% complete. Add these to unlock swiping and messaging:\n\n• ${missing.isEmpty ? 'Add photos and a longer bio' : missing}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).later),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToProfileEdit(context);
            },
            child: Text(AppLocalizations.of(context).completeProfile),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSafetyAction(
    BuildContext context,
    _DeckSafetyAction action, {
    required Profile currentProfile,
    required String? currentUserId,
  }) async {
    final safety = context.read<SafetyCubit>();
    final currentProfileId = currentProfile.id;
    final currentProfileName = currentProfile.publicDisplayName;
    switch (action) {
      case _DeckSafetyAction.viewProfile:
        context.push(
          CrushRoutes.userProfile,
          extra: OtherUserProfileArgs(profile: currentProfile),
        );
        break;
      case _DeckSafetyAction.report:
        await _showReportSheet(
          context,
          safety,
          reportedId: currentProfileId,
          reportedName: currentProfileName,
          currentUserId: currentUserId,
        );
        break;
      case _DeckSafetyAction.block:
        if (currentUserId == null) {
          showErrorSnackBar(context, 'Sign in again to block profiles.');
          return;
        }
        await safety.toggleBlock(
          currentProfileId,
          block: true,
          currentUserId: currentUserId,
        );
        if (!context.mounted) return;
        final error = safety.state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Blocked $currentProfileName and hidden from deck.',
              ),
            ),
          );
        }
        break;
      case _DeckSafetyAction.guidelines:
        context.push(CrushRoutes.safetyGuidelines);
        break;
    }
  }

  void _goToProfileEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }

  void _showPassportUpsell(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
            buildWhen: (previous, current) =>
                previous.tier != current.tier ||
                previous.isCheckoutInProgress != current.isCheckoutInProgress,
            builder: (context, subState) {
              final isPlus = subState.tier.hasPremium;
              final loading = subState.isCheckoutInProgress;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff),
                        DsGap.smH,
                        Text(
                          isPlus ? 'Passport available' : 'Passport with Plus',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const IntroBadge(),
                      ],
                    ),
                    DsGap.sm,
                    Text(
                      isPlus
                          ? 'Change your location and explore anywhere.'
                          : 'Intro offer: 50% off your first month. Explore any city, see likes, and keep swiping with unlimited likes.',
                    ),
                    DsGap.md,
                    const UpsellBullets(
                      items: [
                        'Passport to any city',
                        'See who likes you first',
                        'Unlimited likes & Passport',
                      ],
                    ),
                    DsGap.lg,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                if (!isPlus) {
                                  sheetContext.read<SubscriptionBloc>().add(
                                    SubscriptionCheckoutRequested(
                                      SubscriptionTier.plus,
                                      BillingPeriod.monthly,
                                    ),
                                  );
                                }
                              },
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    DsColors.surfaceLight,
                                  ),
                                ),
                              )
                            : Text(isPlus ? 'Got it' : 'Upgrade to Plus'),
                      ),
                    ),
                    if (!isPlus)
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(AppLocalizations.of(context).maybeLater1),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showReportSheet(
    BuildContext context,
    SafetyCubit safety, {
    required String reportedId,
    required String reportedName,
    required String? currentUserId,
  }) async {
    if (currentUserId == null) {
      showErrorSnackBar(context, 'Sign in again to report this profile.');
      return;
    }

    const reasons = [
      'Spam or scams',
      'Harassment or hate',
      'Inappropriate content',
      'Fake profile',
      'Other',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Report $reportedName'),
                subtitle: Text(AppLocalizations.of(context).weWillReviewAndMay),
              ),
              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  onTap: () => Navigator.pop(sheetContext, reason),
                ),
              ),
              DsGap.sm,
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (selected == null) return;

    if (selected == 'Other') {
      final controller = TextEditingController();
      final custom = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Report $reportedName'),
            content: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe what happened',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text.trim()),
                child: Text(AppLocalizations.of(context).submit),
              ),
            ],
          );
        },
      );
      if (custom == null || custom.isEmpty) return;
      await safety.reportWithContext(
        reporterId: currentUserId,
        reportedId: reportedId,
        reason: custom,
      );
    } else {
      await safety.reportWithContext(
        reporterId: currentUserId,
        reportedId: reportedId,
        reason: selected,
      );
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = safety.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      showErrorSnackBar(context, error);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Report submitted for $reportedName.')),
      );
    }
  }

  String? _locationLabel(Profile? profile) {
    final city = profile?.city.trim();
    final country = profile?.country.trim();
    if (city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty &&
        country.toLowerCase() != 'unknown') {
      return '$city, $country';
    }
    if (city != null && city.isNotEmpty) return city;
    if (country != null &&
        country.isNotEmpty &&
        country.toLowerCase() != 'unknown') {
      return country;
    }
    return null;
  }
}

class _BackendCheckOutcome {
  const _BackendCheckOutcome({
    required this.allowed,
    this.remote,
    this.message,
    this.blocked = false,
  });

  final bool allowed;
  final RemoteProfileCompleteness? remote;
  final String? message;
  final bool blocked;
}

enum _DeckSafetyAction { viewProfile, report, block, guidelines }

/// A non-gesture discovery action that can be triggered from the swipe gesture
/// callbacks, the on-screen action buttons, or the keyboard shortcuts. Routed
/// through [_DeckScreenState._performSwipe].
enum _SwipeAction { pass, like, superLike }
