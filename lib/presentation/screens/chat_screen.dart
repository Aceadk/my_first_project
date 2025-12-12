import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/chat/chat_bloc.dart';
import '../../logic/chat/chat_event.dart';
import '../../logic/chat/chat_state.dart';
import '../../data/models/message.dart';
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
                tooltip: 'Audio call',
                icon: const Icon(Icons.call),
                onPressed: _startAudioCall,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Video call',
                icon: const Icon(Icons.videocam),
                onPressed: () {
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
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isMe = msg.fromUserId == widget.args.currentUserId;
                    final text = msg.isDeletedForSender && isMe
                        ? '(You unsent this message)'
                        : msg.content;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                            color:
                                isMe ? Colors.pinkAccent : Colors.grey.shade800,
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
              _buildInput(state),
            ],
          ),
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

  Widget _buildInput(ChatState state) {
    return SafeArea(
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !state.isSending,
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
}
