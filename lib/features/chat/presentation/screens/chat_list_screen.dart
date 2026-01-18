import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_state.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/core/services/badge_counter_service.dart';
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

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: DsEdgeInsets.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glass icon container
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
                      color: isDark
                          ? DsGlassColors.borderDark
                          : DsGlassColors.borderLight,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DsColors.secondary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        DsGradients.chats.createShader(bounds),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 52,
                      color: Colors.white,
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
                'No conversations yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
            DsGap.sm,
            Text(
              'When you match with someone and start chatting,\nyour conversations will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  PreferredSizeWidget _buildGlassAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  (isDark
                          ? DsGlassColors.surfaceDark
                          : DsGlassColors.surfaceLight)
                      .withValues(alpha: 0.8),
                  (isDark
                          ? DsGlassColors.surfaceDark
                          : DsGlassColors.surfaceLight)
                      .withValues(alpha: 0.6),
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
                height: kToolbarHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered title
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            DsGradients.chats.createShader(bounds),
                        child: Text(
                          'Chats',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                    // Settings button on the right
                    Positioned(
                      right: DsSpacing.sm,
                      child: GlassIconButton(
                        icon: Icons.settings_outlined,
                        onPressed: () => context.push(CrushRoutes.settings),
                        size: 40,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        return AsyncStateScaffold(
          appBar: _buildGlassAppBar(context),
          isLoading: state.isLoading && state.matches.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: state.matches.isEmpty
              ? _buildEmptyState(context)
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
                        otherPhotoUrl: match.otherUserPhotoUrl,
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
  // Static map to track unread counts across all tiles for badge aggregation
  static final Map<String, int> _unreadCounts = {};

  Message? _lastMessage;
  int _unreadCount = 0;
  bool _isOnline = false;

  // Properly managed stream subscriptions to prevent memory leaks
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<bool>? _presenceSubscription;

  // Store references to avoid context.read() in dispose/async callbacks
  BadgeCounterCubit? _badgeCounterCubit;
  ChatRepository? _chatRepository;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Store references before any async operations
    _badgeCounterCubit = context.read<BadgeCounterCubit>();
    _chatRepository = context.read<ChatRepository>();
    _subscribeToMessages();
    _subscribeToPresence();
  }

  @override
  void dispose() {
    // Remove this match's count and update badge using stored reference
    _unreadCounts.remove(widget.match.id);
    _updateBadgeCounterSafe();
    // Cancel subscriptions to prevent memory leaks
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }

  /// Update badge counter using stored reference (safe for dispose/async)
  void _updateBadgeCounterSafe() {
    final totalUnread = _unreadCounts.values.fold(0, (sum, count) => sum + count);
    _badgeCounterCubit?.updateUnreadChats(totalUnread);
  }

  void _updateBadgeCounter() {
    if (!mounted) return;
    _updateBadgeCounterSafe();
  }

  void _subscribeToMessages() {
    final chatRepo = _chatRepository;
    if (chatRepo == null) return;
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
            // Update static map and badge counter
            _unreadCounts[widget.match.id] = _unreadCount;
            _updateBadgeCounter();
          }
        });
      },
      onError: (_) {
        // Silently handle errors - just show default text
      },
    );
  }

  void _subscribeToPresence() {
    final chatRepo = _chatRepository;
    if (chatRepo == null) return;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
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
                    (isDark
                            ? DsGlassColors.surfaceDark
                            : DsGlassColors.surfaceLight)
                        .withValues(alpha: hasUnread ? 0.7 : 0.5),
                    (isDark
                            ? DsGlassColors.surfaceDark
                            : DsGlassColors.surfaceLight)
                        .withValues(alpha: hasUnread ? 0.5 : 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(DsRadius.lg),
                border: Border.all(
                  color: hasUnread
                      ? DsColors.primary.withValues(alpha: 0.5)
                      : (isDark
                          ? DsGlassColors.borderDark
                          : DsGlassColors.borderLight),
                  width: hasUnread ? 1.5 : 1,
                ),
                boxShadow: hasUnread
                    ? [
                        BoxShadow(
                          color: DsColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? DsGlassColors.borderLight
                                : DsGlassColors.borderDark.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CachedCircleAvatar(
                          imageUrl: widget.match.otherUserPhotoUrl,
                          radius: 28,
                        ),
                      ),
                      // Online indicator with glow effect
                      // Online indicator (green dot)
                      if (_isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: DsColors.onlineIndicator,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      DsColors.onlineIndicator.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Unread message indicator (red dot) - top right
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: hasUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                            ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      hasUnread ? 'New Message' : lastMessageText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                        color: hasUnread
                                            ? Colors.red.shade400
                                            : DsColors.textMutedLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (lastMessageTime != null)
                              Text(
                                _formatTime(lastMessageTime),
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: hasUnread
                                              ? DsColors.primary
                                              : DsColors.textMutedLight,
                                          fontWeight:
                                              hasUnread ? FontWeight.bold : null,
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
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: hasUnread
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                              : DsColors.textMutedLight,
                                          fontWeight:
                                              hasUnread ? FontWeight.w600 : null,
                                        ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(left: DsSpacing.sm),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DsSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: DsGradients.primaryHorizontal,
                                  borderRadius:
                                      BorderRadius.circular(DsRadius.round),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          DsColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
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
