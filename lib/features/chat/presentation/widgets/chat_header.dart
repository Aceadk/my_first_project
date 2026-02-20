import 'dart:ui';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ChatSafetyAction {
  viewProfile,
  chatSettings,
  report,
  block,
  unmatch,
  muteMessages,
  muteCalls,
  safetyCenter,
}

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatState state;
  final bool isBlocked;
  final bool messagesMuted;
  final bool callsMuted;

  final String otherName;
  final String currentUserId;
  final String otherUserId;
  final String matchId;

  final VoidCallback onNavigateToProfile;
  final VoidCallback onStartAudioCall;
  final Function(ChatSafetyAction) onSafetyAction;

  const ChatHeader({
    super.key,
    required this.state,
    required this.isBlocked,
    required this.messagesMuted,
    required this.callsMuted,
    required this.otherName,
    required this.currentUserId,
    required this.otherUserId,
    required this.matchId,
    required this.onNavigateToProfile,
    required this.onStartAudioCall,
    required this.onSafetyAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final baseSurface = DsGlassColors.surfaceFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 8),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseSurface.withValues(alpha: 0.85),
                  baseSurface.withValues(alpha: 0.7),
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
                height: kToolbarHeight + 8,
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // User avatar with online indicator - tappable to view profile
                    Semantics(
                      button: true,
                      label: 'View $otherName profile',
                      child: GestureDetector(
                        onTap: onNavigateToProfile,
                        child: Stack(
                          children: [
                            Container(
                              width: DsSizes.avatarMd,
                              height: DsSizes.avatarMd,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: state.otherUserOnline
                                      ? DsColors.onlineIndicator
                                      : DsGlassColors.borderFor(context),
                                  width: 2,
                                ),
                                boxShadow: state.otherUserOnline
                                    ? [
                                        BoxShadow(
                                          color: DsColors.onlineIndicator
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ClipOval(
                                child: state.otherUserPhotoUrl != null
                                    ? CachedImage(
                                        imageUrl: state.otherUserPhotoUrl!,
                                        width: DsSizes.buttonHeightSm,
                                        height: DsSizes.buttonHeightSm,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: DsGlassColors.surfaceFor(
                                          context,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 20,
                                          color: isDark
                                              ? DsColors.surfaceLight
                                                    .withValues(alpha: 0.54)
                                              : DsColors.ink900.withValues(
                                                  alpha: 0.38,
                                                ),
                                        ),
                                      ),
                              ),
                            ),
                            if (state.otherUserOnline)
                              PositionedDirectional(
                                end: 0,
                                bottom: 0,
                                child: Container(
                                  width: DsSizes.iconXs,
                                  height: DsSizes.iconXs,
                                  decoration: BoxDecoration(
                                    color: DsColors.onlineIndicator,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? DsColors.ink900
                                          : DsColors.surfaceLight,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DsColors.onlineIndicator
                                            .withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    // User info - tappable to view profile
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'View $otherName profile',
                        child: GestureDetector(
                          onTap: onNavigateToProfile,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      otherName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      state.otherUserOnline
                                          ? 'Online now'
                                          : 'Offline',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: state.otherUserOnline
                                                ? DsColors.onlineIndicator
                                                : DsColors.textMutedLight,
                                            fontWeight: state.otherUserOnline
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Mute indicators
                              if (messagesMuted || callsMuted) ...[
                                const SizedBox(width: DsSpacing.xs),
                                if (messagesMuted)
                                  Container(
                                    padding: const EdgeInsets.all(DsSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: DsColors.warning.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        DsRadius.xs,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_off,
                                      size: 14,
                                      color: DsColors.warning,
                                    ),
                                  ),
                                if (messagesMuted && callsMuted)
                                  const SizedBox(width: DsSpacing.xs),
                                if (callsMuted)
                                  Container(
                                    padding: const EdgeInsets.all(DsSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: DsColors.warning.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        DsRadius.xs,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.call_end,
                                      size: 14,
                                      color: DsColors.warning,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Action buttons
                    Semantics(
                      button: true,
                      label: 'Start voice call',
                      child: GlassIconButton(
                        icon: Icons.call,
                        onPressed: (isBlocked || state.isUnmatched)
                            ? () {}
                            : onStartAudioCall,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Start video call',
                      child: GlassIconButton(
                        icon: Icons.videocam,
                        onPressed: (isBlocked || state.isUnmatched)
                            ? () {}
                            : () {
                                context.push(
                                  CrushRoutes.videoCall,
                                  extra: VideoCallArgs(
                                    currentUserId: currentUserId,
                                    otherUserId: otherUserId,
                                    otherName: otherName,
                                  ),
                                );
                              },
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Date ideas',
                      child: GlassIconButton(
                        icon: Icons.lightbulb_outline,
                        onPressed: () => context.push(
                          CrushRoutes.dateIdeas,
                          extra: {'matchId': matchId},
                        ),
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.quiz_outlined,
                      onPressed: () => context.push(
                        CrushRoutes.compatibilityQuiz,
                        extra: {'matchId': matchId},
                      ),
                      size: 38,
                    ),
                    PopupMenuButton<ChatSafetyAction>(
                      onSelected: onSafetyAction,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: ChatSafetyAction.viewProfile,
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: DsSizes.iconMd),
                              SizedBox(width: DsSpacing.md),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: ChatSafetyAction.chatSettings,
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: DsSizes.iconMd),
                              SizedBox(width: DsSpacing.md),
                              Text('Chat Settings'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: ChatSafetyAction.report,
                          child: Text('Report user'),
                        ),
                        PopupMenuItem(
                          value: ChatSafetyAction.block,
                          child: Text(
                            isBlocked ? 'Unblock user' : 'Block user',
                          ),
                        ),
                        const PopupMenuItem(
                          value: ChatSafetyAction.unmatch,
                          child: Text('Unmatch'),
                        ),
                        PopupMenuItem(
                          value: ChatSafetyAction.muteMessages,
                          child: Text(
                            messagesMuted ? 'Unmute messages' : 'Mute messages',
                          ),
                        ),
                        PopupMenuItem(
                          value: ChatSafetyAction.muteCalls,
                          child: Text(
                            callsMuted ? 'Unmute calls' : 'Mute calls',
                          ),
                        ),
                        const PopupMenuItem(
                          value: ChatSafetyAction.safetyCenter,
                          child: Text('Open Safety Center'),
                        ),
                      ],
                    ),
                    const SizedBox(width: DsSpacing.xs),
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
