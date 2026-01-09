import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/profanity_filter.dart';
import '../../core/profile_completeness.dart';
import '../../core/result.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../data/models/profile.dart';
import '../../data/models/subscription.dart';
import '../../data/services/prematch_service.dart';
import '../../data/services/profile_validation_service.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing_widgets.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/discovery/discovery_bloc.dart';
import '../../logic/discovery/discovery_event.dart';
import '../../logic/discovery/discovery_state.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/safety/safety_cubit.dart';
import '../../logic/subscription/subscription_bloc.dart';
import '../../logic/subscription/subscription_event.dart';
import '../../logic/subscription/subscription_state.dart';
import '../widgets/async_state_scaffold.dart';
import '../widgets/deck_ui_helpers.dart';
import '../widgets/swipe_card.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'other_user_profile_screen.dart';

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

  ProfileValidationService get _validationService =>
      widget.validationService ?? ProfileValidationService();

  @override
  Widget build(BuildContext context) {
    final preMatchService = widget.preMatchService;
    final userId = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );

    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
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
                  ? const _DeckSkeletonList()
                  : const SizedBox.shrink())
              : Column(
                  children: [
                    DeckStatusBar(
                      isLoading: isLoading,
                      retryInSeconds: retryInSeconds,
                      completeness: completeness,
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
                      child: _SwipeableCard(
                        profile: currentProfile,
                        onTap: () => context.push(
                          CrushRoutes.userProfile,
                          extra: OtherUserProfileArgs(profile: currentProfile),
                        ),
                        onSwipeLeft: () async {
                          // Pass action (swipe right to left)
                          if (userId == null) return;
                          final discoveryBloc = context.read<DiscoveryBloc>();
                          if (!_canSwipe(completeness, backendSwipeReady)) {
                            _showProfileIncompleteDialog(
                              context,
                              completeness,
                              remote: _backendCompleteness,
                              minimum: 'swipe',
                            );
                            return;
                          }
                          final outcome = await _evaluateBackendAllowance(
                            minimum: 'swipe',
                            local: completeness,
                          );
                          if (!context.mounted) return;
                          final allowed = _handleBackendOutcome(
                            context,
                            outcome,
                            minimum: 'swipe',
                            completeness: completeness,
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
                          if (!_canSwipe(completeness, backendSwipeReady)) {
                            _showProfileIncompleteDialog(
                              context,
                              completeness,
                              remote: _backendCompleteness,
                              minimum: 'swipe',
                            );
                            return;
                          }
                          final outcome = await _evaluateBackendAllowance(
                            minimum: 'swipe',
                            local: completeness,
                          );
                          if (!context.mounted) return;
                          final allowed = _handleBackendOutcome(
                            context,
                            outcome,
                            minimum: 'swipe',
                            completeness: completeness,
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
                        DeckActionButton(
                          icon: Icons.clear,
                          color: DsColors.actionPass,
                          onTap: () async {
                            if (userId == null) return;
                            final discoveryBloc = context.read<DiscoveryBloc>();
                            if (!_canSwipe(completeness, backendSwipeReady)) {
                              _showProfileIncompleteDialog(
                                context,
                                completeness,
                                remote: _backendCompleteness,
                                minimum: 'swipe',
                              );
                              return;
                            }
                            final outcome = await _evaluateBackendAllowance(
                              minimum: 'swipe',
                              local: completeness,
                            );
                            if (!context.mounted) return;
                            final allowed = _handleBackendOutcome(
                              context,
                              outcome,
                              minimum: 'swipe',
                              completeness: completeness,
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
                        DeckActionButton(
                          icon: Icons.message,
                          color: DsColors.actionMessage,
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
                              );
                              return;
                            }
                            final outcome = await _evaluateBackendAllowance(
                              minimum: 'message',
                              local: completeness,
                            );
                            if (!context.mounted) return;
                            final allowed = _handleBackendOutcome(
                              context,
                              outcome,
                              minimum: 'message',
                              completeness: completeness,
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
                        DeckActionButton(
                          icon: Icons.favorite,
                          color: DsColors.actionLike,
                          onTap: () async {
                            if (userId == null) return;
                            final discoveryBloc = context.read<DiscoveryBloc>();
                            if (!_canSwipe(completeness, backendSwipeReady)) {
                              _showProfileIncompleteDialog(
                                context,
                                completeness,
                                remote: _backendCompleteness,
                                minimum: 'swipe',
                              );
                              return;
                            }
                            final outcome = await _evaluateBackendAllowance(
                              minimum: 'swipe',
                              local: completeness,
                            );
                            if (!context.mounted) return;
                            final allowed = _handleBackendOutcome(
                              context,
                              outcome,
                              minimum: 'swipe',
                              completeness: completeness,
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
      profile.prompts.length,
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
  }) async {
    if ((minimum == 'swipe' && !_canSwipe(local, true)) ||
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
  }) {
    if (!outcome.allowed) {
      if (outcome.blocked) {
        _showProfileIncompleteDialog(
          context,
          completeness,
          remote: outcome.remote ?? _backendCompleteness,
          minimum: minimum,
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
    bool backendAllowed,
  ) {
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
                const _UpgradeNudgeCard(
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
    final radiusLabel = radiusKm?.toStringAsFixed(0);
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
                  const Icon(Icons.people_outline, size: 72),
                  DsGap.lg,
                  const Text(
                    'You’re all caught up!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DsGap.sm,
                  const Text(
                    'There are no more people nearby right now.\n'
                    'You can adjust your filters or explore with Passport.',
                    textAlign: TextAlign.center,
                  ),
                  if (locationLabel != null || radiusKm != null) ...[
                    DsGap.sm,
                    Text(
                      'Current filters: ${locationLabel ?? 'your area'}'
                      '${radiusLabel != null ? ' • ~$radiusLabel km radius' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  DsGap.xxl,
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Change filters'),
                  ),
                  DsGap.md,
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh deck'),
                    onPressed: userId == null
                        ? null
                        : () => context
                            .read<DiscoveryBloc>()
                            .add(DiscoveryDeckRequested(userId)),
                  ),
                  DsGap.md,
                  OutlinedButton(
                    onPressed: () => _showPassportUpsell(context),
                    child: const Text('Try Passport with Plus'),
                  ),
                  if (!isPlus) ...[
                    DsGap.md,
                    const _UpgradeNudgeCard(
                      title: 'Intro offer: 50% off Plus',
                      subtitle:
                          'Go global with Passport, see who likes you, and undo swipes.',
                      bullets: [
                        'Passport to any city',
                        'Unlimited likes & rewinds',
                        'Priority in the deck',
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
  }) {
    final percent = ((remote?.score ?? completeness.score) * 100).round();
    final missingList =
        _missingMessages(completeness, remote, minimum: minimum);
    final missing = missingList.take(3).join('\n• ');
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
    return AppBar(
      title: const Text('Crush'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.shield_outlined),
          tooltip: 'Safety Center',
          onPressed: () => context.push(CrushRoutes.safety),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: userId == null
              ? null
              : () => context
                  .read<DiscoveryBloc>()
                  .add(DiscoveryDeckRequested(userId)),
        ),
      ],
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
                        const _IntroBadge(),
                      ],
                    ),
                    DsGap.sm,
                    Text(
                      isPlus
                          ? 'Change your location and explore anywhere.'
                          : 'Intro offer: 50% off your first month. Explore any city, see likes, and keep swiping with unlimited likes.',
                    ),
                    DsGap.md,
                    const _UpsellBullets(items: [
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

class _DeckSkeletonList extends StatelessWidget {
  const _DeckSkeletonList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 16),
        _SkeletonCard(height: 18, widthFactor: 0.6),
        SizedBox(height: 12),
        _SkeletonCard(height: 250),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SkeletonCircle(size: 60),
            _SkeletonCircle(size: 60),
            _SkeletonCircle(size: 60),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height, this.widthFactor});
  final double height;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 0.9,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: DsColors.skeletonLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: DsColors.skeletonLight,
        shape: BoxShape.circle,
      ),
    );
  }
}

enum _DeckSafetyAction { viewProfile, report, block, guidelines }

class _UpgradeNudgeCard extends StatelessWidget {
  const _UpgradeNudgeCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blueGrey.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IntroBadge(),
                DsGap.smH,
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 10),
            _UpsellBullets(items: bullets),
            DsGap.md,
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, subState) {
                final loading = subState.isCheckoutInProgress;
                final isPlus = subState.plan == SubscriptionPlan.plus;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading || isPlus
                        ? null
                        : () {
                            context
                                .read<SubscriptionBloc>()
                                .add(PlusCheckoutRequested());
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isPlus ? 'Thanks for being Plus!' : 'Upgrade now'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroBadge extends StatelessWidget {
  const _IntroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Intro offer',
        style: TextStyle(
          color: Colors.pink,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _UpsellBullets extends StatelessWidget {
  const _UpsellBullets({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// A swipeable card widget that handles horizontal swipe gestures.
/// Swipe left to right = Like, Swipe right to left = Pass
class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    required this.profile,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _dragStartX = 0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _swipeThreshold = 100.0;
  static const double _maxRotation = 0.1; // radians

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragX = details.globalPosition.dx - _dragStartX;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipeRight = _dragX > _swipeThreshold || velocity > 500;
    final shouldSwipeLeft = _dragX < -_swipeThreshold || velocity < -500;

    if (shouldSwipeRight) {
      // Swipe left to right = Like
      _animateOut(true);
    } else if (shouldSwipeLeft) {
      // Swipe right to left = Pass
      _animateOut(false);
    } else {
      // Snap back to center
      _animateBack();
    }
  }

  void _animateOut(bool isLike) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth : -screenWidth;

    _animation = Tween<double>(begin: _dragX, end: targetX).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0).then((_) {
      if (isLike) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
      // Reset position for next card
      setState(() {
        _dragX = 0;
      });
      _animationController.reset();
    });
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(() {
      setState(() {
        _dragX = _animation.value;
      });
    });

    _animationController.forward(from: 0).then((_) {
      _animationController.removeListener(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final rotation = (_dragX / 500).clamp(-_maxRotation, _maxRotation);
    final opacity = 1 - (_dragX.abs() / 300).clamp(0.0, 0.3);

    return GestureDetector(
      onTap: _isDragging ? null : widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final currentX = _animationController.isAnimating ? _animation.value : _dragX;
          return Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(currentX, 0, 0)
              ..rotateZ(rotation),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Opacity(
                  opacity: opacity,
                  child: SwipeCard(profile: widget.profile),
                ),
                // Like indicator (right side)
                if (_dragX > 20)
                  Positioned(
                    left: 30,
                    top: 30,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LIKE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Pass indicator (left side)
                if (_dragX < -20)
                  Positioned(
                    right: 30,
                    top: 30,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NOPE',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
