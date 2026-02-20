import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/features/notifications/domain/entities/app_notification.dart';
import 'package:crushhour/features/notifications/domain/repositories/notification_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.unreadCount = 0,
    this.errorMessage,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int unreadCount;
  final String? errorMessage;

  NotificationCenterState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationCenterState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    isLoading,
    isLoadingMore,
    hasMore,
    unreadCount,
    errorMessage,
  ];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({required NotificationRepository repository})
    : _repository = repository,
      super(const NotificationCenterState());

  final NotificationRepository _repository;
  StreamSubscription<int>? _unreadSub;
  String? _userId;

  static const int _pageSize = 20;

  /// Load initial notifications and start watching unread count.
  Future<void> load(String userId) async {
    _userId = userId;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final notifications = await _repository.fetchNotifications(
      userId,
      limit: _pageSize,
    );

    emit(
      state.copyWith(
        notifications: notifications,
        isLoading: false,
        hasMore: notifications.length >= _pageSize,
      ),
    );

    // Watch unread count for badge
    _unreadSub?.cancel();
    _unreadSub = _repository
        .watchUnreadCount(userId)
        .listen(
          (count) {
            if (!isClosed) {
              emit(state.copyWith(unreadCount: count));
            }
          },
          onError: (e) {
            AppLogger.error(
              'NotificationCenterCubit: unread count stream error',
              error: e,
            );
          },
        );
  }

  /// Load more (pagination).
  Future<void> loadMore() async {
    if (_userId == null || state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final oldest = state.notifications.isNotEmpty
        ? state.notifications.last.createdAt
        : null;

    final more = await _repository.fetchNotifications(
      _userId!,
      limit: _pageSize,
      beforeTimestamp: oldest,
    );

    emit(
      state.copyWith(
        notifications: [...state.notifications, ...more],
        isLoadingMore: false,
        hasMore: more.length >= _pageSize,
      ),
    );
  }

  /// Pull-to-refresh: reload from the top.
  Future<void> refresh() async {
    if (_userId == null) return;

    final notifications = await _repository.fetchNotifications(
      _userId!,
      limit: _pageSize,
    );

    emit(
      state.copyWith(
        notifications: notifications,
        hasMore: notifications.length >= _pageSize,
      ),
    );
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;

    await _repository.markAsRead(_userId!, notificationId);

    final updated = state.notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();

    emit(state.copyWith(notifications: updated));
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    await _repository.markAllAsRead(_userId!);

    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    emit(state.copyWith(notifications: updated, unreadCount: 0));
  }

  @override
  Future<void> close() {
    _unreadSub?.cancel();
    return super.close();
  }
}
