import 'dart:async';

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
    String matchId,
    Map<dynamic, dynamic> data,
  ) {
    return RealtimeMatchNotification(
      matchId: matchId,
      otherUserId: data['otherUserId'] as String? ?? '',
      otherUserName: data['otherUserName'] as String? ?? 'Someone',
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
      createdAt: data['createdAt'] as int? ?? 0,
    );
  }
}

abstract class RealtimeMatchRepository {
  Stream<RealtimeMatchNotification> get onNewMatch;
  bool get isListening;
  String? get currentUserId;
  bool get isDisposed;

  void startListening(String userId);
  void stopListening();
  void dispose();
}
