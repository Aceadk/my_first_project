import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';

typedef RealtimeChildAddedStreamFactory =
    Stream<RealtimeChildAddedEvent> Function(String path);

class RealtimeChildAddedEvent {
  const RealtimeChildAddedEvent({
    required this.key,
    required this.value,
    required this.remove,
  });

  final String? key;
  final dynamic value;
  final Future<void> Function() remove;
}

/// Service for real-time match notifications via Firebase Realtime Database.
///
/// Listens to /users/{userId}/newMatches for instant match notifications.
/// When a match is detected, notifies subscribers and clears the notification.

class RealtimeMatchService implements RealtimeMatchRepository {
  static final RealtimeMatchService instance = RealtimeMatchService._();
  RealtimeMatchService._({
    RealtimeChildAddedStreamFactory? childAddedStreamFactory,
  }) : _childAddedStreamFactory =
           childAddedStreamFactory ?? _defaultChildAddedStreamFactory;

  @visibleForTesting
  factory RealtimeMatchService.test({
    required RealtimeChildAddedStreamFactory childAddedStreamFactory,
  }) {
    return RealtimeMatchService._(
      childAddedStreamFactory: childAddedStreamFactory,
    );
  }

  static Stream<RealtimeChildAddedEvent> _defaultChildAddedStreamFactory(
    String path,
  ) {
    final ref = FirebaseDatabase.instance.ref(path);
    return ref.onChildAdded.map((event) {
      return RealtimeChildAddedEvent(
        key: event.snapshot.key,
        value: event.snapshot.value,
        remove: () => event.snapshot.ref.remove(),
      );
    });
  }

  final RealtimeChildAddedStreamFactory _childAddedStreamFactory;
  StreamSubscription? _matchSubscription;
  String? _currentUserId;
  bool _isDisposed = false;

  /// Stream controller for new match notifications.
  final _matchController =
      StreamController<RealtimeMatchNotification>.broadcast();

  /// Stream of new match notifications.
  /// Subscribe to this to receive instant match notifications.
  @override
  Stream<RealtimeMatchNotification> get onNewMatch => _matchController.stream;

  @override
  @visibleForTesting
  bool get isListening => _matchSubscription != null;

  @override
  @visibleForTesting
  String? get currentUserId => _currentUserId;

  @override
  @visibleForTesting
  bool get isDisposed => _isDisposed;

  /// Start listening for new matches for the given user.
  /// Call this when the user logs in.
  @override
  void startListening(String userId) {
    if (_isDisposed) {
      AppLogger.warning(
        '[RealtimeMatchService] startListening called after dispose',
        data: {'userId': userId},
      );
      return;
    }

    if (_currentUserId == userId && _matchSubscription != null) {
      // Already listening for this user
      return;
    }

    // Stop any existing subscription
    stopListening();

    _currentUserId = userId;

    AppLogger.info(
      '[RealtimeMatchService] Starting match listener for user: $userId',
    );

    _matchSubscription = _childAddedStreamFactory('users/$userId/newMatches')
        .listen(
          (event) {
            final matchId = event.key;
            final data = event.value;

            if (matchId != null && data != null && data is Map) {
              AppLogger.info(
                '[RealtimeMatchService] New match detected: $matchId',
              );

              final notification = RealtimeMatchNotification.fromRtdb(
                matchId,
                data,
              );

              // Emit the notification
              _matchController.add(notification);

              // Clear the notification from RTDB (so it doesn't show again)
              event.remove().catchError((e) {
                AppLogger.error(
                  '[RealtimeMatchService] Failed to clear match notification',
                  error: e,
                );
              });
            }
          },
          onError: (error) {
            AppLogger.error(
              '[RealtimeMatchService] Match listener error',
              error: error,
            );
          },
        );
  }

  /// Stop listening for new matches.
  /// Call this when the user logs out.
  @override
  void stopListening() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    _currentUserId = null;
    AppLogger.info('[RealtimeMatchService] Stopped match listener');
  }

  /// Dispose the service.
  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    stopListening();
    _matchController.close();
  }
}
