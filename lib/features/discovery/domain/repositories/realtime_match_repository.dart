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
    final otherUserId = _coerceString(data['otherUserId'], fallback: '');
    final otherUserName = _coerceString(
      data['otherUserName'],
      fallback: 'Someone',
    );
    final otherUserPhotoUrl = _coerceNullableString(data['otherUserPhotoUrl']);
    final createdAt = _coerceTimestamp(data['createdAt']);

    return RealtimeMatchNotification(
      matchId: matchId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl,
      createdAt: createdAt,
    );
  }

  static String _coerceString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty) return fallback;
    return text;
  }

  static String? _coerceNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static int _coerceTimestamp(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return 0;
      final asInt = int.tryParse(text);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(text);
      if (asDouble != null) return asDouble.round();
    }
    return 0;
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
