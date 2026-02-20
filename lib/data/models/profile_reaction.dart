import 'package:equatable/equatable.dart';

/// A reaction to a specific piece of content on a profile (photo, prompt, etc.)
/// Sent before matching to express interest in a specific aspect.
class ProfileReaction extends Equatable {
  const ProfileReaction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.contentType,
    required this.contentIndex,
    required this.reactionType,
    required this.createdAt,
    this.comment,
    this.contentPreview,
    this.isRead = false,
  });

  /// Unique identifier for this reaction.
  final String id;

  /// User who sent the reaction.
  final String fromUserId;

  /// User who received the reaction.
  final String toUserId;

  /// Type of content being reacted to.
  final ReactionContentType contentType;

  /// Index of the content (e.g., photo index, prompt index).
  final int contentIndex;

  /// Type of reaction (emoji or comment).
  final String reactionType;

  /// When the reaction was sent.
  final DateTime createdAt;

  /// Optional comment with the reaction.
  final String? comment;

  /// Preview of the content being reacted to (photo URL or prompt text).
  final String? contentPreview;

  /// Whether the receiver has seen this reaction.
  final bool isRead;

  /// Check if this is a comment reaction.
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Get display emoji for reaction type.
  String get emoji {
    return _reactionEmojis[reactionType] ?? '❤️';
  }

  ProfileReaction copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    ReactionContentType? contentType,
    int? contentIndex,
    String? reactionType,
    DateTime? createdAt,
    String? comment,
    String? contentPreview,
    bool? isRead,
  }) {
    return ProfileReaction(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      contentType: contentType ?? this.contentType,
      contentIndex: contentIndex ?? this.contentIndex,
      reactionType: reactionType ?? this.reactionType,
      createdAt: createdAt ?? this.createdAt,
      comment: comment ?? this.comment,
      contentPreview: contentPreview ?? this.contentPreview,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'contentType': contentType.name,
      'contentIndex': contentIndex,
      'reactionType': reactionType,
      'createdAt': createdAt.toIso8601String(),
      'comment': comment,
      'contentPreview': contentPreview,
      'isRead': isRead,
    };
  }

  factory ProfileReaction.fromJson(Map<String, dynamic> json) {
    return ProfileReaction(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      contentType: ReactionContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
        orElse: () => ReactionContentType.photo,
      ),
      contentIndex: json['contentIndex'] as int,
      reactionType: json['reactionType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      comment: json['comment'] as String?,
      contentPreview: json['contentPreview'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fromUserId,
    toUserId,
    contentType,
    contentIndex,
    reactionType,
    createdAt,
    comment,
    contentPreview,
    isRead,
  ];
}

/// Types of content that can receive reactions.
enum ReactionContentType { photo, video, prompt, bio, interest }

/// Available reaction emojis.
const Map<String, String> _reactionEmojis = {
  'like': '❤️',
  'love': '😍',
  'laugh': '😂',
  'wow': '😮',
  'fire': '🔥',
  'smile': '😊',
  'cool': '😎',
  'thinking': '🤔',
  'clap': '👏',
  'wave': '👋',
};

/// Get all available reaction types.
List<String> get availableReactionTypes => _reactionEmojis.keys.toList();

/// Get emoji for a reaction type.
String getReactionEmoji(String type) => _reactionEmojis[type] ?? '❤️';

/// Quick reaction options shown to users.
class QuickReaction {
  const QuickReaction({
    required this.type,
    required this.emoji,
    required this.label,
  });

  final String type;
  final String emoji;
  final String label;

  static const List<QuickReaction> photoReactions = [
    QuickReaction(type: 'like', emoji: '❤️', label: 'Like'),
    QuickReaction(type: 'fire', emoji: '🔥', label: 'Fire'),
    QuickReaction(type: 'love', emoji: '😍', label: 'Love'),
    QuickReaction(type: 'wow', emoji: '😮', label: 'Wow'),
  ];

  static const List<QuickReaction> promptReactions = [
    QuickReaction(type: 'like', emoji: '❤️', label: 'Like'),
    QuickReaction(type: 'laugh', emoji: '😂', label: 'Haha'),
    QuickReaction(type: 'thinking', emoji: '🤔', label: 'Hmm'),
    QuickReaction(type: 'clap', emoji: '👏', label: 'Great'),
  ];
}
