import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/notifications/domain/entities/app_notification.dart';
import 'package:crushhour/features/notifications/presentation/bloc/notification_center_cubit.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<NotificationCenterCubit>().load(userId);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationCenterCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).notifications),
        actions: [
          BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
            buildWhen: (prev, curr) =>
                prev.notifications.any((n) => !n.isRead) !=
                curr.notifications.any((n) => !n.isRead),
            builder: (context, state) {
              final hasUnread = state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context.read<NotificationCenterCubit>().markAllAsRead();
                },
                child: Text(AppLocalizations.of(context).markAllRead),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child:
                BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    final grouped = _groupNotifications(state.notifications);

                    return RefreshIndicator(
                      onRefresh: context
                          .read<NotificationCenterCubit>()
                          .refresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            grouped.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == grouped.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final item = grouped[index];
                          if (item is _GroupHeader) {
                            return _buildGroupHeader(context, item.label);
                          }
                          return _NotificationTile(
                            notification:
                                (item as _NotificationItem).notification,
                            onTap: () => _onNotificationTap(
                              context,
                              (item).notification,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _onNotificationTap(BuildContext context, AppNotification notification) {
    // Mark as read
    context.read<NotificationCenterCubit>().markAsRead(notification.id);

    // Navigate based on type
    final route = notification.targetRoute;
    if (route != null) {
      context.push(route);
      return;
    }

    // Fallback routing by type
    switch (notification.type) {
      case NotificationType.match:
      case NotificationType.message:
        if (notification.targetId != null) {
          context.push('${CrushRoutes.chat}?matchId=${notification.targetId}');
        }
      case NotificationType.like:
        context.push(CrushRoutes.likesYou);
      case NotificationType.weeklyPicks:
        context.push(CrushRoutes.weeklyPicks);
      case NotificationType.profileView:
      case NotificationType.boostExpired:
      case NotificationType.system:
        break; // No navigation for these types
    }
  }

  /// Group notifications into Today / This Week / Earlier sections.
  List<Object> _groupNotifications(List<AppNotification> notifications) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final today = <AppNotification>[];
    final thisWeek = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in notifications) {
      if (n.createdAt.isAfter(todayStart)) {
        today.add(n);
      } else if (n.createdAt.isAfter(weekStart)) {
        thisWeek.add(n);
      } else {
        earlier.add(n);
      }
    }

    final items = <Object>[];
    if (today.isNotEmpty) {
      items.add(const _GroupHeader('Today'));
      items.addAll(today.map((n) => _NotificationItem(n)));
    }
    if (thisWeek.isNotEmpty) {
      items.add(const _GroupHeader('This Week'));
      items.addAll(thisWeek.map((n) => _NotificationItem(n)));
    }
    if (earlier.isNotEmpty) {
      items.add(const _GroupHeader('Earlier'));
      items.addAll(earlier.map((n) => _NotificationItem(n)));
    }

    return items;
  }
}

class _GroupHeader {
  const _GroupHeader(this.label);
  final String label;
}

class _NotificationItem {
  const _NotificationItem(this.notification);
  final AppNotification notification;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return ListTile(
      onTap: onTap,
      tileColor: isUnread ? DsColors.primary.withValues(alpha: 0.05) : null,
      leading: CircleAvatar(
        backgroundColor: _iconColor.withValues(alpha: 0.15),
        backgroundImage: notification.imageUrl != null
            ? NetworkImage(notification.imageUrl!)
            : null,
        child: notification.imageUrl == null
            ? Icon(_icon, color: _iconColor, size: 20)
            : null,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        notification.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateTimeFormatter.formatRelativeCompact(
              notification.createdAt,
              l10n: context.l10n,
              locale: Localizations.localeOf(context).toString(),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsetsDirectional.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: DsColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.match:
        return Icons.favorite;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.like:
        return Icons.thumb_up;
      case NotificationType.profileView:
        return Icons.visibility;
      case NotificationType.boostExpired:
        return Icons.flash_on;
      case NotificationType.weeklyPicks:
        return Icons.star;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.match:
        return DsColors.primary;
      case NotificationType.message:
        return DsColors.info;
      case NotificationType.like:
        return DsColors.success;
      case NotificationType.profileView:
        return DsColors.warning;
      case NotificationType.boostExpired:
        return DsColors.error;
      case NotificationType.weeklyPicks:
        return DsColors.primary;
      case NotificationType.system:
        return DsColors.info;
    }
  }
}
