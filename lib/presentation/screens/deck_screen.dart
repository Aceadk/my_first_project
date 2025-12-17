import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../core/profile_completeness.dart';
import '../../data/models/profile.dart';
import '../../logic/discovery/discovery_bloc.dart';
import '../../logic/discovery/discovery_event.dart';
import '../../logic/discovery/discovery_state.dart';
import '../../data/services/prematch_service.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/result.dart';
import '../../core/router.dart';
import '../../logic/safety/safety_cubit.dart';
import '../../logic/subscription/subscription_bloc.dart';
import '../../logic/subscription/subscription_event.dart';
import '../../logic/subscription/subscription_state.dart';
import '../../data/models/subscription.dart';
import '../widgets/swipe_card.dart';
import 'settings_screen.dart';
import 'profile_edit_screen.dart';

class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key, this.preMatchService});

  final PreMatchService? preMatchService;

  @override
  Widget build(BuildContext context) {
    final preMatchService = this.preMatchService;
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
        final isPlus = context.select<SubscriptionBloc, bool>(
          (b) => b.state.plan == SubscriptionPlan.plus,
        );
        final status = state.status;
        final retryInSeconds = state.nextRetrySeconds;
        final isLoading = status == DeckStatus.loading;
        final isEmptyDeck = status == DeckStatus.empty ||
            state.deck.isEmpty ||
            state.currentIndex >= state.deck.length;

        if (isLoading && state.deck.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(context, userId),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (status == DeckStatus.error && state.deck.isEmpty) {
          return _buildErrorState(
            context,
            userId,
            retryInSeconds,
            isPlus: isPlus,
          );
        }

        if (isEmptyDeck) {
          return Scaffold(
            appBar: _buildAppBar(context, userId),
            body: _buildOutOfPeople(
              context,
              userId,
              isPlus: isPlus,
            ),
          );
        }

        final currentProfile = state.deck[state.currentIndex];

        return Scaffold(
          appBar: _buildAppBar(context, userId),
          body: Column(
            children: [
              _buildStatusBar(
                isLoading: isLoading,
                retryInSeconds: retryInSeconds,
                completeness: completeness,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<_DeckSafetyAction>(
                  tooltip: 'Safety tools',
                  onSelected: (action) => _handleSafetyAction(
                    context,
                    action,
                    currentProfileId: currentProfile.id,
                    currentProfileName: currentProfile.name,
                    currentUserId: userId,
                  ),
                  itemBuilder: (context) => const [
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
                child: SwipeCard(profile: currentProfile),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _circleButton(
                    icon: Icons.clear,
                    color: Colors.grey.shade300,
                    onTap: () {
                      if (userId == null) return;
                      if (!completeness.meetsSwipeMinimum) {
                        _showProfileIncompleteDialog(context, completeness);
                        return;
                      }
                      context.read<DiscoveryBloc>().add(
                            DiscoverySwipedLeft(
                              userId: userId,
                              targetUserId: currentProfile.id,
                            ),
                          );
                    },
                  ),
                  _circleButton(
                    icon: Icons.message,
                    color: Colors.blueAccent,
                    onTap: () async {
                      if (userId == null) return;
                      if (!completeness.meetsMessagingMinimum) {
                        _showProfileIncompleteDialog(context, completeness);
                        return;
                      }
                      await _showPreMatchDialog(
                        context: context,
                        preMatchService: preMatchService ?? PreMatchService(),
                        targetUserId: currentProfile.id,
                      );
                    },
                  ),
                  _circleButton(
                    icon: Icons.favorite,
                    color: Colors.pinkAccent,
                    onTap: () {
                      if (userId == null) return;
                      if (!completeness.meetsSwipeMinimum) {
                        _showProfileIncompleteDialog(context, completeness);
                        return;
                      }
                      context.read<DiscoveryBloc>().add(
                            DiscoverySwipedRight(
                              userId: userId,
                              targetUserId: currentProfile.id,
                            ),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
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

  Widget _buildErrorState(
    BuildContext context,
    String? userId,
    int? retryInSeconds, {
    required bool isPlus,
  }) {
    return Scaffold(
      appBar: _buildAppBar(context, userId),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 72),
              const SizedBox(height: 12),
              const Text(
                'Trouble loading people',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
              if (!isPlus) ...[
                const SizedBox(height: 16),
                const _UpgradeNudgeCard(
                  title: 'Try Plus while we fix this',
                  subtitle:
                      'Unlock offline likes, queue retries, and Passport so you never miss a match.',
                  bullets:  [
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
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 72),
            const SizedBox(height: 16),
            const Text(
              'You’re all caught up!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no more people nearby right now.\n'
              'You can adjust your filters or explore with Passport.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh deck'),
              onPressed: userId == null
                  ? null
                  : () => context
                      .read<DiscoveryBloc>()
                      .add(DiscoveryDeckRequested(userId)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showPassportUpsell(context),
              child: const Text('Try Passport with Plus'),
            ),
            if (!isPlus) ...[
              const SizedBox(height: 12),
              const _UpgradeNudgeCard(
                title: 'Intro offer: 50% off Plus',
                subtitle:
                    'Go global with Passport, see who likes you, and undo swipes.',
                bullets:  [
                  'Passport to any city',
                  'Unlimited likes & rewinds',
                  'Priority in the deck',
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: CircleAvatar(
        backgroundColor: color,
        radius: 28,
        child: Icon(icon, color: Colors.black),
      ),
    );
  }

  Widget _buildStatusBar({
    required bool isLoading,
    required int? retryInSeconds,
    required ProfileCompletenessSummary completeness,
  }) {
    if (isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (retryInSeconds != null) {
      return Container(
        width: double.infinity,
        color: Colors.orange.withAlpha((0.08 * 255).round()),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.refresh, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Retrying in ~${retryInSeconds}s…',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
      );
    }

    if (!completeness.meetsSwipeMinimum) {
      final percent = (completeness.score * 100).round();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: completeness.score, minHeight: 6),
            const SizedBox(height: 8),
            Text(
              'Profile completeness: $percent% — finish your profile to swipe and message.',
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 2);
  }

  void _showProfileIncompleteDialog(
    BuildContext context,
    ProfileCompletenessSummary completeness,
  ) {
    final percent = (completeness.score * 100).round();
    final missing = completeness.missing.take(3).join('\n• ');
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
      title: const Text('CrushHour'),
      centerTitle: true,
      actions: [
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
    required String currentProfileId,
    required String currentProfileName,
    required String? currentUserId,
  }) async {
    final safety = context.read<SafetyCubit>();
    switch (action) {
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
        Navigator.pushNamed(context, CrushRoutes.safetyGuidelines);
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
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 8),
                    Text(
                      isPlus
                          ? 'Change your location and explore anywhere.'
                          : 'Intro offer: 50% off your first month. Explore any city, see likes, and keep swiping with unlimited likes.',
                    ),
                    const SizedBox(height: 12),
                    const _UpsellBullets(items: [
                      'Passport to any city',
                      'See who likes you first',
                      'Unlimited likes & rewinds',
                    ]),
                    const SizedBox(height: 16),
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
              const SizedBox(height: 8),
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Send message request'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Say something nice…',
                    ),
                    onChanged: (_) {
                      if (inlineError != null) {
                        setState(() => inlineError = null);
                      }
                    },
                  ),
                  if (inlineError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      inlineError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  if (isSending) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty || text.length < 4) {
                  inlineError =
                      'Write at least 4 characters to send a message request.';
                } else if (text.length > 200) {
                  inlineError = 'Keep it under 200 characters.';
                } else if (_containsProfanity(text)) {
                  inlineError = 'Please remove inappropriate language.';
                } else {
                  Navigator.pop(context, text);
                  return;
                }
                (context as Element).markNeedsBuild();
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (content == null || content.isEmpty) return;

    try {
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
    const banned = [
      'damn',
      'hell',
      'shit',
      'fuck',
      'bitch',
    ];
    final lower = text.toLowerCase();
    return banned.any((word) => lower.contains(word));
  }
}

enum _DeckSafetyAction { report, block, guidelines }

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
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
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
