import '../entities/app_notification.dart';

/// Repository interface for in-app notification persistence.
abstract class NotificationRepository {
  /// Fetch notifications for a user, paginated.
  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    int limit = 20,
    DateTime? beforeTimestamp,
  });

  /// Stream of unread notification count for badge display.
  Stream<int> watchUnreadCount(String userId);

  /// Mark a single notification as read.
  Future<void> markAsRead(String userId, String notificationId);

  /// Mark all notifications as read.
  Future<void> markAllAsRead(String userId);
}
