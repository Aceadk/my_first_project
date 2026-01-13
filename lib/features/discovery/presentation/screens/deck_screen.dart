import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:crushhour/shared/utils/profanity_filter.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/services/prematch_service.dart';
import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/presentation/widgets/async_state_scaffold.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_skeleton.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_ui_helpers.dart';
import 'package:crushhour/features/discovery/presentation/widgets/swipeable_card.dart';
import 'package:crushhour/presentation/widgets/upsell_widgets.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/discovery/presentation/widgets/match_celebration_modal.dart';
import 'package:crushhour/features/discovery/presentation/widgets/boost_button.dart';
import 'package:crushhour/features/discovery/presentation/bloc/boost_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, this.preMatchService, this.validationService});

  final PreMatchService? preMatchService;
  final ProfileValidationService? validationService;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  RemoteProfileCompleteness? _backendCompleteness;
  bool _checkingCompleteness = false;
  String? _completenessError;
  String? _lastProfileSignature;
  bool _backendBlocked = false;
  String? _lastBoostUserId;

  ProfileValidationService get _validationService =>
      widget.validationService ?? ProfileValidationService();

  @override
  Widget build(BuildContext context) {
    final preMatchService = widget.preMatchService;
    final user = context.select<AuthBloc, dynamic>(
      (bloc) => bloc.state.user,
    );
    final userId = user?.id as String?;
    final isAccountVerified = user?.isAccountVerified ?? false;

    // Initialize boost cubit when user ID is available
    if (userId != null && userId != _lastBoostUserId) {
      _lastBoostUserId = userId;
      context.read<BoostCubit>().initialize(userId);
    }

    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.newMatch != current.newMatch,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        }
        // Show match celebration when a new match occurs
        final newMatch = state.newMatch;
        if (newMatch != null) {
          // Get current user's photo for the celebration modal
          final currentProfile = context.read<ProfileBloc>().state.profile;
          final currentUserPhotoUrl = currentProfile?.photoUrls.isNotEmpty == true
              ? currentProfile!.photoUrls.first
              : null;

          // Show the celebration modal
          MatchCelebrationModal.show(
            context: context,
            matchedProfile: newMatch.matchedProfile,
            currentUserPhotoUrl: currentUserPhotoUrl,
            onKeepSwiping: () {
              // Clear the match after showing
              context.read<DiscoveryBloc>().add(DiscoveryMatchCelebrationShown());
            },
            onSendMessage: () {
              // Clear the match and navigate to chat
              context.read<DiscoveryBloc>().add(DiscoveryMatchCelebrationShown());
              context.push(
                CrushRoutes.chat,
                extra: {'matchId': newMatch.matchId},
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
        final isPlus = context.select<SubscriptionBloc, bool>(
          (b) => b.state.plan == SubscriptionPlan.plus,
        );
        final status = state.status;
        final retryInSeconds = state.nextRetrySeconds;
        final isLoading = status == DeckStatus.loading;
        final isEmptyDeck = status == DeckStatus.empty ||
            state.deck.isEmpty ||
            state.currentIndex >= state.deck.length;

        final currentProfile =
            isEmptyDeck ? null : state.deck[state.currentIndex];

        final backendSwipeReady = _backendCompleteness?.allowsSwipe ??
            (_backendBlocked ? false : _completenessError != null);
        final backendMessageReady = _backendCompleteness?.allowsMessaging ??
            (_backendBlocked ? false : _completenessError != null);

        return AsyncStateScaffold(
          appBar: _buildAppBar(context, userId),
          isLoading: isLoading && state.deck.isEmpty,
          errorMessage: status == DeckStatus.error ? state.errorMessage : null,
          error: status == DeckStatus.error && state.deck.isEmpty
              ? _buildErrorState(
                  context,
                  userId,
                  retryInSeconds,
                  isPlus: isPlus,
                  locationLabel: locationLabel,
                  radiusKm: radiusKm,
                )
              : null,
          empty: isEmptyDeck
              ? _buildOutOfPeople(
                  context,
                  userId,
                  isPlus: isPlus,
                  locationLabel: locationLabel,
                  radiusKm: radiusKm,
                )
              : null,
          showErrorSnackBar: true,
          showBodyOnLoading: true,
          body: currentProfile == null
              ? (isLoading && state.deck.isEmpty
                  ? const DeckSkeletonList()
                  : const SizedBox.shrink())
              : Column(
                  children: [
                    DeckStatusBar(
                      isLoading: isLoading,
                      retryInSeconds: retryInSeconds,
                      completeness: completeness,
                    ),
                    DeckSearchModeIndicator(
                      localDeckExhausted: state.localDeckExhausted,
                      passportModeActive: state.passportModeActive,
                      currentDistanceKm: state.currentDistanceLimitKm,
                      onTapPassport: () => context.push(CrushRoutes.discoverySettings),
                    ),
                    if (_checkingCompleteness)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Checking profile with server...',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    if (_completenessError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _completenessError!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.orange),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<_DeckSafetyAction>(
                        tooltip: 'Safety tools',
                        onSelected: (action) => _handleSafetyAction(
                          context,
                          action,
                          currentProfile: currentProfile,
                          currentUserId: userId,
                        ),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _DeckSafetyAction.viewProfile,
                            child: Text('View full profile'),
                          ),
                          PopupMenuItem(
                            value: _DeckSafetyAction.report,
                            child: Text('Report profile'),
                          ),
                          PopupMenuItem(
                            value: _DeckSafetyAction.block,
                            child: Text('Block & hide profile'),
                          ),
                          PopupMenuItem(
                            value: _DeckSafetyAction.guidelines,
                            child: Text('Community guidelines'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SwipeableCard(
                        profile: currentProfile,
                        onTap: () => context.push(
                          CrushRoutes.userProfile,
                          extra: OtherUserProfileArgs(profile: currentProfile),
                        ),
                        onSwipeLeft: () async {
                          // Pass action (swipe right to left)
                          if (userId == null) return;
                          final discoveryBloc = context.read<DiscoveryBloc>();
                          if (!_canSwipe(completeness, backendSwipeReady, isAccountVerified: isAccountVerified)) {
                            _showProfileIncompleteDialog(
                              context,
                              completeness,
                              remote: _backendCompleteness,
                              minimum: 'swipe',
                              isAccountVerified: isAccountVerified,
                            );
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
                          discoveryBloc.add(
                            DiscoverySwipedLeft(
                              userId: userId,
                              targetUserId: currentProfile.id,
                            ),
                          );
                        },
                        onSwipeRight: () async {
                          // Like action (swipe left to right)
                          if (userId == null) return;
                          final discoveryBloc = context.read<DiscoveryBloc>();
                          if (!_canSwipe(completeness, backendSwipeReady, isAccountVerified: isAccountVerified)) {
                            _showProfileIncompleteDialog(
                              context,
                              completeness,
                              remote: _backendCompleteness,
                              minimum: 'swipe',
                              isAccountVerified: isAccountVerified,
                            );
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
                          discoveryBloc.add(
                            DiscoverySwipedRight(
                              userId: userId,
                              targetUserId: currentProfile.id,
                            ),
                          );
                        },
                      ),
                    ),
                    DsGap.lg,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Rewind button (premium only)
                        DeckActionButton(
                          icon: Icons.replay,
                          color: DsColors.actionRewind,
                          semanticLabel: 'Undo last swipe',
                          size: 48,
                          enabled: state.canRewind,
                          onTap: () async {
                            if (userId == null) return;
                            final discoveryBloc = context.read<DiscoveryBloc>();
                            discoveryBloc.add(DiscoveryRewindRequested(userId));
                          },
                        ),
                        DeckActionButton(
                          icon: Icons.clear,
                          color: DsColors.actionPass,
                          semanticLabel: 'Pass on this profile',
                          onTap: () async {
                            if (userId == null) return;
                            final discoveryBloc = context.read<DiscoveryBloc>();
                            if (!_canSwipe(completeness, backendSwipeReady, isAccountVerified: isAccountVerified)) {
                              _showProfileIncompleteDialog(
                                context,
                                completeness,
                                remote: _backendCompleteness,
                                minimum: 'swipe',
                                isAccountVerified: isAccountVerified,
                              );
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
                            discoveryBloc.add(
                              DiscoverySwipedLeft(
                                userId: userId,
                                targetUserId: currentProfile.id,
                              ),
                            );
                          },
                        ),
                        // Super Like button (with remaining count badge)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            DeckActionButton(
                              icon: Icons.star,
                              color: DsColors.actionSuperLike,
                              semanticLabel: 'Super like this profile',
                              enabled: state.superLikesRemaining > 0,
                              onTap: () async {
                                if (userId == null) return;
                                final discoveryBloc = context.read<DiscoveryBloc>();
                                if (!_canSwipe(completeness, backendSwipeReady, isAccountVerified: isAccountVerified)) {
                                  _showProfileIncompleteDialog(
                                    context,
                                    completeness,
                                    remote: _backendCompleteness,
                                    minimum: 'swipe',
                                    isAccountVerified: isAccountVerified,
                                  );
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
                                discoveryBloc.add(
                                  DiscoverySuperLiked(
                                    userId: userId,
                                    targetUserId: currentProfile.id,
                                  ),
                                );
                              },
                            ),
                            // Badge showing remaining super likes
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: state.superLikesRemaining > 0
                                      ? DsColors.actionSuperLike
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${state.superLikesRemaining}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        DeckActionButton(
                          icon: Icons.favorite,
                          color: DsColors.actionLike,
                          semanticLabel: 'Like this profile',
                          onTap: () async {
                            if (userId == null) return;
                            final discoveryBloc = context.read<DiscoveryBloc>();
                            if (!_canSwipe(completeness, backendSwipeReady, isAccountVerified: isAccountVerified)) {
                              _showProfileIncompleteDialog(
                                context,
                                completeness,
                                remote: _backendCompleteness,
                                minimum: 'swipe',
                                isAccountVerified: isAccountVerified,
                              );
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
                            discoveryBloc.add(
                              DiscoverySwipedRight(
                                userId: userId,
                                targetUserId: currentProfile.id,
                              ),
                            );
                          },
                        ),
                        // Message button
                        DeckActionButton(
                          icon: Icons.message,
                          color: DsColors.actionMessage,
                          semanticLabel: 'Send message',
                          size: 48,
                          onTap: () async {
                            if (userId == null) return;
                            if (!_canMessage(
                              completeness,
                              backendMessageReady,
                            )) {
                              _showProfileIncompleteDialog(
                                context,
                                completeness,
                                remote: _backendCompleteness,
                                minimum: 'message',
                                isAccountVerified: isAccountVerified,
                              );
                              return;
                            }
                            final outcome = await _evaluateBackendAllowance(
                              minimum: 'message',
                              local: completeness,
                              isAccountVerified: isAccountVerified,
                            );
                            if (!context.mounted) return;
                            final allowed = _handleBackendOutcome(
                              context,
                              outcome,
                              minimum: 'message',
                              completeness: completeness,
                              isAccountVerified: isAccountVerified,
                            );
                            if (!allowed) return;
                            await _showPreMatchDialog(
                              context: context,
                              preMatchService:
                                  preMatchService ?? PreMatchService(),
                              targetUserId: currentProfile.id,
                            );
                          },
                        ),
                      ],
                    ),
                    DsGap.xxl,
                  ],
                ),
        );
      },
    );
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

  Future<void> _refreshBackendCompleteness({String minimum = 'message'}) async {
    setState(() {
      _checkingCompleteness = true;
      _completenessError = null;
    });
    try {
      final result = await _validationService.validate(minimum: minimum);
      if (!mounted) return;
      setState(() {
        _backendCompleteness = result;
        _completenessError = null;
        _backendBlocked = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backendCompleteness = null;
        _completenessError = _friendlyError(e);
        _backendBlocked = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingCompleteness = false;
        });
      }
    }
  }

  Future<_BackendCheckOutcome> _evaluateBackendAllowance({
    required String minimum,
    required ProfileCompletenessSummary local,
    required bool isAccountVerified,
  }) async {
    if ((minimum == 'swipe' && !_canSwipe(local, true, isAccountVerified: isAccountVerified)) ||
        (minimum == 'message' && !_canMessage(local, true))) {
      return const _BackendCheckOutcome(
        allowed: false,
        blocked: true,
      );
    }

    if (_backendCompleteness == null && !_checkingCompleteness) {
      await _refreshBackendCompleteness(minimum: minimum);
    }

    final backend = _backendCompleteness;
    if (backend == null) {
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
        return const _BackendCheckOutcome(
          allowed: false,
          message:
              'Checking your profile with the server. Try again in a moment.',
        );
      }
      return const _BackendCheckOutcome(allowed: false);
    }

    final allowed =
        minimum == 'message' ? backend.allowsMessaging : backend.allowsSwipe;
    return _BackendCheckOutcome(
      allowed: allowed,
      remote: backend,
      blocked: !allowed,
    );
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
    final remoteMissing = minimum == 'message'
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

  bool _canMessage(
    ProfileCompletenessSummary local,
    bool backendAllowed,
  ) {
    return local.meetsMessagingMinimum &&
        local.meetsRequiredFields &&
        backendAllowed;
  }

  String _friendlyError(Object error) {
    if (error is Exception) {
      return error.toString();
    }
    return 'Could not verify profile completeness. Check your connection.';
  }

  Widget _buildErrorState(
    BuildContext context,
    String? userId,
    int? retryInSeconds, {
    required bool isPlus,
    String? locationLabel,
    double? radiusKm,
  }) {
    final radiusLabel = radiusKm?.toStringAsFixed(0);
    return Scaffold(
      appBar: _buildAppBar(context, userId),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 72),
              DsGap.md,
              const Text(
                'Trouble loading people',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              DsGap.sm,
              Text(
                'Check your connection and try again.'
                '${locationLabel != null ? '\nLooking near $locationLabel${radiusLabel != null ? ' within ~$radiusLabel km' : ''}.' : ''}',
                textAlign: TextAlign.center,
              ),
              DsGap.lg,
              if (retryInSeconds != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Retrying automatically in ~${retryInSeconds}s',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: userId == null
                    ? null
                    : () => context
                        .read<DiscoveryBloc>()
                        .add(DiscoveryDeckRequested(userId)),
              ),
              if (retryInSeconds != null)
                TextButton.icon(
                  icon: const Icon(Icons.timer),
                  label: Text('Auto-retrying in ~${retryInSeconds}s'),
                  onPressed: userId == null
                      ? null
                      : () => context
                          .read<DiscoveryBloc>()
                          .add(DiscoveryDeckRequested(userId)),
                ),
              if (!isPlus) ...[
                DsGap.lg,
                OutlinedButton.icon(
                  icon: const Icon(Icons.flight_takeoff),
                  label: const Text('Try Passport with Plus'),
                  onPressed: () => _showPassportUpsell(context),
                ),
                DsGap.sm,
                const UpgradeNudgeCard(
                  title: 'Try Plus while we fix this',
                  subtitle:
                      'Unlock offline likes, queue retries, and Passport so you never miss a match.',
                  bullets: [
                    'Intro offer: 50% off your first month',
                    'Unlimited likes & rewinds',
                    'Passport to swipe anywhere',
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutOfPeople(
    BuildContext context,
    String? userId, {
    required bool isPlus,
    String? locationLabel,
    double? radiusKm,
  }) {
    final discoveryState = context.watch<DiscoveryBloc>().state;
    final localDeckExhausted = discoveryState.localDeckExhausted;
    final passportModeActive = discoveryState.passportModeActive;
    final currentDistanceKm = discoveryState.currentDistanceLimitKm;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Context-aware messaging
    String title;
    String subtitle;
    IconData icon;
    Color? iconColor;

    if (passportModeActive) {
      title = 'No one in this city yet';
      subtitle = 'Try exploring a different destination or check back later.';
      icon = Icons.flight_takeoff;
      iconColor = Colors.cyan;
    } else if (localDeckExhausted) {
      title = 'Explored far and wide';
      subtitle = 'You\'ve seen everyone up to ${currentDistanceKm.round()} km away.\n'
          'Try Passport mode to explore globally!';
      icon = Icons.explore;
      iconColor = DsColors.secondary;
    } else {
      title = 'You\'re all caught up!';
      subtitle = 'No more people within 220 km right now.\n'
          'Check back soon or try expanding your search.';
      icon = Icons.people_outline;
      iconColor = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: iconColor != null
                          ? LinearGradient(
                              colors: [
                                iconColor.withValues(alpha: 0.2),
                                iconColor.withValues(alpha: 0.1),
                              ],
                            )
                          : null,
                      color: iconColor == null
                          ? (isDark ? DsColors.surfaceDark : DsColors.surfaceLight)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 56,
                      color: iconColor ?? (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  DsGap.lg,
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  DsGap.sm,
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                    ),
                  ),
                  if (locationLabel != null) ...[
                    DsGap.md,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            passportModeActive
                                ? locationLabel
                                : '$locationLabel • ${currentDistanceKm.round()} km',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  DsGap.xxl,
                  BlocBuilder<DiscoverySettingsCubit, DiscoverySettingsState>(
                    builder: (context, filterState) {
                      final activeCount = filterState.activeAdvancedFilterCount;
                      return FilledButton.icon(
                        icon: activeCount > 0
                            ? Badge(
                                label: Text('$activeCount'),
                                backgroundColor: DsColors.secondary,
                                child: const Icon(Icons.tune, size: 18),
                              )
                            : const Icon(Icons.tune, size: 18),
                        onPressed: () => context.push(CrushRoutes.discoverySettings),
                        label: Text(activeCount > 0 ? 'Filters active' : 'Adjust filters'),
                      );
                    },
                  ),
                  DsGap.md,
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh deck'),
                    onPressed: userId == null
                        ? null
                        : () => context
                            .read<DiscoveryBloc>()
                            .add(DiscoveryDeckRequested(userId)),
                  ),
                  if (!passportModeActive) ...[
                    DsGap.md,
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flight_takeoff, size: 18),
                      onPressed: isPlus
                          ? () => context.push(CrushRoutes.discoverySettings)
                          : () => _showPassportUpsell(context),
                      label: Text(isPlus ? 'Enable Passport mode' : 'Try Passport with Plus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyan,
                        side: BorderSide(color: Colors.cyan.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                  if (!isPlus) ...[
                    DsGap.lg,
                    const UpgradeNudgeCard(
                      title: 'Unlock Passport Mode',
                      subtitle:
                          'Go global with Passport and explore people from anywhere.',
                      bullets: [
                        'Passport to any city',
                        'Unlimited likes & rewinds',
                        'See who likes you first',
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileIncompleteDialog(
    BuildContext context,
    ProfileCompletenessSummary completeness, {
    RemoteProfileCompleteness? remote,
    String minimum = 'swipe',
    bool isAccountVerified = true,
  }) {
    final percent = ((remote?.score ?? completeness.score) * 100).round();
    final missingList =
        _missingMessages(completeness, remote, minimum: minimum);
    final missing = missingList.take(3).join('\n• ');

    // Check if account verification is the issue
    if (!isAccountVerified) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verify your account'),
          content: const Text(
            'Please verify your email or phone number to start swiping and matching with others.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(CrushRoutes.emailProtection);
              },
              child: const Text('Verify now'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete your profile'),
        content: Text(
          percent >= 100
              ? 'Your profile looks good.'
              : 'Your profile is $percent% complete. Add these to unlock swiping and messaging:\n\n• ${missing.isEmpty ? 'Add photos and a longer bio' : missing}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToProfileEdit(context);
            },
            child: const Text('Complete profile'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String? userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsBlur.heavy,
            sigmaY: DsBlur.heavy,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (isDark
                          ? DsGlassColors.surfaceDark
                          : DsGlassColors.surfaceLight)
                      .withValues(alpha: 0.8),
                  (isDark
                          ? DsGlassColors.surfaceDark
                          : DsGlassColors.surfaceLight)
                      .withValues(alpha: 0.6),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? DsGlassColors.borderDark
                      : DsGlassColors.borderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered title
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            DsGradients.primaryHorizontal.createShader(bounds),
                        child: Text(
                          'Crush',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                    // Boost indicator and weekly picks on the left
                    Positioned(
                      left: DsSpacing.sm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BoostButton(),
                          const SizedBox(width: DsSpacing.xs),
                          GlassIconButton(
                            icon: Icons.auto_awesome,
                            onPressed: () => context.push(CrushRoutes.weeklyPicks),
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                    // Actions on the right
                    Positioned(
                      right: DsSpacing.sm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GlassIconButton(
                            icon: Icons.shield_outlined,
                            onPressed: () => context.push(CrushRoutes.safety),
                            size: 40,
                          ),
                          const SizedBox(width: DsSpacing.xs),
                          GlassIconButton(
                            icon: Icons.refresh,
                            onPressed: userId == null
                                ? () {}
                                : () => context
                                    .read<DiscoveryBloc>()
                                    .add(DiscoveryDeckRequested(userId)),
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final currentProfileName = currentProfile.name;
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
              content:
                  Text('Blocked $currentProfileName and hidden from deck.'),
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
            builder: (context, subState) {
              final isPlus = subState.plan == SubscriptionPlan.plus;
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
                    const UpsellBullets(items: [
                      'Passport to any city',
                      'See who likes you first',
                      'Unlimited likes & rewinds',
                    ]),
                    DsGap.lg,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                if (!isPlus) {
                                  sheetContext
                                      .read<SubscriptionBloc>()
                                      .add(PlusCheckoutRequested());
                                }
                              },
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(isPlus ? 'Got it' : 'Upgrade to Plus'),
                      ),
                    ),
                    if (!isPlus)
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Maybe later'),
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
                subtitle: const Text(
                  'We will review and may limit accounts that violate guidelines.',
                ),
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
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Submit'),
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
      messenger.showSnackBar(SnackBar(
        content: Text('Report submitted for $reportedName.'),
      ));
    }
  }

  Future<void> _showPreMatchDialog({
    required BuildContext context,
    required PreMatchService preMatchService,
    required String targetUserId,
  }) async {
    final controller = TextEditingController();
    String? inlineError;
    var isSending = false;

    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Send message request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Say something nice…',
                    ),
                    enabled: !isSending,
                    onChanged: (_) {
                      if (inlineError != null) {
                        setState(() => inlineError = null);
                      }
                    },
                  ),
                  if (inlineError != null) ...[
                    DsGap.sm,
                    Text(
                      inlineError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  if (isSending) ...[
                    DsGap.sm,
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          setState(() {
                            isSending = true;
                          });
                          final text = controller.text.trim();
                          if (text.isEmpty || text.length < 4) {
                            inlineError =
                                'Write at least 4 characters to send a message request.';
                          } else if (text.length > 200) {
                            inlineError = 'Keep it under 200 characters.';
                          } else if (_containsProfanity(text)) {
                            inlineError =
                                'Please remove inappropriate language.';
                          } else {
                            Navigator.pop(dialogContext, text);
                            return;
                          }
                          setState(() {
                            isSending = false;
                          });
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    if (content == null || content.isEmpty) return;

    try {
      isSending = true;
      final result = await Result.guard(
        () => preMatchService.sendPreMatchMessageRequest(
          targetUserId: targetUserId,
          content: content,
        ),
        logLabel: 'PreMatchService.sendPreMatchMessageRequest',
        fallbackError: 'Could not send message request. Try again.',
      );
      if (!context.mounted) return;
      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message request sent')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send message request. Try again.'),
        ),
      );
    }
  }

  bool _containsProfanity(String text) {
    return ProfanityFilter.containsProfanity(text);
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
