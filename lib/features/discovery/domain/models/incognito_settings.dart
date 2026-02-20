import 'package:equatable/equatable.dart';

/// Settings for incognito/browse mode where user can view profiles without being seen.
class IncognitoSettings extends Equatable {
  const IncognitoSettings({
    this.isEnabled = false,
    this.enabledAt,
    this.expiresAt,
    this.hideFromLikedYou = true,
    this.hideLastActive = true,
    this.hideReadReceipts = true,
    this.onlyShowToLiked = false,
  });

  /// Whether incognito mode is currently active.
  final bool isEnabled;

  /// When incognito mode was enabled.
  final DateTime? enabledAt;

  /// When incognito mode expires (premium feature with time limit for free users).
  final DateTime? expiresAt;

  /// Hide from "Who Liked You" section for other users.
  final bool hideFromLikedYou;

  /// Hide last active time from profile.
  final bool hideLastActive;

  /// Hide read receipts in chat.
  final bool hideReadReceipts;

  /// Only show profile to people you've already liked.
  final bool onlyShowToLiked;

  /// Duration of incognito for free users (1 hour).
  static const Duration freeDuration = Duration(hours: 1);

  /// Check if incognito has expired.
  bool get isExpired {
    if (!isEnabled) return true;
    if (expiresAt == null) return false; // Premium - no expiry
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if currently active (enabled and not expired).
  bool get isActive => isEnabled && !isExpired;

  /// Get remaining time.
  Duration get remainingTime {
    if (!isEnabled || expiresAt == null) return Duration.zero;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get formatted remaining time string.
  String get remainingTimeDisplay {
    final remaining = remainingTime;
    if (remaining == Duration.zero) return 'Expired';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  IncognitoSettings copyWith({
    bool? isEnabled,
    DateTime? enabledAt,
    DateTime? expiresAt,
    bool? hideFromLikedYou,
    bool? hideLastActive,
    bool? hideReadReceipts,
    bool? onlyShowToLiked,
  }) {
    return IncognitoSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      enabledAt: enabledAt ?? this.enabledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hideFromLikedYou: hideFromLikedYou ?? this.hideFromLikedYou,
      hideLastActive: hideLastActive ?? this.hideLastActive,
      hideReadReceipts: hideReadReceipts ?? this.hideReadReceipts,
      onlyShowToLiked: onlyShowToLiked ?? this.onlyShowToLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'enabledAt': enabledAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'hideFromLikedYou': hideFromLikedYou,
      'hideLastActive': hideLastActive,
      'hideReadReceipts': hideReadReceipts,
      'onlyShowToLiked': onlyShowToLiked,
    };
  }

  factory IncognitoSettings.fromJson(Map<String, dynamic> json) {
    return IncognitoSettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      enabledAt: json['enabledAt'] != null
          ? DateTime.parse(json['enabledAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      hideFromLikedYou: json['hideFromLikedYou'] as bool? ?? true,
      hideLastActive: json['hideLastActive'] as bool? ?? true,
      hideReadReceipts: json['hideReadReceipts'] as bool? ?? true,
      onlyShowToLiked: json['onlyShowToLiked'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isEnabled,
    enabledAt,
    expiresAt,
    hideFromLikedYou,
    hideLastActive,
    hideReadReceipts,
    onlyShowToLiked,
  ];
}
