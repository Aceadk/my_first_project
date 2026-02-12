import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:crushhour/core/app_logger.dart';

/// Data class for real-time match notification.
class RealtimeMatchNotification {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final int createdAt;

  const RealtimeMatchNotification({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.createdAt,
  });

  factory RealtimeMatchNotification.fromRtdb(
      String matchId, Map<dynamic, dynamic> data) {
    return RealtimeMatchNotification(
      matchId: matchId,
      otherUserId: data['otherUserId'] as String? ?? '',
      otherUserName: data['otherUserName'] as String? ?? 'Someone',
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
      createdAt: data['createdAt'] as int? ?? 0,
    );
  }
}

/// Service for real-time match notifications via Firebase Realtime Database.
///
/// Listens to /users/{userId}/newMatches for instant match notifications.
/// When a match is detected, notifies subscribers and clears the notification.
class RealtimeMatchService {
  static final RealtimeMatchService instance = RealtimeMatchService._();
  RealtimeMatchService._();

  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  StreamSubscription? _matchSubscription;
  String? _currentUserId;

  /// Stream controller for new match notifications.
  final _matchController =
      StreamController<RealtimeMatchNotification>.broadcast();

  /// Stream of new match notifications.
  /// Subscribe to this to receive instant match notifications.
  Stream<RealtimeMatchNotification> get onNewMatch => _matchController.stream;

  /// Start listening for new matches for the given user.
  /// Call this when the user logs in.
  void startListening(String userId) {
    if (_currentUserId == userId && _matchSubscription != null) {
      // Already listening for this user
      return;
    }

    // Stop any existing subscription
    stopListening();

    _currentUserId = userId;

    AppLogger.info(
        '[RealtimeMatchService] Starting match listener for user: $userId');

    // Listen to /users/{userId}/newMatches
    final ref = _rtdb.ref('users/$userId/newMatches');
    _matchSubscription = ref.onChildAdded.listen(
      (event) {
        final matchId = event.snapshot.key;
        final data = event.snapshot.value;

        if (matchId != null && data != null && data is Map) {
          AppLogger.info(
              '[RealtimeMatchService] New match detected: $matchId');

          final notification = RealtimeMatchNotification.fromRtdb(
            matchId,
            data,
          );

          // Emit the notification
          _matchController.add(notification);

          // Clear the notification from RTDB (so it doesn't show again)
          event.snapshot.ref.remove().catchError((e) {
            AppLogger.error(
                '[RealtimeMatchService] Failed to clear match notification', error: e);
          });
        }
      },
      onError: (error) {
        AppLogger.error(
            '[RealtimeMatchService] Match listener error', error: error);
      },
    );
  }

  /// Stop listening for new matches.
  /// Call this when the user logs out.
  void stopListening() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    _currentUserId = null;
    AppLogger.info('[RealtimeMatchService] Stopped match listener');
  }

  /// Dispose the service.
  void dispose() {
    stopListening();
    _matchController.close();
  }
}
