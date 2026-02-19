import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_cubit.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_state.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';

PreferredSizeWidget _buildMessageRequestsAppBar(BuildContext context) {
  final baseSurface = DsGlassColors.surfaceFor(context);
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
                baseSurface.withValues(alpha: 0.8),
                baseSurface.withValues(alpha: 0.6),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: DsGlassColors.borderFor(context),
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
                  Positioned(
                    left: DsSpacing.sm,
                    child: GlassIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => context.pop(),
                      size: 40,
                    ),
                  ),
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          DsGradients.chats.createShader(bounds),
                      child: Text(
                        'Message Requests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: DsColors.surfaceLight,
                            ),
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
  );
}

Widget _buildMessageRequestsEmptyState(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Center(
    child: Padding(
      padding: DsEdgeInsets.allXxl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: DsBlur.medium,
                sigmaY: DsBlur.medium,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DsColors.secondary.withValues(alpha: 0.2),
                      DsColors.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DsGlassColors.borderFor(context),
                    width: 1.5,
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      DsGradients.chats.createShader(bounds),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 52,
                    color: DsColors.surfaceLight,
                  ),
                ),
              ),
            ),
          ),
          DsGap.xxl,
          ShaderMask(
            shaderCallback: (bounds) =>
                DsGradients.primaryHorizontal.createShader(bounds),
            child: Text(
              'No message requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DsColors.surfaceLight,
                  ),
            ),
          ),
          DsGap.sm,
          Text(
            'When someone sends you a message request,\nit will show up here for 48 hours.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
          ),
        ],
      ),
    ),
  );
}

class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view message requests.')),
      );
    }

    return BlocProvider(
      create: (context) => MessageRequestsCubit(
        chatRepository: context.read<ChatRepository>(),
        discoveryRepository: context.read<DiscoveryRepository>(),
        userId: userId,
      )..load(),
      child: _MessageRequestsView(currentUserId: userId),
    );
  }
}

class _MessageRequestsView extends StatelessWidget {
  final String currentUserId;

  const _MessageRequestsView({required this.currentUserId});

  Future<void> _openProfile(
    BuildContext context,
    MessageRequest request,
  ) async {
    final repo = context.read<DiscoveryRepository>();
    final otherUserId = request.otherUserIdFor(currentUserId);
    final profile = await repo.fetchProfileById(otherUserId);
    if (!context.mounted) return;
    if (profile == null) {
      showErrorSnackBar(context, 'Could not load profile.');
      return;
    }
    context.push(
      CrushRoutes.userProfile,
      extra: OtherUserProfileArgs(profile: profile, isMatch: false),
    );
  }

  void _showMatchCelebration(BuildContext context, String userName) {
    DsHaptics.match();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _MatchCelebrationDialog(userName: userName),
    ).then((_) {
      if (context.mounted) {
        context.read<MessageRequestsCubit>().clearMatchNotification();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessageRequestsCubit, MessageRequestsState>(
      listener: (context, state) {
        // Show match celebration
        if (state.showMatchNotification && state.matchedUserName != null) {
          _showMatchCelebration(context, state.matchedUserName!);
        }

        // Show error snackbar
        if (state.actionStatus == RequestActionStatus.error &&
            state.actionErrorMessage != null) {
          DsHaptics.error();
          showErrorSnackBar(context, state.actionErrorMessage!);
          context.read<MessageRequestsCubit>().clearAction();
        }
      },
      builder: (context, state) {
        return AsyncStateScaffold(
          appBar: _buildMessageRequestsAppBar(context),
          isLoading: state.isLoading && state.requests.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: state.requests.isEmpty
              ? _buildMessageRequestsEmptyState(context)
              : null,
          body: RefreshIndicator(
            onRefresh: () => context.read<MessageRequestsCubit>().refresh(),
            child: ListView.separated(
              padding: DsEdgeInsets.allLg,
              itemCount: state.requests.length,
              separatorBuilder: (_, _) => DsGap.md,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                return _MessageRequestCard(
                  request: request,
                  currentUserId: currentUserId,
                  isProcessing: state.isProcessing(request.id),
                  onTap: () => _openProfile(context, request),
                  onAccept: request.isInboundFor(currentUserId)
                      ? () {
                          DsHaptics.medium();
                          context
                              .read<MessageRequestsCubit>()
                              .acceptRequest(request);
                        }
                      : null,
                  onDecline: () {
                    DsHaptics.light();
                    _showDeclineConfirmation(context, request);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeclineConfirmation(BuildContext context, MessageRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
        title: const Text('Decline request?'),
        content: const Text(
          'This will remove the message request. '
          'You can still match with them later through discovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<MessageRequestsCubit>().declineRequest(request);
            },
            style: TextButton.styleFrom(foregroundColor: DsColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}

/// Individual message request card with countdown timer.
class _MessageRequestCard extends StatefulWidget {
  final MessageRequest request;
  final String currentUserId;
  final bool isProcessing;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback onDecline;

  const _MessageRequestCard({
    required this.request,
    required this.currentUserId,
    required this.isProcessing,
    required this.onTap,
    this.onAccept,
    required this.onDecline,
  });

  @override
  State<_MessageRequestCard> createState() => _MessageRequestCardState();
}

class _MessageRequestCardState extends State<_MessageRequestCard> {
  late Timer _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.request.expiresAt.difference(now);
    if (mounted) {
      setState(() {
        _remaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  String _formatCountdown() {
    if (_remaining == Duration.zero) return 'Expired';
    if (_remaining.inHours >= 1) {
      final hours = _remaining.inHours;
      final minutes = _remaining.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getCountdownColor(bool isDark) {
    if (_remaining.inHours < 2) {
      return DsColors.warning;
    } else if (_remaining.inHours < 12) {
      return isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    }
    return DsColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final otherName =
        widget.request.otherUserNameFor(widget.currentUserId) ?? 'Unknown';
    final otherPhotoUrl =
        widget.request.otherUserPhotoUrlFor(widget.currentUserId);
    final inbound = widget.request.isInboundFor(widget.currentUserId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = _remaining == Duration.zero;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);

    return AnimatedOpacity(
      opacity: isExpired ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsBlur.light,
            sigmaY: DsBlur.light,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(DsRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(DsSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      baseSurface.withValues(alpha: 0.6),
                      baseSurface.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DsRadius.lg),
                  border: Border.all(
                    color: inbound
                        ? DsColors.primary.withValues(alpha: 0.3)
                        : borderBase,
                    width: inbound ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Avatar with gradient ring for inbound
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: inbound
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: DsGradients.primaryHorizontal,
                                )
                              : null,
                          child: CachedCircleAvatar(
                            imageUrl: otherPhotoUrl,
                            radius: 26,
                          ),
                        ),
                        const SizedBox(width: DsSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      otherName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: DsSpacing.xs),
                                  _DirectionBadge(isInbound: inbound),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Countdown timer
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: _getCountdownColor(isDark),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCountdown(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                      color: _getCountdownColor(isDark),
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.sm),

                    // Message content
                    Container(
                      padding: const EdgeInsets.all(DsSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DsColors.ink900.withValues(alpha: 0.2)
                            : DsColors.surfaceLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(DsRadius.md),
                      ),
                      child: Text(
                        widget.request.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action buttons (only for inbound requests)
                    if (inbound && !isExpired) ...[
                      const SizedBox(height: DsSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              onPressed:
                                  widget.isProcessing ? null : widget.onDecline,
                              icon: Icons.close_rounded,
                              label: 'Decline',
                              isDestructive: true,
                            ),
                          ),
                          const SizedBox(width: DsSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              onPressed:
                                  widget.isProcessing ? null : widget.onAccept,
                              icon: Icons.favorite_rounded,
                              label: 'Accept & Match',
                              isPrimary: true,
                              isLoading: widget.isProcessing,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Sent indicator for outbound
                    if (!inbound) ...[
                      const SizedBox(height: DsSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 14,
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sent • Waiting for response',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isDark
                                      ? DsColors.textMutedDark
                                      : DsColors.textMutedLight,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Direction badge (Received/Sent).
class _DirectionBadge extends StatelessWidget {
  final bool isInbound;

  const _DirectionBadge({required this.isInbound});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: isInbound
            ? LinearGradient(
                colors: [
                  DsColors.primary.withValues(alpha: 0.2),
                  DsColors.secondary.withValues(alpha: 0.15),
                ],
              )
            : null,
        color: isInbound ? null : DsColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInbound ? Icons.inbox_rounded : Icons.outbox_rounded,
            size: 12,
            color: isInbound ? DsColors.primary : DsColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            isInbound ? 'Received' : 'Sent',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isInbound ? DsColors.primary : DsColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Action button for accept/decline.
class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;

    if (isPrimary) {
      backgroundColor = DsColors.primary;
      foregroundColor = DsColors.surfaceLight;
    } else if (isDestructive) {
      backgroundColor = isDark
          ? DsColors.surfaceLight.withValues(alpha: 0.1)
          : DsColors.ink900.withValues(alpha: 0.05);
      foregroundColor =
          isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    } else {
      backgroundColor = isDark
          ? DsColors.surfaceLight.withValues(alpha: 0.1)
          : DsColors.ink900.withValues(alpha: 0.05);
      foregroundColor =
          isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(DsRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(foregroundColor),
                  ),
                )
              else
                Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Match celebration dialog.
class _MatchCelebrationDialog extends StatefulWidget {
  final String userName;

  const _MatchCelebrationDialog({required this.userName});

  @override
  State<_MatchCelebrationDialog> createState() =>
      _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<_MatchCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DsRadius.xl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(DsSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DsColors.primary.withValues(alpha: 0.3),
                          DsColors.secondary.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DsRadius.xl),
                      border: Border.all(
                        color: DsColors.surfaceLight.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heart icon with glow
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: DsGradients.primaryHorizontal,
                            boxShadow: [
                              BoxShadow(
                                color: DsColors.primary.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: DsColors.surfaceLight,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: DsSpacing.lg),
                        ShaderMask(
                          shaderCallback: (bounds) => DsGradients
                              .primaryHorizontal
                              .createShader(bounds),
                          child: Text(
                            "It's a Match!",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: DsColors.surfaceLight,
                                ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          'You and ${widget.userName} liked each other!',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                        ),
                        const SizedBox(height: DsSpacing.xl),
                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: GlassOutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                height: 44,
                                child: const Text('Keep Browsing'),
                              ),
                            ),
                            const SizedBox(width: DsSpacing.sm),
                            Expanded(
                              child: GlassPrimaryButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Navigate to chats
                                  context.go(CrushRoutes.chat);
                                },
                                height: 44,
                                child: const Text('Start Chatting'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
