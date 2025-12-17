import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../logic/chat/chat_bloc.dart';
import '../../logic/chat/chat_event.dart';
import '../../logic/chat/chat_state.dart';
import '../../data/models/message.dart';
import '../../data/models/profile.dart';
import '../../logic/safety/safety_cubit.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../core/profile_completeness.dart';
import '../../core/router.dart';
import '../../data/services/profile_validation_service.dart';
import '../widgets/plus_feature_gate.dart';
import '../widgets/async_state_scaffold.dart';
import '../../core/ui/snackbar_utils.dart';
import 'video_call_screen.dart';
import 'profile_edit_screen.dart';

class ChatScreenArgs {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final String otherName;
  ChatScreenArgs({
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
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
  RemoteProfileCompleteness? _backendCompleteness;
  bool _checkingCompleteness = false;
  String? _completenessError;
  String? _lastProfileSignature;
  bool _backendBlocked = false;
  final ProfileValidationService _validationService =
      ProfileValidationService();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatOpened(
          widget.args.matchId,
          widget.args.currentUserId,
          widget.args.otherUserId,
        ));
  }

  @override
  void dispose() {
    context.read<ChatBloc>().add(
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
            final messages = state.messages;
            final canMessage = completeness.meetsMessagingMinimum &&
                completeness.meetsRequiredFields &&
                backendMessageAllowed &&
                !isBlocked &&
                !state.isUnmatched;
            final isOtherTyping =
                state.typingUserIds.contains(widget.args.otherUserId);

            return AsyncStateScaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.args.otherName),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 9,
                          color: state.otherUserOnline
                              ? Colors.greenAccent
                              : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.otherUserOnline ? 'Online' : 'Offline',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: isBlocked || state.isUnmatched
                        ? 'Unavailable for this match'
                        : 'Audio call',
                    icon: const Icon(Icons.call),
                    onPressed: (isBlocked || state.isUnmatched)
                        ? null
                        : _startAudioCall,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: isBlocked || state.isUnmatched
                        ? 'Unavailable for this match'
                        : 'Video call',
                    icon: const Icon(Icons.videocam),
                    onPressed: (isBlocked || state.isUnmatched)
                        ? null
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
                        child: Text(isBlocked ? 'Unblock user' : 'Block user'),
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
                        child: Text(callsMuted ? 'Unmute calls' : 'Mute calls'),
                      ),
                      const PopupMenuItem(
                        value: _ChatSafetyAction.safetyCenter,
                        child: Text('Open Safety Center'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selfVerified
                                ? 'You are verified. Profiles see your badge as a trust signal.'
                                : 'Verify your ID to add a trust badge to your messages and matches.',
                          ),
                        ),
                        if (!selfVerified)
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, CrushRoutes.safety),
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
                          const SizedBox(width: 8),
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
                          const Icon(Icons.wifi_off, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Internet connection error. Messages may not send.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _refreshChat(context),
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            label: const Text(
                              'Refresh',
                              style: TextStyle(color: Colors.red),
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
                          const SizedBox(width: 8),
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
                          const Icon(Icons.block, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You blocked ${widget.args.otherName}. Unblock to chat or call.',
                              style: const TextStyle(color: Colors.red),
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
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Complete your profile to continue messaging.',
                                  style: TextStyle(color: Colors.orange),
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
                                  style: const TextStyle(color: Colors.orange),
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
                          const Icon(Icons.volume_off, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _muteSummary(
                                messagesMuted: messagesMuted,
                                callsMuted: callsMuted,
                                name: widget.args.otherName,
                              ),
                              style: const TextStyle(color: Colors.orange),
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
                          const SizedBox(width: 8),
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
                        ? _EmptyChatState(onRefresh: () => _refreshChat(context))
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
                              return Align(
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
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.pinkAccent
                                              : Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: _buildMessageContent(
                                          msg,
                                          text,
                                          isHeld: isHeld,
                                          pendingScan: pendingScan,
                                        ),
                                      ),
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
                                              const SizedBox(width: 4),
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
                                    ],
                                  ),
                                ),
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

  void _showMessageActions({
    required BuildContext context,
    required ChatState state,
    required Message message,
    required bool isMe,
  }) {
    const reactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    final myReaction = message.reactions[widget.args.currentUserId];

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: reactions
                    .map(
                      (emoji) => IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleReaction(message, emoji);
                        },
                        icon: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (myReaction != null)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleReaction(message, myReaction);
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Remove my reaction'),
              ),
            if (isMe) ...[
              PlusFeatureGate(
                onAllowed: () {
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
          ],
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

    return SafeArea(
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            tooltip: state.mediaSendingEnabled
                ? 'Disable media for this chat'
                : 'Enable media for this chat',
            icon: Icon(state.mediaSendingEnabled
                ? Icons.photo_camera_back
                : Icons.no_photography),
            onPressed:
                isBlocked || isUnmatched ? null : () => _toggleMedia(state),
          ),
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: canSendMedia
                ? () => _pickAndSendImage(canMessage, completeness)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: canSendMedia
                ? () => _pickAndSendVideo(canMessage, completeness)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: canSendMedia
                ? () => _pickAndSendAudio(canMessage, completeness)
                : null,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: canSendText,
              onChanged: _onTextChanged,
              decoration: const InputDecoration(
                hintText: 'Message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: isSendingText
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
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
                        await _ensureBackendAllowsMessaging(completeness);
                    if (!allowed || !mounted) return;
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
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
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    Message msg,
    String textFallback, {
    required bool isHeld,
    required bool pendingScan,
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
        return GestureDetector(
          onTap: () => _launchUrl(msg.content),
          child: Image.network(
            msg.content,
            width: 220,
            height: 260,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Image unavailable'),
          ),
        );
      case MessageType.video:
        return _AttachmentTile(
          label: pendingScan ? 'Video (scan pending)' : 'Video',
          url: msg.content,
          icon: Icons.videocam,
        );
      case MessageType.voice:
        return _AttachmentTile(
          label: pendingScan ? 'Voice (scan pending)' : 'Voice message',
          url: msg.content,
          icon: Icons.mic,
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
        _backendBlocked =
            e is FirebaseFunctionsException && e.code == 'failed-precondition';
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
      profile.prompts.length,
      profile.bio.hashCode,
      profile.interests.length,
      profile.isVerified,
    ].join('|');
  }

  String _friendlyError(Object error) {
    if (error is FirebaseFunctionsException && error.message != null) {
      return error.message!;
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

  Future<void> _pickAndSendAudio(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      _showMessagingIncomplete(completeness);
      return;
    }
    final allowed = await _ensureBackendAllowsMessaging(completeness);
    if (!allowed || !mounted) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (!mounted || result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    context.read<ChatBloc>().add(
          ChatMediaSendRequested(
            matchId: widget.args.matchId,
            fromUserId: widget.args.currentUserId,
            toUserId: widget.args.otherUserId,
            filePath: path,
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
        Navigator.pushNamed(context, CrushRoutes.safety);
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
                      Navigator.pushNamed(context, CrushRoutes.safetyGuidelines),
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
  });

  final String label;
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launch(context, url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  void _launch(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
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
              const SizedBox(width: 8),
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('$name is typing...'),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('No messages yet. Say hello!'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
