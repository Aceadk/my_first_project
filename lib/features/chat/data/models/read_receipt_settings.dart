import 'package:equatable/equatable.dart';

/// Settings for read receipts in chat (premium feature).
class ReadReceiptSettings extends Equatable {
  const ReadReceiptSettings({
    this.sendReadReceipts = true,
    this.showOthersReadReceipts = true,
    this.isPremium = false,
  });

  /// Whether to send read receipts to others when you read their messages.
  final bool sendReadReceipts;

  /// Whether to show read receipts from others (when they read your messages).
  final bool showOthersReadReceipts;

  /// Whether user has premium (required to toggle these settings).
  final bool isPremium;

  /// Check if read receipts are fully enabled.
  bool get isFullyEnabled => sendReadReceipts && showOthersReadReceipts;

  /// Check if user can modify settings.
  bool get canModify => isPremium;

  ReadReceiptSettings copyWith({
    bool? sendReadReceipts,
    bool? showOthersReadReceipts,
    bool? isPremium,
  }) {
    return ReadReceiptSettings(
      sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
      showOthersReadReceipts:
          showOthersReadReceipts ?? this.showOthersReadReceipts,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sendReadReceipts': sendReadReceipts,
      'showOthersReadReceipts': showOthersReadReceipts,
      'isPremium': isPremium,
    };
  }

  factory ReadReceiptSettings.fromJson(Map<String, dynamic> json) {
    return ReadReceiptSettings(
      sendReadReceipts: json['sendReadReceipts'] as bool? ?? true,
      showOthersReadReceipts: json['showOthersReadReceipts'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        sendReadReceipts,
        showOthersReadReceipts,
        isPremium,
      ];
}

/// Read receipt status for a message.
enum ReadReceiptStatus {
  sent,
  delivered,
  read,
}

extension ReadReceiptStatusExtension on ReadReceiptStatus {
  String get icon {
    switch (this) {
      case ReadReceiptStatus.sent:
        return '✓';
      case ReadReceiptStatus.delivered:
        return '✓✓';
      case ReadReceiptStatus.read:
        return '✓✓'; // Shown in blue/accent color
    }
  }
}
