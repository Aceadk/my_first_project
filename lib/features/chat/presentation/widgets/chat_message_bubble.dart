import 'dart:io';
import 'dart:ui';

import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A single chat message bubble with glass morphism styling.
///
/// Renders the message content (text/image/video/voice), send status indicators,
/// moderation badges, reaction pills, and retry/delete actions for failed messages.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.otherName,
    required this.canSeeReadReceipts,
    required this.onLongPress,
    this.onRetry,
    this.onDiscard,
  });

  final Message message;
  final bool isMe;
  final String currentUserId;
  final String otherName;
  final bool canSeeReadReceipts;
  final VoidCallback onLongPress;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final isHeld =
        message.moderationAction == 'hold' ||
        message.moderationStatus == 'held';
    final pendingScan = message.moderationStatus == 'pending_scan';
    final isFlagged = message.isFlagged || isHeld;
    final text = message.isDeletedForSender && isMe
        ? '(You unsent this message)'
        : isHeld
        ? 'Message held for safety review'
        : message.content;
    final reactionCounts = _reactionCounts(message);
    final alignment = isMe
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;

    return Semantics(
      label: _messageSemanticLabel(message, isMe),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: DsBreakpoints.responsiveValue<double>(
              MediaQuery.of(context).size.width,
              mobile: double.infinity,
              tablet: 480,
              desktop: 480,
            ),
          ),
          child: Semantics(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildBubble(
                    context,
                    text,
                    isHeld: isHeld,
                    pendingScan: pendingScan,
                  ),
                  _buildSendStatus(context),
                  if (isFlagged || pendingScan)
                    _buildModerationBadge(
                      context,
                      isHeld: isHeld,
                      pendingScan: pendingScan,
                    ),
                  if (reactionCounts.isNotEmpty)
                    _buildReactionPills(context, reactionCounts),
                  if (isMe && message.sendStatus == MessageSendStatus.failed)
                    _buildFailedActions(context),
                  if (isMe && message.sendStatus == MessageSendStatus.sending)
                    _buildSendingIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    String text, {
    required bool isHeld,
    required bool pendingScan,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: DsSpacing.xs,
            horizontal: DsSpacing.sm,
          ),
          padding: const EdgeInsets.all(DsSpacing.sm + DsSpacing.xxs),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: isMe
                  ? [
                      DsColors.primary.withValues(alpha: 0.85),
                      DsColors.secondary.withValues(alpha: 0.7),
                    ]
                  : [
                      DsGlassColors.surfaceFor(context).withValues(alpha: 0.6),
                      DsGlassColors.surfaceFor(context).withValues(alpha: 0.4),
                    ],
            ),
            borderRadius: BorderRadius.circular(DsRadius.bubble),
            border: Border.all(
              color: isMe
                  ? DsColors.primary.withValues(alpha: 0.3)
                  : DsGlassColors.borderFor(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMe ? DsColors.primary : DsColors.ink900).withValues(
                  alpha: 0.15,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildMessageContent(
            context,
            text,
            isHeld: isHeld,
            pendingScan: pendingScan,
          ),
        ),
      ),
    );
  }

  Widget _buildSendStatus(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    if (message.sendStatus == MessageSendStatus.sending) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          end: DsSpacing.md,
          bottom: DsSpacing.xxs,
          top: DsSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(
                  DsColors.surfaceLight.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.xs),
            Text(
              'Sending...',
              style: TextStyle(
                fontSize: 10,
                color: DsColors.surfaceLight.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (message.sendStatus == MessageSendStatus.sent) {
      final locale = Localizations.localeOf(context).toString();
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          end: DsSpacing.md,
          bottom: DsSpacing.xxs,
          top: DsSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateTimeFormatter.formatTime(message.sentAt, locale: locale),
              style: TextStyle(
                fontSize: 10,
                color: DsColors.surfaceLight.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: DsSpacing.xs),
            if (canSeeReadReceipts && message.isRead) ...[
              const Icon(Icons.done_all, size: 14, color: DsColors.info),
              const SizedBox(width: DsSpacing.xxs),
              const Text(
                'Seen',
                style: TextStyle(
                  fontSize: 10,
                  color: DsColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Icon(
                Icons.done,
                size: 14,
                color: DsColors.surfaceLight.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildModerationBadge(
    BuildContext context, {
    required bool isHeld,
    required bool pendingScan,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 12, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHeld ? Icons.shield : Icons.shield_outlined,
            size: 14,
            color: isHeld ? DsColors.error : DsColors.warning,
          ),
          DsGap.xsH,
          Flexible(
            child: Text(
              _moderationLabel(
                message,
                isHeld: isHeld,
                pendingScan: pendingScan,
              ),
              style: TextStyle(
                fontSize: 11,
                color: isHeld ? DsColors.error : DsColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionPills(
    BuildContext context,
    Map<String, int> reactionCounts,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 12, bottom: 2),
      child: Wrap(
        spacing: 6,
        children: reactionCounts.entries
            .map(
              (entry) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DsColors.ink900.withValues(alpha: 0.54),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFailedActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 12,
        end: 12,
        bottom: 4,
        top: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 14, color: DsColors.error),
          DsGap.xsH,
          const Text(
            'Failed to send',
            style: TextStyle(fontSize: 11, color: DsColors.error),
          ),
          DsGap.smH,
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  color: DsColors.info,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          DsGap.smH,
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: onDiscard,
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 12,
                  color: DsColors.error,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendingIndicator() {
    return const Padding(
      padding: EdgeInsetsDirectional.only(
        start: 12,
        end: 12,
        bottom: 4,
        top: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: DsSizes.iconXs,
            height: DsSizes.iconXs,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(DsColors.ink300),
            ),
          ),
          SizedBox(width: DsSpacing.xs + DsSpacing.xxs),
          Text(
            'Sending...',
            style: TextStyle(fontSize: 11, color: DsColors.ink300),
          ),
        ],
      ),
    );
  }

  // --- Message content rendering ---

  Widget _buildMessageContent(
    BuildContext context,
    String textFallback, {
    required bool isHeld,
    required bool pendingScan,
  }) {
    if (isHeld) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            size: DsSizes.iconSm,
            color: DsColors.surfaceLight,
          ),
          SizedBox(width: DsSpacing.xs + DsSpacing.xxs),
          Flexible(
            child: Text(
              'Message held for safety review',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // CHAT-UI-003: Cap media at 400px width and 40% of screen height
    final mediaWidth = DsBreakpoints.responsiveValue<double>(
      screenWidth,
      mobile: (screenWidth * 0.7).clamp(160.0, 260.0),
      tablet: 400,
      desktop: 400,
    );
    final maxMediaHeight = screenHeight * 0.4; // 40% of screen height
    final mediaHeight = (mediaWidth * 1.18).clamp(180.0, maxMediaHeight);

    switch (message.type) {
      case MessageType.image:
        if (pendingScan) {
          return Text(AppLocalizations.of(context).imagePendingSafetyScan);
        }
        final isLocalFile =
            message.content.startsWith('/') ||
            message.content.startsWith('file://');
        return Semantics(
          button: true,
          child: GestureDetector(
            onTap: () => isLocalFile ? null : _launchUrl(message.content),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DsRadius.media),
              child: isLocalFile
                  ? Image.file(
                      File(message.content.replaceFirst('file://', '')),
                      width: mediaWidth,
                      height: mediaHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildMediaErrorPlaceholder(
                        context,
                        Icons.broken_image_outlined,
                        'Image unavailable',
                      ),
                    )
                  : CachedImage(
                      imageUrl: message.content,
                      width: mediaWidth,
                      height: mediaHeight,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(DsRadius.media),
                      errorWidget: _buildMediaErrorPlaceholder(
                        context,
                        Icons.broken_image_outlined,
                        'Image unavailable',
                      ),
                    ),
            ),
          ),
        );
      case MessageType.video:
        final isLocalVideo =
            message.content.startsWith('/') ||
            message.content.startsWith('file://');
        return ChatAttachmentTile(
          label: pendingScan ? 'Video (scan pending)' : 'Video',
          url: message.content,
          icon: Icons.videocam,
          isLocal: isLocalVideo,
        );
      case MessageType.voice:
        final isLocalAudio =
            message.content.startsWith('/') ||
            message.content.startsWith('file://');
        if (pendingScan) {
          return ChatAttachmentTile(
            label: 'Voice (scan pending)',
            url: message.content,
            icon: Icons.mic,
            isLocal: isLocalAudio,
          );
        }
        return VoiceNotePlayer(
          audioUrl: message.content,
          isFromCurrentUser: isMe,
          isLocal: isLocalAudio,
          compact: true,
        );
      case MessageType.text:
        return Text(
          textFallback,
          style: isMe ? const TextStyle(color: Colors.white) : null,
        );
    }
  }

  Widget _buildMediaErrorPlaceholder(
    BuildContext context,
    IconData icon,
    String errorMessage,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final sw = MediaQuery.of(context).size.width;
    final placeholderWidth = DsBreakpoints.responsiveValue<double>(
      sw,
      mobile: (sw * 0.7).clamp(160.0, 260.0),
      tablet: 400,
      desktop: 500,
    );
    return Container(
      width: placeholderWidth,
      height: placeholderWidth * 0.6,
      decoration: BoxDecoration(
        color: baseSurface.withValues(alpha: isDark ? 0.6 : 0.8),
        borderRadius: BorderRadius.circular(DsRadius.media),
        border: Border.all(color: DsGlassColors.borderFor(context), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
          DsGap.sm,
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility methods ---

  Map<String, int> _reactionCounts(Message msg) {
    final counts = <String, int>{};
    for (final emoji in msg.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  String _messageSemanticLabel(Message msg, bool isMe) {
    final sender = isMe ? 'You' : otherName;
    final typeLabel = switch (msg.type) {
      MessageType.image => 'Photo',
      MessageType.video => 'Video',
      MessageType.voice => 'Voice note',
      MessageType.text => msg.content,
    };
    final status = switch (msg.sendStatus) {
      MessageSendStatus.sending => ', sending',
      MessageSendStatus.failed => ', failed to send',
      _ => msg.isRead ? ', read' : ', delivered',
    };
    return 'Message from $sender: $typeLabel$status';
  }

  String _moderationLabel(
    Message msg, {
    required bool isHeld,
    required bool pendingScan,
  }) {
    if (isHeld) return msg.moderationReason ?? 'Message held for review';
    if (pendingScan) return 'Pending safety scan';
    if (msg.isFlagged) return msg.moderationReason ?? 'Flagged for review';
    return 'Safety check';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
