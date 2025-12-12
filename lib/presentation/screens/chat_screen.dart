import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/chat/chat_bloc.dart';
import '../../logic/chat/chat_event.dart';
import '../../logic/chat/chat_state.dart';
import '../../data/models/message.dart';
import '../../logic/safety/safety_cubit.dart';
import '../widgets/plus_feature_gate.dart';
import '../../core/ui/snackbar_utils.dart';
import 'video_call_screen.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatOpened(
          widget.args.matchId,
          widget.args.currentUserId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SafetyCubit, SafetyState>(
      builder: (context, safetyState) {
        final safety = context.read<SafetyCubit>();
        final isBlocked =
            safetyState.blockedUsers.contains(widget.args.otherUserId);
        final messagesMuted =
            safetyState.mutedMessages.contains(widget.args.otherUserId);
        final callsMuted =
            safetyState.mutedCalls.contains(widget.args.otherUserId);

        return BlocConsumer<ChatBloc, ChatState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            final messages = state.messages;

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.args.otherName),
                actions: [
                  IconButton(
                    tooltip:
                        isBlocked ? 'Unblock to call' : 'Audio call',
                    icon: const Icon(Icons.call),
                    onPressed: isBlocked ? null : _startAudioCall,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip:
                        isBlocked ? 'Unblock to call' : 'Video call',
                    icon: const Icon(Icons.videocam),
                    onPressed: isBlocked
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
                        child:
                            Text(isBlocked ? 'Unblock user' : 'Block user'),
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
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Column(
                children: [
                  if (isBlocked)
                    Container(
                      width: double.infinity,
                      color: Colors.red.withOpacity(0.1),
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
                            onPressed: () {
                              safety.toggleBlock(
                                widget.args.otherUserId,
                                block: false,
                              );
                            },
                            child: const Text('Unblock'),
                          ),
                        ],
                      ),
                    )
                  else if (messagesMuted || callsMuted)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.withOpacity(0.1),
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
                              style:
                                  const TextStyle(color: Colors.orange),
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
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        final isMe =
                            msg.fromUserId == widget.args.currentUserId;
                        final text =
                            msg.isDeletedForSender && isMe
                                ? '(You unsent this message)'
                                : msg.content;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: isMe
                                ? () => _showMessageActions(
                                      context: context,
                                      state: state,
                                      message: msg,
                                    )
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.pinkAccent
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(text),
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
                  _buildInput(state, isBlocked),
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
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  Widget _buildInput(ChatState state, bool isBlocked) {
    return SafeArea(
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !state.isSending && !isBlocked,
              decoration: const InputDecoration(
                hintText: 'Message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: state.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: state.isSending
                ? null
                : () {
                    if (isBlocked) {
                      showErrorSnackBar(
                        context,
                        'Unblock ${widget.args.otherName} to send messages.',
                      );
                      return;
                    }
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
                  },
          ),
        ],
      ),
    );
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
  }) {
    switch (action) {
      case _ChatSafetyAction.report:
        _showReportSheet(context, cubit);
        break;
      case _ChatSafetyAction.block:
        cubit.toggleBlock(
          widget.args.otherUserId,
          block: !isBlocked,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBlocked
                  ? 'Unblocked ${widget.args.otherName}.'
                  : 'Blocked ${widget.args.otherName}.',
            ),
          ),
        );
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
    }
  }

  void _showReportSheet(BuildContext context, SafetyCubit cubit) {
    const reasons = [
      'Spam or scams',
      'Harassment or hate',
      'Inappropriate content',
      'Fake profile',
      'Other',
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Report user',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Choose a reason. Serious issues will be reviewed.',
                ),
              ),
              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (reason == 'Other') {
                      _showCustomReportDialog(context, cubit);
                    } else {
                      cubit.reportUser(widget.args.otherUserId, reason);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report submitted: $reason')),
                      );
                    }
                  },
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isNotEmpty) {
                  cubit.reportUser(widget.args.otherUserId, reason);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted'),
                    ),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

enum _ChatSafetyAction { report, block, muteMessages, muteCalls }
