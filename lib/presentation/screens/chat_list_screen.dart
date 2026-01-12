import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/router.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/match.dart';
import '../../data/models/message.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import '../../logic/matches/matches_bloc.dart';
import '../../logic/matches/matches_event.dart';
import '../../logic/matches/matches_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing_widgets.dart';
import '../../shared/widgets/cached_image.dart';
import '../widgets/async_state_scaffold.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in to view your chats.'),
        ),
      );
    }

    return BlocProvider(
      create: (context) => MatchesBloc(
        chatRepository: context.read<ChatRepository>(),
        userId: userId,
      )..add(const MatchesLoadRequested()),
      child: _ChatListView(currentUserId: userId),
    );
  }
}

class _ChatListView extends StatelessWidget {
  final String currentUserId;

  const _ChatListView({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        return AsyncStateScaffold(
          appBar: AppBar(
            title: const Text('Chats'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(CrushRoutes.settings),
              ),
            ],
          ),
          isLoading: state.isLoading && state.matches.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: state.matches.isEmpty
              ? Center(
                  child: Padding(
                    padding: DsEdgeInsets.allXxl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DsColors.secondary.withValues(alpha: 0.1),
                                DsColors.primary.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: DsColors.secondary,
                          ),
                        ),
                        DsGap.xxl,
                        Text(
                          'No conversations yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DsGap.sm,
                        Text(
                          'When you match with someone and start chatting,\nyour conversations will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<MatchesBloc>().add(const MatchesRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: DsEdgeInsets.allLg,
              itemCount: state.matches.length,
              separatorBuilder: (_, __) => DsGap.sm,
              itemBuilder: (context, index) {
                final match = state.matches[index];
                return _ChatTile(
                  match: match,
                  currentUserId: currentUserId,
                  onTap: () {
                    final otherName = match.otherUserName ??
                        (match.otherUserId.trim().isNotEmpty
                            ? match.otherUserId
                            : null) ??
                        'Unknown';

                    // Use go_router for navigation - ChatScreen will create its own ChatBloc
                    context.push(
                      '/chat/${match.id}',
                      extra: ChatScreenArgs(
                        matchId: match.id,
                        currentUserId: currentUserId,
                        otherUserId: match.otherUserId,
                        otherName: otherName,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ChatTile extends StatefulWidget {
  const _ChatTile({
    required this.match,
    required this.currentUserId,
    required this.onTap,
  });

  final CrushMatch match;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile>
    with AutomaticKeepAliveClientMixin {
  Message? _lastMessage;
  int _unreadCount = 0;
  bool _isOnline = false;

  // Properly managed stream subscriptions to prevent memory leaks
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<bool>? _presenceSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
    _subscribeToPresence();
  }

  @override
  void dispose() {
    // Cancel subscriptions to prevent memory leaks
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToMessages() {
    final chatRepo = context.read<ChatRepository>();
    _messagesSubscription = chatRepo.watchMessages(widget.match.id).listen(
      (messages) {
        if (!mounted) return;
        setState(() {
          if (messages.isNotEmpty) {
            // Sort by sentAt to get the most recent
            final sorted = List<Message>.from(messages)
              ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
            _lastMessage = sorted.first;
            // Count unread messages sent to current user
            _unreadCount = messages
                .where((m) =>
                    m.toUserId == widget.currentUserId && !m.isRead)
                .length;
          }
        });
      },
      onError: (_) {
        // Silently handle errors - just show default text
      },
    );
  }

  void _subscribeToPresence() {
    final chatRepo = context.read<ChatRepository>();
    _presenceSubscription = chatRepo.watchPresence(widget.match.otherUserId).listen(
      (isOnline) {
        if (!mounted) return;
        setState(() {
          _isOnline = isOnline;
        });
      },
      onError: (_) {
        // Silently handle errors - default to offline
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final name = widget.match.otherUserName ??
        (widget.match.otherUserId.trim().isNotEmpty
            ? widget.match.otherUserId
            : null) ??
        'Unknown';

    final hasUnread = _unreadCount > 0;
    final lastMessageText = _lastMessage != null
        ? _getMessagePreview(_lastMessage!)
        : 'Tap to start chatting';
    final lastMessageTime = _lastMessage?.sentAt;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: DsEdgeInsets.listItemPadding,
          child: Row(
            children: [
              Stack(
                children: [
                  CachedCircleAvatar(
                    imageUrl: widget.match.otherUserPhotoUrl,
                    radius: 28,
                  ),
                  // Online indicator - only show when user is online
                  if (_isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: DsColors.onlineIndicator,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              DsGap.lgH,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatTime(lastMessageTime),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasUnread
                                  ? DsColors.primary
                                  : DsColors.textMutedLight,
                              fontWeight: hasUnread ? FontWeight.bold : null,
                            ),
                          ),
                      ],
                    ),
                    DsGap.xs,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessageText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasUnread
                                  ? Theme.of(context).textTheme.bodyMedium?.color
                                  : DsColors.textMutedLight,
                              fontWeight: hasUnread ? FontWeight.w600 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DsColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _unreadCount > 99 ? '99+' : '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(Message message) {
    final isMe = message.fromUserId == widget.currentUserId;
    final prefix = isMe ? 'You: ' : '';

    switch (message.type) {
      case MessageType.image:
        return '$prefix Photo';
      case MessageType.video:
        return '$prefix Video';
      case MessageType.voice:
        return '$prefix Voice message';
      case MessageType.text:
        return '$prefix${message.content}';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
