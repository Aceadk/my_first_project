import 'dart:collection';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/notifications/domain/entities/app_notification.dart';
import 'package:crushhour/features/notifications/domain/repositories/notification_repository.dart';
import 'package:crushhour/features/notifications/presentation/bloc/notification_center_cubit.dart';

void main() {
  group('NotificationCenterState', () {
    test('copyWith updates selected fields and clears error by default', () {
      const base = NotificationCenterState(
        notifications: [],
        isLoading: true,
        errorMessage: 'error',
      );

      final next = base.copyWith(isLoading: false);

      expect(next.isLoading, isFalse);
      expect(next.errorMessage, isNull);
    });
  });

  group('NotificationCenterCubit', () {
    late _FakeNotificationRepository repository;
    late NotificationCenterCubit cubit;

    setUp(() {
      repository = _FakeNotificationRepository();
      cubit = NotificationCenterCubit(repository: repository);
    });

    tearDown(() async {
      await cubit.close();
      await repository.dispose();
    });

    test('load fetches first page and listens to unread count', () async {
      repository.enqueueFetch(_buildNotifications(count: 20));

      await cubit.load('user-1');

      expect(repository.fetchCalls.length, 1);
      expect(repository.fetchCalls.first.userId, 'user-1');
      expect(repository.fetchCalls.first.limit, 20);
      expect(repository.fetchCalls.first.beforeTimestamp, isNull);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.notifications.length, 20);
      expect(cubit.state.hasMore, isTrue);
      expect(repository.unreadController.hasListener, isTrue);

      repository.unreadController.add(4);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.unreadCount, 4);
    });

    test('loadMore appends notifications and updates hasMore', () async {
      final firstPage = _buildNotifications(count: 20);
      final secondPage = _buildNotifications(
        count: 3,
        startIndex: 100,
        startAt: DateTime(2026, 1, 1, 10, 0, 0),
      );
      repository
        ..enqueueFetch(firstPage)
        ..enqueueFetch(secondPage);

      await cubit.load('user-2');
      await cubit.loadMore();

      expect(repository.fetchCalls.length, 2);
      expect(
        repository.fetchCalls[1].beforeTimestamp,
        firstPage.last.createdAt,
      );
      expect(cubit.state.notifications.length, 23);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.isLoadingMore, isFalse);
    });

    test('loadMore is a no-op when user is not loaded', () async {
      await cubit.loadMore();
      expect(repository.fetchCalls, isEmpty);
    });

    test('refresh reloads latest page from top', () async {
      final initial = _buildNotifications(count: 5);
      final refreshed = _buildNotifications(
        count: 2,
        startIndex: 500,
        startAt: DateTime(2026, 2, 1),
      );
      repository
        ..enqueueFetch(initial)
        ..enqueueFetch(refreshed);

      await cubit.load('user-3');
      await cubit.refresh();

      expect(repository.fetchCalls.length, 2);
      expect(repository.fetchCalls[1].beforeTimestamp, isNull);
      expect(cubit.state.notifications, refreshed);
      expect(cubit.state.hasMore, isFalse);
    });

    test('markAsRead updates a single notification and repository', () async {
      repository.enqueueFetch(
        _buildNotifications(
          count: 2,
        ).map((n) => n.copyWith(isRead: false)).toList(),
      );
      await cubit.load('user-4');

      final targetId = cubit.state.notifications.first.id;
      await cubit.markAsRead(targetId);

      expect(repository.markAsReadCalls.length, 1);
      expect(repository.markAsReadCalls.first.userId, 'user-4');
      expect(repository.markAsReadCalls.first.notificationId, targetId);
      expect(
        cubit.state.notifications.firstWhere((n) => n.id == targetId).isRead,
        isTrue,
      );
    });

    test('markAllAsRead updates all notifications and unread count', () async {
      repository.enqueueFetch(
        _buildNotifications(
          count: 3,
        ).map((n) => n.copyWith(isRead: false)).toList(),
      );
      await cubit.load('user-5');

      repository.unreadController.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.unreadCount, 3);

      await cubit.markAllAsRead();

      expect(repository.markAllAsReadCalls, ['user-5']);
      expect(cubit.state.notifications.every((n) => n.isRead), isTrue);
      expect(cubit.state.unreadCount, 0);
    });

    test('close cancels unread subscription', () async {
      repository.enqueueFetch(_buildNotifications(count: 1));
      await cubit.load('user-6');
      expect(repository.unreadController.hasListener, isTrue);

      await cubit.close();
      expect(repository.unreadController.hasListener, isFalse);
    });
  });
}

List<AppNotification> _buildNotifications({
  required int count,
  int startIndex = 0,
  DateTime? startAt,
}) {
  final base = startAt ?? DateTime(2026, 1, 1, 0, 0, 0);
  return List<AppNotification>.generate(count, (i) {
    final idx = startIndex + i;
    return AppNotification(
      id: 'notif-$idx',
      type: NotificationType.message,
      title: 'Title $idx',
      body: 'Body $idx',
      createdAt: base.subtract(Duration(minutes: i)),
      isRead: false,
      targetRoute: '/chat',
      targetId: 'chat-$idx',
    );
  });
}

class _FetchCall {
  _FetchCall({
    required this.userId,
    required this.limit,
    required this.beforeTimestamp,
  });

  final String userId;
  final int limit;
  final DateTime? beforeTimestamp;
}

class _MarkAsReadCall {
  _MarkAsReadCall({required this.userId, required this.notificationId});

  final String userId;
  final String notificationId;
}

class _FakeNotificationRepository implements NotificationRepository {
  final Queue<List<AppNotification>> _fetchQueue =
      Queue<List<AppNotification>>();

  final List<_FetchCall> fetchCalls = <_FetchCall>[];
  final List<_MarkAsReadCall> markAsReadCalls = <_MarkAsReadCall>[];
  final List<String> markAllAsReadCalls = <String>[];
  final StreamController<int> unreadController =
      StreamController<int>.broadcast();

  void enqueueFetch(List<AppNotification> notifications) {
    _fetchQueue.add(notifications);
  }

  Future<void> dispose() async {
    await unreadController.close();
  }

  @override
  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    int limit = 20,
    DateTime? beforeTimestamp,
  }) async {
    fetchCalls.add(
      _FetchCall(
        userId: userId,
        limit: limit,
        beforeTimestamp: beforeTimestamp,
      ),
    );
    if (_fetchQueue.isEmpty) {
      return <AppNotification>[];
    }
    return _fetchQueue.removeFirst();
  }

  @override
  Stream<int> watchUnreadCount(String userId) => unreadController.stream;

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    markAsReadCalls.add(
      _MarkAsReadCall(userId: userId, notificationId: notificationId),
    );
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    markAllAsReadCalls.add(userId);
  }
}
