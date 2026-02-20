import 'dart:async';

import 'package:crushhour/data/models/profile_story.dart';
import 'package:uuid/uuid.dart';

/// Service for managing profile stories (24-hour expiring media).
import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';

class StoryService implements StoryRepository {
  StoryService._();

  static final StoryService instance = StoryService._();

  final _uuid = const Uuid();

  /// In-memory storage of stories (in production, this would be backed by Firebase).
  final Map<String, List<ProfileStory>> _userStories = {};

  /// Stream controller for story updates.
  final _storyUpdatesController = StreamController<StoryUpdate>.broadcast();

  /// Stream of story updates.
  @override
  Stream<StoryUpdate> get storyUpdates => _storyUpdatesController.stream;

  /// Timer for cleaning up expired stories.
  Timer? _cleanupTimer;

  /// Initialize the service.
  @override
  void initialize() {
    // Start periodic cleanup of expired stories
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredStories(),
    );
  }

  /// Dispose the service.
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _storyUpdatesController.close();
  }

  /// Get all active stories for a user.
  @override
  List<ProfileStory> getStoriesForUser(String userId) {
    final stories = _userStories[userId] ?? [];
    return stories.where((s) => s.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Check if a user has any active stories.
  @override
  bool hasActiveStories(String userId) {
    return getStoriesForUser(userId).isNotEmpty;
  }

  /// Get the count of active stories for a user.
  @override
  int getActiveStoryCount(String userId) {
    return getStoriesForUser(userId).length;
  }

  /// Add a new story for a user.
  @override
  Future<ProfileStory> addStory({
    required String userId,
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? thumbnailUrl,
    Duration? customDuration,
  }) async {
    final now = DateTime.now();
    final story = ProfileStory(
      id: _uuid.v4(),
      userId: userId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: now,
      expiresAt: customDuration != null ? now.add(customDuration) : null,
      thumbnailUrl: thumbnailUrl,
    );

    _userStories.putIfAbsent(userId, () => []);
    _userStories[userId]!.add(story);

    _storyUpdatesController.add(
      StoryUpdate(type: StoryUpdateType.added, userId: userId, story: story),
    );

    return story;
  }

  /// Remove a story.
  @override
  Future<void> removeStory({
    required String userId,
    required String storyId,
  }) async {
    final stories = _userStories[userId];
    if (stories == null) return;

    final index = stories.indexWhere((s) => s.id == storyId);
    if (index == -1) return;

    final story = stories.removeAt(index);

    _storyUpdatesController.add(
      StoryUpdate(type: StoryUpdateType.removed, userId: userId, story: story),
    );
  }

  /// Mark a story as viewed.
  @override
  Future<void> viewStory({
    required String storyId,
    required String viewerId,
  }) async {
    for (final stories in _userStories.values) {
      final index = stories.indexWhere((s) => s.id == storyId);
      if (index != -1) {
        final story = stories[index];
        stories[index] = story.copyWith(viewCount: story.viewCount + 1);

        _storyUpdatesController.add(
          StoryUpdate(
            type: StoryUpdateType.viewed,
            userId: story.userId,
            story: stories[index],
            viewerId: viewerId,
          ),
        );
        break;
      }
    }
  }

  /// Get all users who have active stories.
  @override
  List<String> getUsersWithActiveStories() {
    return _userStories.entries
        .where((entry) => entry.value.any((s) => s.isActive))
        .map((entry) => entry.key)
        .toList();
  }

  /// Clean up expired stories.
  void _cleanupExpiredStories() {
    final expiredStories = <ProfileStory>[];

    for (final entry in _userStories.entries) {
      final userId = entry.key;
      final stories = entry.value;

      final expired = stories.where((s) => s.isExpired).toList();
      for (final story in expired) {
        stories.remove(story);
        expiredStories.add(story);
        _storyUpdatesController.add(
          StoryUpdate(
            type: StoryUpdateType.expired,
            userId: userId,
            story: story,
          ),
        );
      }
    }

    // Remove users with no stories
    _userStories.removeWhere((_, stories) => stories.isEmpty);
  }

  /// Force cleanup of expired stories (for testing).
  @override
  void forceCleanup() {
    _cleanupExpiredStories();
  }

  /// Add mock stories for testing.
  @override
  void addMockStories() {
    // Add some mock stories for demo purposes
    final mockUsers = ['user1', 'user2', 'user3'];

    for (final userId in mockUsers) {
      addStory(
        userId: userId,
        mediaUrl: 'https://picsum.photos/seed/$userId/400/600',
        mediaType: StoryMediaType.photo,
      );

      // Add a video story for some users
      if (userId == 'user1') {
        addStory(
          userId: userId,
          mediaUrl:
              'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
          mediaType: StoryMediaType.video,
          thumbnailUrl: 'https://picsum.photos/seed/${userId}video/400/600',
        );
      }
    }
  }
}

/// Types of story updates.
enum StoryUpdateType { added, removed, expired, viewed }

/// A story update event.
class StoryUpdate {
  const StoryUpdate({
    required this.type,
    required this.userId,
    required this.story,
    this.viewerId,
  });

  final StoryUpdateType type;
  final String userId;
  final ProfileStory story;
  final String? viewerId;
}
