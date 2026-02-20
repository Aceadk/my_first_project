import 'package:equatable/equatable.dart';

/// Message retention duration options
enum MessageRetention {
  /// Messages deleted 1 hour after being read (default for free users)
  oneHour,

  /// Messages deleted 24 hours after being read (opt-in for free users)
  twentyFourHours,

  /// Messages deleted 7 days after being read (Plus users only)
  oneWeek,
}

/// Chat settings that control message behavior and retention.
class ChatSettings extends Equatable {
  /// Whether to keep messages for 24 hours instead of 1 hour.
  /// Default is false (1 hour retention).
  /// Plus users can keep for up to 7 days regardless of this setting.
  final bool extendedRetention;

  /// Computed retention duration based on settings.
  /// Note: For Plus users, this is overridden to 7 days on the backend.
  MessageRetention get retentionDuration => extendedRetention
      ? MessageRetention.twentyFourHours
      : MessageRetention.oneHour;

  /// Get the retention hours based on settings.
  /// Free users: 1 hour (default) or 24 hours (if extended enabled)
  /// Plus users: 168 hours (7 days) - handled on backend
  int get retentionHours => extendedRetention ? 24 : 1;

  const ChatSettings({this.extendedRetention = false});

  /// Create settings with default 1-hour retention
  factory ChatSettings.defaultSettings() {
    return const ChatSettings(extendedRetention: false);
  }

  /// Create settings with 24-hour retention
  factory ChatSettings.extended() {
    return const ChatSettings(extendedRetention: true);
  }

  ChatSettings copyWith({bool? extendedRetention}) {
    return ChatSettings(
      extendedRetention: extendedRetention ?? this.extendedRetention,
    );
  }

  Map<String, dynamic> toJson() {
    return {'extendedRetention': extendedRetention};
  }

  factory ChatSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChatSettings();
    return ChatSettings(
      extendedRetention: json['extendedRetention'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [extendedRetention];
}
