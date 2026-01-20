import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';
import 'package:crushhour/presentation/widgets/plus_feature_gate.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/chat/presentation/widgets/voice_note_player.dart';
import 'package:crushhour/features/chat/presentation/widgets/voice_note_recorder.dart';
import 'package:crushhour/features/chat/data/services/ice_breaker_service.dart';
import 'package:crushhour/core/services/haptic_service.dart';

class ChatScreenArgs {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final String otherName;
  final String? otherPhotoUrl;
  ChatScreenArgs({
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
  });
}

class ChatScreen extends StatefulWidget {
  final ChatScreenArgs args;
  const ChatScreen({super.key, required this.args});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isRecordingVoice = false;
  List<IceBreakerSuggestion> _iceBreakerSuggestions = [];
  RemoteProfileCompleteness? _backendCompleteness;
  bool _checkingCompleteness = false;
  String? _completenessError;
  String? _lastProfileSignature;
  bool _backendBlocked = false;
  final ProfileValidationService _validationService =
      ProfileValidationService();

  // Store reference to ChatBloc to safely use in dispose()
  ChatBloc? _chatBloc;

  @override
  void initState() {
    super.initState();
    _refreshIceBreakers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatBloc = context.read<ChatBloc>();
        _chatBloc?.add(ChatOpened(
              widget.args.matchId,
              widget.args.currentUserId,
              widget.args.otherUserId,
              otherUserPhotoUrl: widget.args.otherPhotoUrl,
            ));
      }
    });
  }

  void _refreshIceBreakers() {
    setState(() {
      _iceBreakerSuggestions = IceBreakerService.getSuggestions(maxCount: 4);
    });
  }

  void _onIceBreakerTap(String text) {
    _controller.text = text;
  }

  @override
  void dispose() {
    // Use stored reference instead of context.read() which is unsafe in dispose
    _chatBloc?.add(
          ChatClosed(widget.args.matchId, widget.args.currentUserId),
        );
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.select<ProfileBloc, Profile?>(
      (bloc) => bloc.state.profile ?? bloc.state.user?.profile,
    );
    final completeness = evaluateProfileCompleteness(userProfile);
    _maybeRefreshBackendCompleteness(userProfile);
    final backendMessageAllowed =
        _backendCompleteness?.allowsMessaging ??
            (_backendBlocked ? false : _completenessError != null);

    return BlocBuilder<SafetyCubit, SafetyState>(
      builder: (context, safetyState) {
        final safety = context.read<SafetyCubit>();
        final isBlocked =
            safetyState.blockedUsers.contains(widget.args.otherUserId);
        final messagesMuted =
            safetyState.mutedMessages.contains(widget.args.otherUserId);
        final callsMuted =
            safetyState.mutedCalls.contains(widget.args.otherUserId);
        final selfVerified = userProfile?.isVerified ?? false;

        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final messages = state.allMessages;
            final canMessage = completeness.meetsMessagingMinimum &&
                completeness.meetsRequiredFields &&
                backendMessageAllowed &&
                !isBlocked &&
                !state.isUnmatched;
            final isOtherTyping =
                state.typingUserIds.contains(widget.args.otherUserId);

            return AsyncStateScaffold(
              appBar: _buildGlassAppBar(
                context,
                state: state,
                isBlocked: isBlocked,
                messagesMuted: messagesMuted,
                callsMuted: callsMuted,
                safety: safety,
              ),
              errorMessage: state.errorMessage,
              showErrorSnackBar: true,
              showBodyOnLoading: true,
              body: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: selfVerified
                        ? Colors.green.withAlpha((0.12 * 255).round())
                        : Colors.orange.withAlpha((0.12 * 255).round()),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          selfVerified
                              ? Icons.verified_user
                              : Icons.privacy_tip_outlined,
                          color: selfVerified ? Colors.green : Colors.orange,
                        ),
                        DsGap.smH,
                        Expanded(
                          child: Text(
                            selfVerified
                                ? 'You are verified. Profiles see your badge as a trust signal.'
                                : 'Verify your ID to add a trust badge to your messages and matches.',
                          ),
                        ),
                        if (!selfVerified)
                          TextButton(
                            onPressed: () => context.push(CrushRoutes.safety),
                            child: const Text('Verify'),
                          ),
                      ],
                    ),
                  ),
                  if (_checkingCompleteness)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'Checking your profile completeness with the server…',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_completenessError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        _completenessError!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.orange),
                      ),
                    ),
                  if (_isNetworkError(state.errorMessage))
                    Container(
                      width: double.infinity,
                      color: Colors.red.withAlpha((0.08 * 255).round()),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: DsColors.error),
                          DsGap.smH,
                          const Expanded(
                            child: Text(
                              'Internet connection error. Messages may not send.',
                              style: TextStyle(color: DsColors.error),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _refreshChat(context),
                            icon: const Icon(Icons.refresh, color: DsColors.error),
                            label: const Text(
                              'Refresh',
                              style: TextStyle(color: DsColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (state.isUnmatched)
                    Container(
                      width: double.infinity,
                      color: Colors.blueGrey.withAlpha((0.12 * 255).round()),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.heart_broken, color: Colors.white70),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'You unmatched with ${widget.args.otherName}. You can still browse history, but messaging is disabled.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isBlocked)
                    Container(
                      width: double.infinity,
                      color: Colors.red.withAlpha((0.1 * 255).round()),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: DsColors.error),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'You blocked ${widget.args.otherName}. Unblock to chat or call.',
                              style: const TextStyle(color: DsColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleBlock(
                              context,
                              safety,
                              block: false,
                            ),
                            child: const Text('Unblock'),
                          ),
                        ],
                      ),
                    )
                  else if (!canMessage)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.withAlpha((0.1 * 255).round()),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: DsColors.warning),
                          DsGap.smH,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Complete your profile to continue messaging.',
                                  style: TextStyle(color: DsColors.warning),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value:
                                      _backendCompleteness?.score ?? completeness.score,
                                  minHeight: 5,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Missing: ${_missingMessages(completeness).take(2).join(', ')}',
                                  style: const TextStyle(color: DsColors.warning),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _goToProfileEdit(context),
                            child: const Text('Finish'),
                          ),
                        ],
                      ),
                    )
                  else if (messagesMuted || callsMuted)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.withAlpha((0.1 * 255).round()),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_off, color: DsColors.warning),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              _muteSummary(
                                messagesMuted: messagesMuted,
                                callsMuted: callsMuted,
                                name: widget.args.otherName,
                              ),
                              style: const TextStyle(color: DsColors.warning),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (messagesMuted) {
                                safety.toggleMuteMessages(
                                  widget.args.otherUserId,
                                  mute: false,
                                );
                              }
                              if (callsMuted) {
                                safety.toggleMuteCalls(
                                  widget.args.otherUserId,
                                  mute: false,
                                );
                              }
                            },
                            child: const Text('Unmute'),
                          ),
                        ],
                      ),
                    ),
                  if (!state.mediaSendingEnabled && !state.isUnmatched)
                    Container(
                      width: double.infinity,
                      color: Colors.blueGrey.withAlpha((0.1 * 255).round()),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.no_photography,
                              color: Colors.white70),
                          DsGap.smH,
                          const Expanded(
                            child: Text(
                              'Media sending is disabled for this match. Enable it from the toolbar to share photos, videos, or audio.',
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleMedia(state),
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: messages.isEmpty
                        ? _EmptyChatState(
                            onRefresh: _refreshIceBreakers,
                            suggestions: _iceBreakerSuggestions,
                            onSuggestionTap: _onIceBreakerTap,
                            otherName: widget.args.otherName,
                          )
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[messages.length - 1 - index];
                              final isMe =
                                  msg.fromUserId == widget.args.currentUserId;
                              final isHeld = msg.moderationAction == 'hold' ||
                                  msg.moderationStatus == 'held';
                              final pendingScan =
                                  msg.moderationStatus == 'pending_scan';
                              final isFlagged = msg.isFlagged || isHeld;
                              final text = msg.isDeletedForSender && isMe
                                  ? '(You unsent this message)'
                                  : isHeld
                                      ? 'Message held for safety review'
                                      : msg.content;
                              final reactionCounts = _reactionCounts(msg);
                              final alignment =
                                  isMe ? Alignment.centerRight : Alignment.centerLeft;

                              // Check if we need a date separator
                              final showDateSeparator = _shouldShowDateSeparator(
                                messages,
                                messages.length - 1 - index,
                              );

                              return Column(
                                children: [
                                  // Date separator (shown above the message in reversed list)
                                  if (showDateSeparator)
                                    _DateSeparator(date: msg.sentAt),
                                  Align(
                                alignment: alignment,
                                child: GestureDetector(
                                  onLongPress: () => _showMessageActions(
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
                                                horizontal: DsSpacing.sm),
                                            padding: const EdgeInsets.all(DsSpacing.sm + 2),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: isMe
                                                    ? [
                                                        DsColors.primary
                                                            .withValues(alpha: 0.85),
                                                        DsColors.secondary
                                                            .withValues(alpha: 0.7),
                                                      ]
                                                    : [
                                                        DsGlassColors.surfaceDark
                                                            .withValues(alpha: 0.6),
                                                        DsGlassColors.surfaceDark
                                                            .withValues(alpha: 0.4),
                                                      ],
                                              ),
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(
                                                color: isMe
                                                    ? DsColors.primary
                                                        .withValues(alpha: 0.3)
                                                    : DsGlassColors.borderLight,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isMe
                                                          ? DsColors.primary
                                                          : Colors.black)
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: _buildMessageContent(
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
                                        if (msg.sendStatus == MessageSendStatus.sending)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                              bottom: 2,
                                              top: 2,
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
                                                      Colors.white.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Sending...',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (msg.sendStatus == MessageSendStatus.sent)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                              bottom: 2,
                                              top: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _formatTime(msg.sentAt),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                // Read status icon
                                                Icon(
                                                  msg.isRead
                                                      ? Icons.done_all
                                                      : Icons.done,
                                                  size: 14,
                                                  color: msg.isRead
                                                      ? Colors.blue
                                                      : Colors.white.withValues(alpha: 0.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                      if (isFlagged || pendingScan)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            right: 12,
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
                                                    ? Colors.redAccent
                                                    : Colors.amber,
                                              ),
                                              DsGap.xsH,
                                              Flexible(
                                                child: Text(
                                                  _moderationLabel(
                                                    msg,
                                                    isHeld: isHeld,
                                                    pendingScan: pendingScan,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isHeld
                                                        ? Colors.redAccent
                                                        : Colors.amber.shade200,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (reactionCounts.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            right: 12,
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
                                                            vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
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
                                      // Retry button for failed messages
                                      if (isMe && msg.sendStatus == MessageSendStatus.failed)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            bottom: 4,
                                            top: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                size: 14,
                                                color: Colors.redAccent,
                                              ),
                                              DsGap.xsH,
                                              const Text(
                                                'Failed to send',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                              DsGap.smH,
                                              GestureDetector(
                                                onTap: () {
                                                  context.read<ChatBloc>().add(
                                                    ChatMessageRetryRequested(
                                                      matchId: widget.args.matchId,
                                                      messageId: msg.id,
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Sending indicator
                                      if (isMe && msg.sendStatus == MessageSendStatus.sending)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            bottom: 4,
                                            top: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation(Colors.grey),
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Sending...',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (state.isUnsendInProgress)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (state.isUnmatching)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  _SendStatusBar(state: state),
                  if (isOtherTyping)
                  _TypingIndicator(name: widget.args.otherName),
                  _buildInput(
                    state,
                    isBlocked: isBlocked,
                    canMessage: canMessage,
                    isUnmatched: state.isUnmatched,
                    completeness: completeness,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildGlassAppBar(
    BuildContext context, {
    required ChatState state,
    required bool isBlocked,
    required bool messagesMuted,
    required bool callsMuted,
    required SafetyCubit safety,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 8),
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
                      .withValues(alpha: 0.85),
                  (isDark
                          ? DsGlassColors.surfaceDark
                          : DsGlassColors.surfaceLight)
                      .withValues(alpha: 0.7),
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
                height: kToolbarHeight + 8,
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // User avatar with online indicator
                    Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: state.otherUserOnline
                                  ? DsColors.onlineIndicator
                                  : (isDark
                                      ? DsGlassColors.borderDark
                                      : DsGlassColors.borderLight),
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
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: isDark
                                        ? DsGlassColors.surfaceDark
                                        : DsGlassColors.surfaceLight,
                                    child: Icon(
                                      Icons.person,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black38,
                                    ),
                                  ),
                          ),
                        ),
                        if (state.otherUserOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: DsColors.onlineIndicator,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.black : Colors.white,
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
                    const SizedBox(width: DsSpacing.sm),
                    // User info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.args.otherName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            state.otherUserOnline ? 'Online now' : 'Offline',
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
                    // Action buttons
                    GlassIconButton(
                      icon: Icons.call,
                      onPressed: (isBlocked || state.isUnmatched)
                          ? () {}
                          : _startAudioCall,
                      size: 38,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.videocam,
                      onPressed: (isBlocked || state.isUnmatched)
                          ? () {}
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VideoCallScreen(
                                    currentUserId: widget.args.currentUserId,
                                    otherUserId: widget.args.otherUserId,
                                    otherName: widget.args.otherName,
                                  ),
                                ),
                              );
                            },
                      size: 38,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.lightbulb_outline,
                      onPressed: () => context.push(
                        CrushRoutes.dateIdeas,
                        extra: {'matchId': widget.args.matchId},
                      ),
                      size: 38,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.quiz_outlined,
                      onPressed: () => context.push(
                        CrushRoutes.compatibilityQuiz,
                        extra: {'matchId': widget.args.matchId},
                      ),
                      size: 38,
                    ),
                    PopupMenuButton<_ChatSafetyAction>(
                      onSelected: (action) => _handleSafetyAction(
                        context,
                        safety,
                        isBlocked: isBlocked,
                        messagesMuted: messagesMuted,
                        callsMuted: callsMuted,
                        action: action,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _ChatSafetyAction.report,
                          child: Text('Report user'),
                        ),
                        PopupMenuItem(
                          value: _ChatSafetyAction.block,
                          child:
                              Text(isBlocked ? 'Unblock user' : 'Block user'),
                        ),
                        const PopupMenuItem(
                          value: _ChatSafetyAction.unmatch,
                          child: Text('Unmatch'),
                        ),
                        PopupMenuItem(
                          value: _ChatSafetyAction.muteMessages,
                          child: Text(messagesMuted
                              ? 'Unmute messages'
                              : 'Mute messages'),
                        ),
                        PopupMenuItem(
                          value: _ChatSafetyAction.muteCalls,
                          child:
                              Text(callsMuted ? 'Unmute calls' : 'Mute calls'),
                        ),
                        const PopupMenuItem(
                          value: _ChatSafetyAction.safetyCenter,
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

  void _showMessageActions({
    required BuildContext context,
    required ChatState state,
    required Message message,
    required bool isMe,
  }) {
    const reactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    final myReaction = message.reactions[widget.args.currentUserId];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? DsGlassColors.surfaceDark.withValues(alpha: 0.9)
                  : DsGlassColors.surfaceLight.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight,
                width: 0.5,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Reaction picker with animation
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: reactions.map((emoji) {
                        final isSelected = myReaction == emoji;
                        return _ReactionButton(
                          emoji: emoji,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            _toggleReaction(message, emoji);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  if (myReaction != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          _toggleReaction(message, myReaction);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Remove my reaction'),
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
                          _showEditMessageDialog(message);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit (Plus)'),
                          enabled: !state.isEditInProgress,
                        ),
                      ),
                    PlusFeatureGate(
                      onAllowed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        context.read<ChatBloc>().add(
                              ChatMessageUnsendRequested(
                                widget.args.matchId,
                                message.id,
                              ),
                            );
                      },
                      child: ListTile(
                        leading: const Icon(Icons.undo),
                        title: const Text('Unsend (Plus)'),
                        enabled: !state.isUnsendInProgress,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Delete for me'),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        context.read<ChatBloc>().add(
                              ChatMessageDeleteForMeRequested(
                                widget.args.matchId,
                                message.id,
                                widget.args.currentUserId,
                              ),
                            );
                      },
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy text'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      Clipboard.setData(
                        ClipboardData(text: message.content),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied'),
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

  void _refreshChat(BuildContext context) {
    context.read<ChatBloc>().add(
          ChatOpened(
            widget.args.matchId,
            widget.args.currentUserId,
            widget.args.otherUserId,
          ),
        );
  }

  void _showEditMessageDialog(Message message) {
    final controller = TextEditingController(text: message.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark
            ? DsGlassColors.surfaceDark.withValues(alpha: 0.95)
            : DsGlassColors.surfaceLight.withValues(alpha: 0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
        title: const Text('Edit message'),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                context.read<ChatBloc>().add(
                      ChatMessageEditRequested(
                        matchId: widget.args.matchId,
                        messageId: message.id,
                        newContent: newContent,
                      ),
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isNetworkError(String? message) {
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('internet connection')
        || lower.contains('network')
        || lower.contains('wifi');
  }

  void _toggleReaction(Message message, String emoji) {
    final existing = message.reactions[widget.args.currentUserId];
    final bloc = context.read<ChatBloc>();
    if (existing == emoji) {
      bloc.add(ChatReactionRemoved(
        matchId: widget.args.matchId,
        messageId: message.id,
        userId: widget.args.currentUserId,
      ));
    } else {
      bloc.add(ChatReactionAdded(
        matchId: widget.args.matchId,
        messageId: message.id,
        userId: widget.args.currentUserId,
        emoji: emoji,
      ));
    }
  }

  Future<void> _startAudioCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start audio call'),
        content: Text('Call ${widget.args.otherName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling ${widget.args.otherName}...')),
      );
    }
  }

  Widget _buildInput(
    ChatState state, {
    required bool isBlocked,
    required bool canMessage,
    required bool isUnmatched,
    required ProfileCompletenessSummary completeness,
  }) {
    final isSendingText = state.sendStatus == SendStatus.sendingText;
    final isUploading = state.sendStatus == SendStatus.uploadingAttachment;
    final canSendText = !isBlocked &&
        !isUnmatched &&
        canMessage &&
        !isSendingText &&
        !isUploading;
    final canSendMedia = state.mediaSendingEnabled &&
        !isBlocked &&
        !isUnmatched &&
        canMessage &&
        !isUploading;

    // Show voice recorder when in recording mode
    if (_isRecordingVoice) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.xs,
          ),
          child: VoiceNoteRecorder(
            onRecordingComplete: (filePath) {
              setState(() => _isRecordingVoice = false);
              _sendVoiceNote(filePath);
            },
            onCancel: () {
              setState(() => _isRecordingVoice = false);
            },
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.medium, sigmaY: DsBlur.medium),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      DsGlassColors.surfaceDark.withValues(alpha: 0.7),
                      DsGlassColors.surfaceDark.withValues(alpha: 0.9),
                    ]
                  : [
                      DsGlassColors.surfaceLight.withValues(alpha: 0.8),
                      DsGlassColors.surfaceLight.withValues(alpha: 0.95),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? DsGlassColors.borderDark
                    : DsGlassColors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.xs,
                vertical: DsSpacing.xs,
              ),
              child: Row(
                children: [
                  // Media action buttons in a glass container
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: state.mediaSendingEnabled
                              ? 'Disable media'
                              : 'Enable media',
                          icon: Icon(
                            state.mediaSendingEnabled
                                ? Icons.photo_camera_back
                                : Icons.no_photography,
                            size: 20,
                          ),
                          onPressed: isBlocked || isUnmatched
                              ? null
                              : () => _toggleMedia(state),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo, size: 20),
                          onPressed: canSendMedia
                              ? () => _pickAndSendImage(canMessage, completeness)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.videocam, size: 20),
                          onPressed: canSendMedia
                              ? () => _pickAndSendVideo(canMessage, completeness)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, size: 20),
                          onPressed: canSendMedia
                              ? () =>
                                  _startVoiceRecording(canMessage, completeness)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  DsGap.smH,
                  // Glass text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? DsGlassColors.borderDark
                              : DsGlassColors.borderLight,
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: canSendText,
                        onChanged: _onTextChanged,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.black38,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DsGap.smH,
                  // Glass send button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DsColors.primary,
                          DsColors.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DsColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: isSendingText
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: isSendingText
                          ? null
                          : () async {
                              if (isBlocked) {
                                showErrorSnackBar(
                                  context,
                                  'Unblock ${widget.args.otherName} to send messages.',
                                );
                                return;
                              }
                              if (isUnmatched) {
                                showErrorSnackBar(
                                  context,
                                  'You unmatched with ${widget.args.otherName}. Messaging is disabled.',
                                );
                                return;
                              }
                              if (!canMessage) {
                                _showMessagingIncomplete(completeness);
                                return;
                              }
                              final allowed =
                                  await _ensureBackendAllowsMessaging(
                                      completeness);
                              if (!allowed || !mounted) return;
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              HapticService.messageSent();
                              context.read<ChatBloc>().add(ChatMessageSent(
                                    matchId: widget.args.matchId,
                                    fromUserId: widget.args.currentUserId,
                                    toUserId: widget.args.otherUserId,
                                    content: text,
                                    type: MessageType.text,
                                  ));
                              _controller.clear();
                              _onTextChanged('');
                            },
                    ),
                  ),
                  DsGap.xsH,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(
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
          Icon(Icons.shield, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Message held for safety review',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }
    switch (msg.type) {
      case MessageType.image:
        if (pendingScan) {
          return const Text('Image pending safety scan…');
        }
        // Check if it's a local file path or a network URL
        final isLocalFile = msg.content.startsWith('/') ||
            msg.content.startsWith('file://');
        return GestureDetector(
          onTap: () => isLocalFile ? null : _launchUrl(msg.content),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isLocalFile
                ? Image.file(
                    File(msg.content.replaceFirst('file://', '')),
                    width: 220,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildMediaErrorPlaceholder(
                      Icons.broken_image_outlined,
                      'Image unavailable',
                    ),
                  )
                : CachedImage(
                    imageUrl: msg.content,
                    width: 220,
                    height: 260,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                    errorWidget: _buildMediaErrorPlaceholder(
                      Icons.broken_image_outlined,
                      'Image unavailable',
                    ),
                  ),
          ),
        );
      case MessageType.video:
        final isLocalVideo = msg.content.startsWith('/') ||
            msg.content.startsWith('file://');
        return _AttachmentTile(
          label: pendingScan ? 'Video (scan pending)' : 'Video',
          url: msg.content,
          icon: Icons.videocam,
          isLocal: isLocalVideo,
        );
      case MessageType.voice:
        final isLocalAudio = msg.content.startsWith('/') ||
            msg.content.startsWith('file://');
        if (pendingScan) {
          return _AttachmentTile(
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
        return Text(textFallback);
    }
  }

  Map<String, int> _reactionCounts(Message msg) {
    final counts = <String, int>{};
    for (final emoji in msg.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  /// Check if we should show a date separator before this message.
  bool _shouldShowDateSeparator(List<Message> messages, int index) {
    if (index == 0) return true; // Always show for first message
    final currentDate = messages[index].sentAt;
    final previousDate = messages[index - 1].sentAt;
    return !_isSameDay(currentDate, previousDate);
  }

  /// Check if two dates are on the same day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Builds a styled error placeholder for media that fails to load.
  Widget _buildMediaErrorPlaceholder(IconData icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 220,
      height: 160,
      decoration: BoxDecoration(
        color: isDark
            ? DsGlassColors.surfaceDark.withValues(alpha: 0.6)
            : DsGlassColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight,
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
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _moderationLabel(
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

  void _toggleMedia(ChatState state) {
    context.read<ChatBloc>().add(
          ChatMediaToggleRequested(
            matchId: widget.args.matchId,
            requesterId: widget.args.currentUserId,
            enabled: !state.mediaSendingEnabled,
          ),
        );
  }

  void _onTextChanged(String value) {
    final shouldType = value.trim().isNotEmpty;
    if (shouldType != _isTyping) {
      _isTyping = shouldType;
      context.read<ChatBloc>().add(
            ChatTypingStatusChanged(
              matchId: widget.args.matchId,
              userId: widget.args.currentUserId,
              isTyping: shouldType,
            ),
          );
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(
              ChatTypingStatusChanged(
                matchId: widget.args.matchId,
                userId: widget.args.currentUserId,
                isTyping: false,
              ),
            );
      }
    });
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

  Future<void> _refreshBackendCompleteness() async {
    setState(() {
      _checkingCompleteness = true;
      _completenessError = null;
    });
    try {
      final result = await _validationService.validate(minimum: 'message');
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

  Future<bool> _ensureBackendAllowsMessaging(
    ProfileCompletenessSummary local,
  ) async {
    if (_backendCompleteness == null && !_checkingCompleteness) {
      await _refreshBackendCompleteness();
      if (!mounted) return false;
    }
    final backend = _backendCompleteness;
    if (backend == null) {
      if (_backendBlocked) {
        if (_completenessError != null) {
          showErrorSnackBar(context, _completenessError!);
        }
        _showMessagingIncomplete(local);
        return false;
      }
      if (_completenessError != null) {
        showErrorSnackBar(
          context,
          'Could not verify profile completeness with the server. Using local checks.',
        );
        return true;
      }
      if (_checkingCompleteness) {
        showErrorSnackBar(
          context,
          'Checking your profile with the server. Try again in a moment.',
        );
      }
      return false;
    }
    if (!backend.allowsMessaging) {
      _showMessagingIncomplete(local);
      return false;
    }
    return true;
  }

  List<String> _missingMessages(ProfileCompletenessSummary local) {
    final remoteMissing = _backendCompleteness?.missingForMessaging;
    if (remoteMissing != null && remoteMissing.isNotEmpty) {
      return remoteMissing;
    }
    if (local.requiredMissing.isNotEmpty) return local.requiredMissing;
    return local.missing;
  }

  void _showMessagingIncomplete(ProfileCompletenessSummary completeness) {
    final missing = _missingMessages(completeness);
    final message = missing.isEmpty
        ? 'Finish your profile to continue messaging.'
        : 'Finish your profile: ${missing.take(3).join(', ')}';
    showErrorSnackBar(context, message);
    _goToProfileEdit(context);
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

  String _friendlyError(Object error) {
    if (error is Exception) {
      return error.toString();
    }
    return 'Could not verify profile completeness. Check your connection.';
  }

  Future<void> _pickAndSendImage(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      _showMessagingIncomplete(completeness);
      return;
    }
    final allowed = await _ensureBackendAllowsMessaging(completeness);
    if (!allowed || !mounted) return;
    final result = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || result == null) return;
    HapticService.messageSent();
    context.read<ChatBloc>().add(
          ChatMediaSendRequested(
            matchId: widget.args.matchId,
            fromUserId: widget.args.currentUserId,
            toUserId: widget.args.otherUserId,
            filePath: result.path,
            type: MessageType.image,
          ),
        );
  }

  Future<void> _pickAndSendVideo(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      _showMessagingIncomplete(completeness);
      return;
    }
    final allowed = await _ensureBackendAllowsMessaging(completeness);
    if (!allowed || !mounted) return;
    final result = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 20),
    );
    if (!mounted || result == null) return;
    HapticService.messageSent();
    context.read<ChatBloc>().add(
          ChatMediaSendRequested(
            matchId: widget.args.matchId,
            fromUserId: widget.args.currentUserId,
            toUserId: widget.args.otherUserId,
            filePath: result.path,
            type: MessageType.video,
          ),
        );
  }

  Future<void> _startVoiceRecording(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      _showMessagingIncomplete(completeness);
      return;
    }
    final allowed = await _ensureBackendAllowsMessaging(completeness);
    if (!allowed || !mounted) return;

    // Enter voice recording mode
    setState(() => _isRecordingVoice = true);
  }

  void _sendVoiceNote(String filePath) {
    HapticService.messageSent();
    context.read<ChatBloc>().add(
          ChatMediaSendRequested(
            matchId: widget.args.matchId,
            fromUserId: widget.args.currentUserId,
            toUserId: widget.args.otherUserId,
            filePath: filePath,
            type: MessageType.voice,
          ),
        );
  }


  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      showErrorSnackBar(context, 'Could not open attachment.');
    }
  }

  String _muteSummary({
    required bool messagesMuted,
    required bool callsMuted,
    required String name,
  }) {
    if (messagesMuted && callsMuted) {
      return 'You muted messages and calls from $name.';
    }
    if (messagesMuted) {
      return 'You muted messages from $name.';
    }
    return 'You muted calls from $name.';
  }

  void _handleSafetyAction(
    BuildContext context,
    SafetyCubit cubit, {
    required bool isBlocked,
    required bool messagesMuted,
    required bool callsMuted,
    required _ChatSafetyAction action,
  }) async {
    switch (action) {
      case _ChatSafetyAction.report:
        _showReportSheet(context, cubit);
        break;
      case _ChatSafetyAction.block:
        await _toggleBlock(context, cubit, block: !isBlocked);
        break;
      case _ChatSafetyAction.unmatch:
        final chatBloc = context.read<ChatBloc>();
        final messenger = ScaffoldMessenger.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Unmatch?'),
            content: Text(
              'This will remove your match with ${widget.args.otherName}. You will not be able to message unless you match again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Unmatch'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          chatBloc.add(
            ChatUnmatchRequested(
              matchId: widget.args.matchId,
              userId: widget.args.currentUserId,
            ),
          );
          messenger.showSnackBar(
            SnackBar(
              content: Text('Unmatching from ${widget.args.otherName}...'),
            ),
          );
        }
        break;
      case _ChatSafetyAction.muteMessages:
        cubit.toggleMuteMessages(
          widget.args.otherUserId,
          mute: !messagesMuted,
        );
        break;
      case _ChatSafetyAction.muteCalls:
        cubit.toggleMuteCalls(
          widget.args.otherUserId,
          mute: !callsMuted,
        );
        break;
      case _ChatSafetyAction.safetyCenter:
        if (!mounted) return;
        context.push(CrushRoutes.safety);
        break;
    }
  }

  Future<void> _toggleBlock(
    BuildContext context,
    SafetyCubit cubit, {
    required bool block,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await cubit.toggleBlock(
      widget.args.otherUserId,
      block: block,
      currentUserId: widget.args.currentUserId,
    );
    if (!context.mounted) return;
    final error = cubit.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          block
              ? 'Blocked ${widget.args.otherName}.'
              : 'Unblocked ${widget.args.otherName}.',
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context, SafetyCubit cubit) {
    const reasons = [
      'Spam or scams',
      'Harassment or hate',
      'Inappropriate content',
      'Fake profile',
      'Other',
    ];

    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Report user',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Reports are anonymous and reviewed by our team. Last match: ${widget.args.matchId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (reason == 'Other') {
                      _showCustomReportDialog(context, cubit);
                    } else {
                      await cubit.reportWithContext(
                        reporterId: widget.args.currentUserId,
                        reportedId: widget.args.otherUserId,
                        reason: reason,
                        matchId: widget.args.matchId,
                        source: 'chat',
                      );
                      if (!mounted) return;
                      final error = cubit.state.errorMessage;
                      messenger.showSnackBar(SnackBar(
                        content: Text(error ?? 'Report submitted: $reason'),
                      ));
                    }
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push(CrushRoutes.safetyGuidelines),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('View community guidelines'),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  void _showCustomReportDialog(BuildContext context, SafetyCubit cubit) {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Report details'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us what happened',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
                  onPressed: () async {
                final details = controller.text.trim();
                if (details.isNotEmpty) {
                  await cubit.reportWithContext(
                    reporterId: widget.args.currentUserId,
                    reportedId: widget.args.otherUserId,
                    reason: 'Other',
                    description: details,
                    matchId: widget.args.matchId,
                    source: 'chat',
                  );
                  if (!mounted) return;
                  final error = cubit.state.errorMessage;
                  messenger.showSnackBar(
                    SnackBar(content: Text(error ?? 'Report submitted')),
                  );
                }
                navigator.pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _goToProfileEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.label,
    required this.url,
    required this.icon,
    this.isLocal = false,
  });

  final String label;
  final String url;
  final IconData icon;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launch(context, url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            DsGap.xsH,
            Text(
              label,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.white,
              ),
            ),
            if (isLocal) ...[
              DsGap.xsH,
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
            ],
          ],
        ),
      ),
    );
  }

  void _launch(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);

    // For local files, show a message that it's stored locally
    if (isLocal) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Media saved locally on your device.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    final can = await canLaunchUrl(uri);
    if (can) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open attachment.')),
      );
    }
  }
}

enum _ChatSafetyAction {
  report,
  block,
  unmatch,
  muteMessages,
  muteCalls,
  safetyCenter
}

/// Date separator widget for chat messages.
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.white24 : Colors.black12),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DsRadius.round),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md,
                    vertical: DsSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(DsRadius.round),
                    border: Border.all(
                      color: isDark
                          ? DsGlassColors.borderDark
                          : DsGlassColors.borderLight,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? Colors.white24 : Colors.black12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendStatusBar extends StatelessWidget {
  const _SendStatusBar({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    switch (state.sendStatus) {
      case SendStatus.uploadingAttachment:
        return Container(
          width: double.infinity,
          color: Colors.blueGrey.withAlpha((0.08 * 255).round()),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              DsGap.smH,
              Expanded(
                child: Text(
                  'Uploading ${state.uploadingAttachmentName ?? 'attachment'}…',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      case SendStatus.sendingText:
        return const SizedBox(height: 4);
      case SendStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.name});

  final String name;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations with staggered delays
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Animated dots container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? DsGlassColors.surfaceDark.withValues(alpha: 0.6)
                  : DsGlassColors.surfaceLight.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? DsGlassColors.borderDark
                    : DsGlassColors.borderLight,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  AnimatedBuilder(
                    animation: _animations[i],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -4 * _animations[i].value),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DsColors.primary.withValues(
                              alpha: 0.5 + (_animations[i].value * 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (i < 2) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          DsGap.smH,
          Text(
            '${widget.name} is typing',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.onRefresh,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.otherName,
  });

  final VoidCallback onRefresh;
  final List<IceBreakerSuggestion> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsGap.xxl,
          // Match icon with glass effect
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: DsBlur.medium, sigmaY: DsBlur.medium),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DsColors.primary.withValues(alpha: 0.25),
                      DsColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? DsGlassColors.borderDark
                        : DsGlassColors.borderLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DsColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      DsGradients.primaryHorizontal.createShader(bounds),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          DsGap.lg,
          ShaderMask(
            shaderCallback: (bounds) =>
                DsGradients.primaryHorizontal.createShader(bounds),
            child: Text(
              'You matched with $otherName!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          DsGap.sm,
          Text(
            'Break the ice with a great opener',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.xl,
          // Ice breaker suggestions
          if (suggestions.isNotEmpty) ...[
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      DsGradients.primaryHorizontal.createShader(bounds),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Suggested openers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  ),
                ),
              ],
            ),
            DsGap.md,
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.sm),
              child: _IceBreakerTile(
                suggestion: suggestion,
                onTap: () => onSuggestionTap(suggestion.text),
              ),
            )),
          ],
          DsGap.lg,
          // Glass refresh button
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? DsGlassColors.borderDark
                        : DsGlassColors.borderLight,
                    width: 0.5,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Show different suggestions'),
                  style: TextButton.styleFrom(
                    foregroundColor: DsColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single ice breaker suggestion tile with glass effect.
class _IceBreakerTile extends StatelessWidget {
  const _IceBreakerTile({
    required this.suggestion,
    required this.onTap,
  });

  final IceBreakerSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DsRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(DsSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          DsGlassColors.surfaceDark.withValues(alpha: 0.6),
                          DsGlassColors.surfaceDark.withValues(alpha: 0.4),
                        ]
                      : [
                          DsGlassColors.surfaceLight.withValues(alpha: 0.7),
                          DsGlassColors.surfaceLight.withValues(alpha: 0.5),
                        ],
                ),
                borderRadius: BorderRadius.circular(DsRadius.lg),
                border: Border.all(
                  color: isDark
                      ? DsGlassColors.borderDark
                      : DsGlassColors.borderLight,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DsColors.primary.withValues(alpha: 0.15),
                          DsColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DsRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        suggestion.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Text(
                      suggestion.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: DsGradients.primaryHorizontal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DsColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated reaction button with scale effect on tap
class _ReactionButton extends StatefulWidget {
  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: widget.isSelected
                  ? BoxDecoration(
                      color: DsColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                widget.emoji,
                style: TextStyle(
                  fontSize: widget.isSelected ? 28 : 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
