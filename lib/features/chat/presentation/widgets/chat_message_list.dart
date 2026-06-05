import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_failed_message_actions.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';
import 'package:crushhour/presentation/widgets/plus_feature_gate.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/core/security/clipboard_manager.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/features/chat/domain/services/ice_breaker_service.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class ChatMessageList extends StatelessWidget {
  final ChatState state;
  final ScrollController scrollController;
  final String currentUserId;
  final String otherName;
  final String matchId;
  final VoidCallback onRefreshIceBreakers;
  final Function(String) onIceBreakerTap;
  final List<IceBreakerSuggestion> iceBreakerSuggestions;

  const ChatMessageList({
    super.key,
    required this.state,
    required this.scrollController,
    required this.currentUserId,
    required this.otherName,
    required this.matchId,
    required this.onRefreshIceBreakers,
    required this.onIceBreakerTap,
    required this.iceBreakerSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, int> getReactionCounts(Message msg) {
      final counts = <String, int>{};
      for (final emoji in msg.reactions.values) {
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
      return counts;
    }

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    bool shouldShowDateSeparator(List<Message> messages, int index) {
      if (index == 0) return true; // Always show for first message
      final currentDate = messages[index].sentAt;
      final previousDate = messages[index - 1].sentAt;
      return !isSameDay(currentDate, previousDate);
    }

    String formatTime(DateTime time) {
      final locale = Localizations.localeOf(context).toString();
      return DateTimeFormatter.formatTime(time, locale: locale);
    }

    String messageSemanticLabel(Message msg, bool isMe) {
      final sender = isMe ? 'You' : otherName;
      final time = formatTime(msg.sentAt);
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
      return 'Message from $sender: $typeLabel, sent at $time$status';
    }

    String moderationLabel(
      Message msg, {
      required bool isHeld,
      required bool pendingScan,
    }) {
      if (isHeld) {
        return msg.moderationReason ?? 'Message held for review';
      }
      if (pendingScan) return 'Pending safety scan';
      if (msg.isFlagged) return msg.moderationReason ?? 'Flagged for review';
      return 'Safety check';
    }

    Future<void> openUrl(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        showErrorSnackBar(context, 'Could not open attachment.');
      }
    }

    Widget buildMediaErrorPlaceholder(IconData icon, String message) {
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
          border: Border.all(
            color: DsGlassColors.borderFor(context),
            width: 0.5,
          ),
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
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildMessageContent(
      Message msg,
      String textFallback, {
      required bool isHeld,
      required bool pendingScan,
      required bool isMe,
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
      // Responsive media dimensions: 70% on phone, 400px on tablet, 500px on desktop
      final screenWidth = MediaQuery.of(context).size.width;
      final mediaWidth = DsBreakpoints.responsiveValue<double>(
        screenWidth,
        mobile: (screenWidth * 0.7).clamp(160.0, 260.0),
        tablet: 400,
        desktop: 500,
      );
      final mediaHeight = (mediaWidth * 1.18).clamp(180.0, 500.0);

      switch (msg.type) {
        case MessageType.image:
          if (pendingScan) {
            return Text(AppLocalizations.of(context).imagePendingSafetyScan);
          }
          // Check if it's a local file path or a network URL
          final isLocalFile =
              msg.content.startsWith('/') || msg.content.startsWith('file://');
          return Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => isLocalFile ? null : openUrl(msg.content),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DsRadius.media),
                child: isLocalFile
                    ? Image.file(
                        File(msg.content.replaceFirst('file://', '')),
                        width: mediaWidth,
                        height: mediaHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => buildMediaErrorPlaceholder(
                          Icons.broken_image_outlined,
                          'Image unavailable',
                        ),
                      )
                    : CachedImage(
                        imageUrl: msg.content,
                        width: mediaWidth,
                        height: mediaHeight,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(DsRadius.media),
                        errorWidget: buildMediaErrorPlaceholder(
                          Icons.broken_image_outlined,
                          'Image unavailable',
                        ),
                      ),
              ),
            ),
          );
        case MessageType.video:
          final isLocalVideo =
              msg.content.startsWith('/') || msg.content.startsWith('file://');
          return ChatAttachmentTile(
            label: pendingScan ? 'Video (scan pending)' : 'Video',
            url: msg.content,
            icon: Icons.videocam,
            isLocal: isLocalVideo,
          );
        case MessageType.voice:
          final isLocalAudio =
              msg.content.startsWith('/') || msg.content.startsWith('file://');
          if (pendingScan) {
            return ChatAttachmentTile(
              label: 'Voice (scan pending)',
              url: msg.content,
              icon: Icons.mic,
              isLocal: isLocalAudio,
            );
          }
          return VoiceNotePlayer(
            audioUrl: msg.content,
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

    void toggleReaction(Message message, String emoji) {
      final existing = message.reactions[currentUserId];
      final bloc = context.read<ChatBloc>();
      if (existing == emoji) {
        bloc.add(
          ChatReactionRemoved(
            matchId: matchId,
            messageId: message.id,
            userId: currentUserId,
          ),
        );
      } else {
        bloc.add(
          ChatReactionAdded(
            matchId: matchId,
            messageId: message.id,
            userId: currentUserId,
            emoji: emoji,
          ),
        );
      }
    }

    void showEditMessageDialog(Message message) {
      final controller = TextEditingController(text: message.content);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final baseSurface = DsGlassColors.surfaceFor(context);

      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: baseSurface.withValues(alpha: isDark ? 0.95 : 0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.lg),
          ),
          title: Text(AppLocalizations.of(context).editMessage),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Enter new message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DsRadius.md),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DsRadius.md),
                borderSide: const BorderSide(color: DsColors.primary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                final newContent = controller.text.trim();
                if (newContent.isNotEmpty && newContent != message.content) {
                  context.read<ChatBloc>().add(
                    ChatMessageEditRequested(
                      matchId: matchId,
                      messageId: message.id,
                      newContent: newContent,
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: Text(AppLocalizations.of(context).save),
            ),
          ],
        ),
      );
    }

    void showMessageActions({
      required BuildContext context,
      required ChatState state,
      required Message message,
      required bool isMe,
    }) {
      const reactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];
      final myReaction = message.reactions[currentUserId];
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final baseSurface = DsGlassColors.surfaceFor(context);
      final borderBase = DsGlassColors.borderFor(context);

      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DsBlur.heavy,
              sigmaY: DsBlur.heavy,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: baseSurface.withValues(alpha: isDark ? 0.9 : 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: borderBase, width: 0.5),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(
                          top: DsSpacing.md,
                          bottom: DsSpacing.sm,
                        ),
                        width: DsSizes.avatarMd,
                        height: DsSpacing.xs,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.surfaceLight.withValues(alpha: 0.24)
                              : DsColors.ink900.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DsRadius.xxs),
                        ),
                      ),
                    ),
                    // Reaction picker with animation
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DsColors.surfaceLight.withValues(alpha: 0.05)
                            : DsColors.ink900.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(
                          DsRadius.xxl - DsRadius.xs,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: reactions.map((emoji) {
                          final isSelected = myReaction == emoji;
                          return ChatReactionButton(
                            emoji: emoji,
                            isSelected: isSelected,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              toggleReaction(message, emoji);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    if (myReaction != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DsSpacing.lg,
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            toggleReaction(message, myReaction);
                          },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            AppLocalizations.of(context).removeMyReaction,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: DsColors.textMutedLight,
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    if (isMe) ...[
                      // Edit option - only for text messages
                      if (message.type == MessageType.text)
                        PlusFeatureGate(
                          onAllowed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            showEditMessageDialog(message);
                          },
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: Text(AppLocalizations.of(context).editPlus),
                            enabled: !state.isEditInProgress,
                          ),
                        ),
                      PlusFeatureGate(
                        onAllowed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          context.read<ChatBloc>().add(
                            ChatMessageUnsendRequested(matchId, message.id),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(Icons.undo),
                          title: Text(AppLocalizations.of(context).unsendPlus),
                          enabled: !state.isUnsendInProgress,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: Text(AppLocalizations.of(context).deleteForMe),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          context.read<ChatBloc>().add(
                            ChatMessageDeleteForMeRequested(
                              matchId,
                              message.id,
                              currentUserId,
                            ),
                          );
                        },
                      ),
                    ],
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: Text(AppLocalizations.of(context).copyText),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        SecureClipboard.copy(message.content);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              ).messageCopiedWillClearIn,
                            ),
                          ),
                        );
                      },
                    ),
                    DsGap.sm,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final messages = state.allMessages;

    return messages.isEmpty
        ? ChatEmptyState(
            onRefresh: onRefreshIceBreakers,
            suggestions: iceBreakerSuggestions,
            onSuggestionTap: onIceBreakerTap,
            otherName: otherName,
          )
        : ListView.builder(
            controller: scrollController,
            reverse: true,
            padding: const EdgeInsets.all(DsSpacing.md),
            // Add extra item for loading indicator when loading more
            itemCount: messages.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end (top of reversed list)
              if (state.isLoadingMore && index == messages.length) {
                return const _LoadMoreIndicator();
              }
              final msg = messages[messages.length - 1 - index];
              final isMe = msg.fromUserId == currentUserId;
              final isHeld =
                  msg.moderationAction == 'hold' ||
                  msg.moderationStatus == 'held';
              final pendingScan = msg.moderationStatus == 'pending_scan';
              final isFlagged = msg.isFlagged || isHeld;
              final text = msg.isDeletedForSender && isMe
                  ? '(You unsent this message)'
                  : isHeld
                  ? 'Message held for safety review'
                  : msg.content;
              final reactionCounts = getReactionCounts(msg);
              final alignment = isMe
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart;

              // Check if we need a date separator
              final showDateSeparator = shouldShowDateSeparator(
                messages,
                messages.length - 1 - index,
              );

              return Column(
                children: [
                  // Date separator (shown above the message in reversed list)
                  if (showDateSeparator) ChatDateSeparator(date: msg.sentAt),
                  Semantics(
                    label: messageSemanticLabel(msg, isMe),
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
                          button: true,
                          child: GestureDetector(
                            onLongPress: () => showMessageActions(
                              context: context,
                              state: state,
                              message: msg,
                              isMe: isMe,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: DsBlur.subtle,
                                      sigmaY: DsBlur.subtle,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: DsSpacing.xs,
                                        horizontal: DsSpacing.sm,
                                      ),
                                      padding: const EdgeInsets.all(
                                        DsSpacing.sm + DsSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: AlignmentDirectional.topStart,
                                          end: AlignmentDirectional.bottomEnd,
                                          colors: isMe
                                              ? [
                                                  DsColors.primary.withValues(
                                                    alpha: 0.85,
                                                  ),
                                                  DsColors.secondary.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                ]
                                              : [
                                                  DsGlassColors.surfaceFor(
                                                    context,
                                                  ).withValues(alpha: 0.6),
                                                  DsGlassColors.surfaceFor(
                                                    context,
                                                  ).withValues(alpha: 0.4),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          DsRadius.bubble,
                                        ),
                                        border: Border.all(
                                          color: isMe
                                              ? DsColors.primary.withValues(
                                                  alpha: 0.3,
                                                )
                                              : DsGlassColors.borderFor(
                                                  context,
                                                ),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isMe
                                                        ? DsColors.primary
                                                        : DsColors.ink900)
                                                    .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: buildMessageContent(
                                        msg,
                                        text,
                                        isHeld: isHeld,
                                        pendingScan: pendingScan,
                                        isMe: isMe,
                                      ),
                                    ),
                                  ),
                                ),
                                // Message status indicators
                                if (isMe) ...[
                                  if (msg.sendStatus ==
                                      MessageSendStatus.sending)
                                    Padding(
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
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    DsColors.surfaceLight
                                                        .withValues(alpha: 0.5),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: DsSpacing.xs),
                                          Text(
                                            'Sending...',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: DsColors.surfaceLight
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (msg.sendStatus ==
                                      MessageSendStatus.sent)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: DsSpacing.md,
                                        bottom: DsSpacing.xxs,
                                        top: DsSpacing.xxs,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formatTime(msg.sentAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: DsColors.surfaceLight
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(width: DsSpacing.xs),
                                          // Read status - only show "Seen" for Plus users
                                          if (state.canSeeReadReceipts &&
                                              msg.isRead) ...[
                                            const Icon(
                                              Icons.done_all,
                                              size: 14,
                                              color: DsColors.info,
                                            ),
                                            const SizedBox(
                                              width: DsSpacing.xxs,
                                            ),
                                            const Text(
                                              'Seen',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: DsColors.info,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ] else ...[
                                            // Non-Plus users just see single checkmark
                                            Icon(
                                              Icons.done,
                                              size: 14,
                                              color: DsColors.surfaceLight
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                                if (isFlagged || pendingScan)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 12,
                                      end: 12,
                                      bottom: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isHeld
                                              ? Icons.shield
                                              : Icons.shield_outlined,
                                          size: 14,
                                          color: isHeld
                                              ? DsColors.error
                                              : DsColors.warning,
                                        ),
                                        DsGap.xsH,
                                        Flexible(
                                          child: Text(
                                            moderationLabel(
                                              msg,
                                              isHeld: isHeld,
                                              pendingScan: pendingScan,
                                            ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isHeld
                                                  ? DsColors.error
                                                  : DsColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (reactionCounts.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 12,
                                      end: 12,
                                      bottom: 2,
                                    ),
                                    child: Wrap(
                                      spacing: 6,
                                      children: reactionCounts.entries
                                          .map(
                                            (entry) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: DsColors.ink900
                                                    .withValues(alpha: 0.54),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                entry.value > 1
                                                    ? '${entry.key} ${entry.value}'
                                                    : entry.key,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                // Retry / Delete for failed messages. The
                                // "Sending…" state is already rendered by the
                                // status row above, so it is intentionally not
                                // repeated here (was previously duplicated).
                                if (isMe &&
                                    msg.sendStatus == MessageSendStatus.failed)
                                  ChatFailedMessageActions(
                                    onRetry: () {
                                      context.read<ChatBloc>().add(
                                        ChatMessageRetryRequested(
                                          matchId: matchId,
                                          messageId: msg.id,
                                        ),
                                      );
                                    },
                                    onDiscard: () {
                                      context.read<ChatBloc>().add(
                                        ChatMessageDiscardRequested(
                                          messageId: msg.id,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: DsSizes.iconSm,
              height: DsSizes.iconSm,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Text(
              'Loading older messages...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
