import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../logic/chat/chat_bloc.dart';
import '../../logic/chat/chat_event.dart';
import '../../logic/chat/chat_state.dart';
import '../../data/models/message.dart';
import '../../logic/safety/safety_cubit.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../core/profile_completeness.dart';
import '../widgets/plus_feature_gate.dart';
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
    final userProfile = context.select<ProfileBloc, Profile?>(
      (bloc) => bloc.state.profile ?? bloc.state.user?.profile,
    );
    final completeness = evaluateProfileCompleteness(userProfile);

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
            final canMessage = completeness.meetsMessagingMinimum && !isBlocked;

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
                            child: Text(
                              'Complete your profile to continue messaging. Missing: ${completeness.missing.take(2).join(', ')}',
                              style: const TextStyle(color: Colors.orange),
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
                              child: _buildMessageContent(msg, text),
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
                  _SendStatusBar(state: state),
                  _buildInput(state, isBlocked, canMessage),
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

  Widget _buildInput(ChatState state, bool isBlocked, bool canMessage) {
    final isSendingText = state.sendStatus == SendStatus.sendingText;
    final isUploading = state.sendStatus == SendStatus.uploadingAttachment;
    final inputDisabled =
        isBlocked || isSendingText || isUploading || !canMessage;

    return SafeArea(
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: inputDisabled
                ? null
                : () => _pickAndSendImage(canMessage),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: inputDisabled
                ? null
                : () => _pickAndSendVideo(canMessage),
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: inputDisabled
                ? null
                : () => _pickAndSendAudio(canMessage),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !inputDisabled,
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
                : () {
                    if (isBlocked) {
                      showErrorSnackBar(
                        context,
                        'Unblock ${widget.args.otherName} to send messages.',
                      );
                      return;
                    }
                    if (!canMessage) {
                      showErrorSnackBar(
                        context,
                        'Finish your profile to continue messaging.',
                      );
                      _goToProfileEdit(context);
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

  Widget _buildMessageContent(Message msg, String textFallback) {
    switch (msg.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => _launchUrl(msg.content),
          child: Image.network(
            msg.content,
            width: 220,
            height: 260,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Text('Image unavailable'),
          ),
        );
      case MessageType.video:
        return _AttachmentTile(
          label: 'Video',
          url: msg.content,
          icon: Icons.videocam,
        );
      case MessageType.voice:
        return _AttachmentTile(
          label: 'Voice message',
          url: msg.content,
          icon: Icons.mic,
        );
      case MessageType.text:
        return Text(textFallback);
    }
  }

  Future<void> _pickAndSendImage(bool canMessage) async {
    if (!canMessage) {
      _goToProfileEdit(context);
      return;
    }
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

  Future<void> _pickAndSendVideo(bool canMessage) async {
    if (!canMessage) {
      _goToProfileEdit(context);
      return;
    }
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

  Future<void> _pickAndSendAudio(bool canMessage) async {
    if (!canMessage) {
      _goToProfileEdit(context);
      return;
    }
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

  Future<void> _toggleBlock(
    BuildContext context,
    SafetyCubit cubit, {
    required bool block,
  }) async {
    await cubit.toggleBlock(
      widget.args.otherUserId,
      block: block,
      currentUserId: widget.args.currentUserId,
    );
    final error = cubit.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      showErrorSnackBar(context, error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
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
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (reason == 'Other') {
                      _showCustomReportDialog(context, cubit);
                    } else {
                      await cubit.reportWithContext(
                        reporterId: widget.args.currentUserId,
                        reportedId: widget.args.otherUserId,
                        reason: reason,
                      );
                      final error = cubit.state.errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? 'Report submitted: $reason'
                                : error,
                          ),
                        ),
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
              onPressed: () async {
                final reason = controller.text.trim();
                if (reason.isNotEmpty) {
                  await cubit.reportWithContext(
                    reporterId: widget.args.currentUserId,
                    reportedId: widget.args.otherUserId,
                    reason: reason,
                  );
                  final error = cubit.state.errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error ?? 'Report submitted',
                      ),
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

enum _ChatSafetyAction { report, block, muteMessages, muteCalls }

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
