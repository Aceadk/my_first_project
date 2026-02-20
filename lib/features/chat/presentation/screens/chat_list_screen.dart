import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_state.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_cubit.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
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
    final userId = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your chats.')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MatchesBloc(
            chatRepository: context.read<ChatRepository>(),
            authRepository: context.read<AuthRepository>(),
            userId: userId,
          )..add(const MatchesLoadRequested()),
        ),
        BlocProvider(
          create: (context) => MessageRequestsCubit(
            chatRepository: context.read<ChatRepository>(),
            discoveryRepository: context.read<DiscoveryRepository>(),
            userId: userId,
          )..load(),
        ),
      ],
      child: _ChatListView(currentUserId: userId),
    );
  }
}

class _ChatListView extends StatefulWidget {
  final String currentUserId;

  const _ChatListView({required this.currentUserId});

  @override
  State<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<_ChatListView> {
  /// Currently selected match for iPad split-view (null = no selection).
  ChatScreenArgs? _selectedChat;

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
                      color: DsGlassColors.borderFor(context),
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
                      color: DsColors.surfaceLight,
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
                  color: DsColors.surfaceLight,
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
    final baseSurface = DsGlassColors.surfaceFor(context);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseSurface.withValues(alpha: 0.8),
                  baseSurface.withValues(alpha: 0.6),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DsColors.surfaceLight,
                              ),
                        ),
                      ),
                    ),
                    // Settings button on the right
                    PositionedDirectional(
                      end: DsSpacing.sm,
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

  ChatScreenArgs _argsForMatch(CrushMatch match) {
    final otherName =
        match.otherUserName ??
        (match.otherUserId.trim().isNotEmpty ? match.otherUserId : null) ??
        'Unknown';
    return ChatScreenArgs(
      matchId: match.id,
      currentUserId: widget.currentUserId,
      otherUserId: match.otherUserId,
      otherName: otherName,
      otherPhotoUrl: match.otherUserPhotoUrl,
    );
  }

  void _onChatTileTap(BuildContext context, CrushMatch match) {
    final screenWidth = MediaQuery.of(context).size.width;
    final args = _argsForMatch(match);

    if (DsBreakpoints.isMobile(screenWidth)) {
      // Phone: push navigation
      context.push('/chat/${match.id}', extra: args);
    } else {
      // iPad/tablet: update detail panel
      setState(() => _selectedChat = args);
    }
  }

  Widget _buildChatList(BuildContext context, MatchesState state) {
    final requestState = context.watch<MessageRequestsCubit>().state;
    final requestsCount = requestState.requests.length;
    final showSkeleton =
        (state.isLoading || state.errorMessage != null) &&
        state.matches.isEmpty;

    return AsyncStateScaffold(
      appBar: _buildGlassAppBar(context),
      isLoading: showSkeleton,
      errorMessage: null,
      showErrorSnackBar: false,
      empty:
          state.matches.isEmpty && requestsCount == 0 && !requestState.isLoading
          ? _buildEmptyState(context)
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<MatchesBloc>().add(const MatchesRefreshRequested());
          context.read<MessageRequestsCubit>().refresh();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.separated(
          padding: DsEdgeInsets.allLg,
          itemCount: state.matches.length + 1,
          separatorBuilder: (_, _) => DsGap.sm,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _MessageRequestsTile(
                count: requestsCount,
                isLoading: requestState.isLoading,
                onTap: () => context.push(CrushRoutes.messageRequests),
              );
            }

            final match = state.matches[index - 1];
            return _ChatTile(
              match: match,
              currentUserId: widget.currentUserId,
              onTap: () => _onChatTileTap(context, match),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Phone: single column (existing behavior)
            if (DsBreakpoints.isMobile(constraints.maxWidth)) {
              return _buildChatList(context, state);
            }

            // iPad/tablet: split-view — conversation list (320px) + chat detail
            return Row(
              children: [
                SizedBox(width: 320, child: _buildChatList(context, state)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedChat != null
                      ? ChatScreen(
                          key: ValueKey(_selectedChat!.matchId),
                          args: _selectedChat!,
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color: DsColors.textMutedLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              DsGap.lg,
                              Text(
                                'Select a conversation',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: DsColors.textMutedLight),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MessageRequestsTile extends StatelessWidget {
  const _MessageRequestsTile({
    required this.count,
    required this.isLoading,
    required this.onTap,
  });

  final int count;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
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
                  colors: [
                    baseSurface.withValues(alpha: 0.6),
                    baseSurface.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(DsRadius.lg),
                border: Border.all(color: borderBase, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: DsGradients.primaryHorizontal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: DsColors.surfaceLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Text(
                      'Message Requests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DsColors.primary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
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
    final totalUnread = _unreadCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    _badgeCounterCubit?.updateUnreadChats(totalUnread);
  }

  void _updateBadgeCounter() {
    if (!mounted) return;
    _updateBadgeCounterSafe();
  }

  void _subscribeToMessages() {
    final chatRepo = _chatRepository;
    if (chatRepo == null) return;
    _messagesSubscription = chatRepo
        .watchMessages(widget.match.id)
        .listen(
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
                    .where(
                      (m) => m.toUserId == widget.currentUserId && !m.isRead,
                    )
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
    _presenceSubscription = chatRepo
        .watchPresence(widget.match.otherUserId)
        .listen(
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

    final name =
        widget.match.otherUserName ??
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
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
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
                    baseSurface.withValues(alpha: hasUnread ? 0.7 : 0.5),
                    baseSurface.withValues(alpha: hasUnread ? 0.5 : 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(DsRadius.lg),
                border: Border.all(
                  color: hasUnread
                      ? DsColors.primary.withValues(alpha: 0.5)
                      : borderBase,
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
                            color: borderBase.withValues(
                              alpha: isDark ? 1.0 : 0.3,
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DsColors.ink900.withValues(alpha: 0.1),
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
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
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
                                  color: DsColors.onlineIndicator.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Unread message indicator (red dot) - top right
                      if (hasUnread)
                        PositionedDirectional(
                          end: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: DsColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? DsColors.ink900
                                    : DsColors.surfaceLight,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DsColors.error.withValues(alpha: 0.5),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      top: 2,
                                    ),
                                    child: Text(
                                      hasUnread
                                          ? 'New Message'
                                          : lastMessageText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: hasUnread
                                            ? DsColors.error
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
                                DateTimeFormatter.formatRelativeCompact(
                                  lastMessageTime,
                                  l10n: context.l10n,
                                  locale: Localizations.localeOf(
                                    context,
                                  ).toString(),
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: hasUnread
                                          ? DsColors.primary
                                          : DsColors.textMutedLight,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : null,
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: hasUnread
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color
                                          : DsColors.textMutedLight,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : null,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsetsDirectional.only(
                                  start: DsSpacing.sm,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DsSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: DsGradients.primaryHorizontal,
                                  borderRadius: BorderRadius.circular(
                                    DsRadius.round,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DsColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                                  style: const TextStyle(
                                    color: DsColors.surfaceLight,
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
}
