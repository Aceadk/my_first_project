import 'package:equatable/equatable.dart';

/// A temporary story that expires after 24 hours.
/// Stories can be photos or videos that appear on a user's profile.
class ProfileStory extends Equatable {
  const ProfileStory({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    this.expiresAt,
    this.viewCount = 0,
    this.thumbnailUrl,
  });

  /// Unique identifier for the story.
  final String id;

  /// The user who posted the story.
  final String userId;

  /// URL to the media content.
  final String mediaUrl;

  /// Type of media (photo or video).
  final StoryMediaType mediaType;

  /// When the story was created.
  final DateTime createdAt;

  /// When the story expires (default: 24 hours after creation).
  final DateTime? expiresAt;

  /// Number of times this story has been viewed.
  final int viewCount;

  /// Thumbnail URL for video stories.
  final String? thumbnailUrl;

  /// Default story duration (24 hours).
  static const Duration defaultDuration = Duration(hours: 24);

  /// Maximum video duration for stories (15 seconds).
  static const Duration maxVideoDuration = Duration(seconds: 15);

  /// Get the expiration time (defaults to 24h after creation).
  DateTime get expirationTime => expiresAt ?? createdAt.add(defaultDuration);

  /// Check if the story is still active (not expired).
  bool get isActive => DateTime.now().isBefore(expirationTime);

  /// Check if the story has expired.
  bool get isExpired => !isActive;

  /// Get remaining time until expiration.
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expirationTime)) return Duration.zero;
    return expirationTime.difference(now);
  }

  /// Get a human-readable remaining time string.
  String get remainingTimeDisplay {
    final remaining = remainingTime;
    if (remaining == Duration.zero) return 'Expired';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m left';
    } else {
      return 'Less than 1m left';
    }
  }

  /// Check if this is a video story.
  bool get isVideo => mediaType == StoryMediaType.video;

  /// Check if this is a photo story.
  bool get isPhoto => mediaType == StoryMediaType.photo;

  ProfileStory copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    StoryMediaType? mediaType,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    String? thumbnailUrl,
  }) {
    return ProfileStory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'viewCount': viewCount,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory ProfileStory.fromJson(Map<String, dynamic> json) {
    return ProfileStory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      mediaUrl: json['mediaUrl'] as String,
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.name == json['mediaType'],
        orElse: () => StoryMediaType.photo,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      viewCount: json['viewCount'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    mediaUrl,
    mediaType,
    createdAt,
    expiresAt,
    viewCount,
    thumbnailUrl,
  ];
}

/// Type of media in a story.
enum StoryMediaType { photo, video }

/// Extension to get active stories from a list.
extension ProfileStoryListExtension on List<ProfileStory> {
  /// Filter to only active (non-expired) stories.
  List<ProfileStory> get active => where((s) => s.isActive).toList();

  /// Filter to only video stories.
  List<ProfileStory> get videos =>
      where((s) => s.mediaType == StoryMediaType.video).toList();

  /// Filter to only photo stories.
  List<ProfileStory> get photos =>
      where((s) => s.mediaType == StoryMediaType.photo).toList();

  /// Get the most recent story.
  ProfileStory? get mostRecent {
    if (isEmpty) return null;
    final activeStories = active;
    if (activeStories.isEmpty) return null;
    return activeStories.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
  }
}
