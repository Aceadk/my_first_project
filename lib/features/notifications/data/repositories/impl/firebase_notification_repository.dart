import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/features/notifications/domain/entities/app_notification.dart';
import 'package:crushhour/features/notifications/domain/repositories/notification_repository.dart';

/// Firebase Firestore implementation of [NotificationRepository].
///
/// Notifications are stored at `users/{userId}/notifications/{notificationId}`.
class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirebaseNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  @override
  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    int limit = 20,
    DateTime? beforeTimestamp,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection(
        userId,
      ).orderBy('createdAt', descending: true);

      if (beforeTimestamp != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(beforeTimestamp),
        );
      }
      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e, s) {
      AppLogger.error(
        'FirebaseNotificationRepository: fetchNotifications failed',
        error: e,
        stackTrace: s,
      );
      return const [];
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _collection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((Object e, StackTrace s) {
          AppLogger.error(
            'FirebaseNotificationRepository: watchUnreadCount error',
            error: e,
            stackTrace: s,
          );
          return 0;
        });
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _collection(userId).doc(notificationId).update({'isRead': true});
    } catch (e, s) {
      AppLogger.error(
        'FirebaseNotificationRepository: markAsRead failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _collection(
        userId,
      ).where('isRead', isEqualTo: false).get();

      if (unread.docs.isEmpty) return;

      // NOTIF-004: Chunk into batches of 500 (Firestore limit)
      const batchLimit = 500;
      for (var i = 0; i < unread.docs.length; i += batchLimit) {
        final chunk = unread.docs.skip(i).take(batchLimit);
        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e, s) {
      AppLogger.error(
        'FirebaseNotificationRepository: markAllAsRead failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  static AppNotification _fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: _parseType(data['type'] as String? ?? 'system'),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
      targetId: data['targetId'] as String?,
      targetRoute: data['targetRoute'] as String?,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'match':
        return NotificationType.match;
      case 'message':
        return NotificationType.message;
      case 'like':
        return NotificationType.like;
      case 'profile_view':
        return NotificationType.profileView;
      case 'boost_expired':
        return NotificationType.boostExpired;
      case 'weekly_picks':
        return NotificationType.weeklyPicks;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}
