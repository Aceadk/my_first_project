import 'package:equatable/equatable.dart';

/// Represents an in-app audio or video call between two users.
class Call extends Equatable {
  const Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.duration,
    this.endReason,
    this.callerName,
    this.receiverName,
    this.callerPhotoUrl,
    this.receiverPhotoUrl,
  });

  /// Unique call identifier.
  final String id;

  /// User ID who initiated the call.
  final String callerId;

  /// User ID who received the call.
  final String receiverId;

  /// Type of call (audio or video).
  final CallType type;

  /// Current call status.
  final CallStatus status;

  /// When the call was initiated.
  final DateTime createdAt;

  /// When the call was answered.
  final DateTime? answeredAt;

  /// When the call ended.
  final DateTime? endedAt;

  /// Duration of the call in seconds.
  final int? duration;

  /// Reason the call ended.
  final CallEndReason? endReason;

  /// Caller's display name.
  final String? callerName;

  /// Receiver's display name.
  final String? receiverName;

  /// Caller's photo URL.
  final String? callerPhotoUrl;

  /// Receiver's photo URL.
  final String? receiverPhotoUrl;

  /// Maximum call duration (30 minutes for free, unlimited for premium).
  static const Duration maxFreeDuration = Duration(minutes: 30);

  /// Ring timeout before marking as missed.
  static const Duration ringTimeout = Duration(seconds: 30);

  /// Check if call is active.
  bool get isActive =>
      status == CallStatus.ringing || status == CallStatus.ongoing;

  /// Check if call is a video call.
  bool get isVideo => type == CallType.video;

  /// Get formatted duration string.
  String get durationDisplay {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Call copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    CallType? type,
    CallStatus? status,
    DateTime? createdAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? duration,
    CallEndReason? endReason,
    String? callerName,
    String? receiverName,
    String? callerPhotoUrl,
    String? receiverPhotoUrl,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      endReason: endReason ?? this.endReason,
      callerName: callerName ?? this.callerName,
      receiverName: receiverName ?? this.receiverName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'answeredAt': answeredAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration,
      'endReason': endReason?.name,
      'callerName': callerName,
      'receiverName': receiverName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverPhotoUrl': receiverPhotoUrl,
    };
  }

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      receiverId: json['receiverId'] as String,
      type: CallType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CallStatus.ended,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      duration: json['duration'] as int?,
      endReason: json['endReason'] != null
          ? CallEndReason.values.firstWhere(
              (e) => e.name == json['endReason'],
              orElse: () => CallEndReason.unknown,
            )
          : null,
      callerName: json['callerName'] as String?,
      receiverName: json['receiverName'] as String?,
      callerPhotoUrl: json['callerPhotoUrl'] as String?,
      receiverPhotoUrl: json['receiverPhotoUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    callerId,
    receiverId,
    type,
    status,
    createdAt,
    answeredAt,
    endedAt,
    duration,
    endReason,
    callerName,
    receiverName,
    callerPhotoUrl,
    receiverPhotoUrl,
  ];
}

/// Type of call.
enum CallType { audio, video }

/// Call status states.
enum CallStatus {
  initiating,
  ringing,
  ongoing,
  ended,
  missed,
  declined,
  failed,
}

/// Reasons a call can end.
enum CallEndReason {
  completed,
  missed,
  declined,
  busy,
  noAnswer,
  networkError,
  timeout,
  userHangup,
  unknown,
}

extension CallEndReasonExtension on CallEndReason {
  String get displayText {
    switch (this) {
      case CallEndReason.completed:
        return 'Call ended';
      case CallEndReason.missed:
        return 'Missed call';
      case CallEndReason.declined:
        return 'Call declined';
      case CallEndReason.busy:
        return 'User busy';
      case CallEndReason.noAnswer:
        return 'No answer';
      case CallEndReason.networkError:
        return 'Connection lost';
      case CallEndReason.timeout:
        return 'Call timed out';
      case CallEndReason.userHangup:
        return 'Call ended';
      case CallEndReason.unknown:
        return 'Call ended';
    }
  }
}
