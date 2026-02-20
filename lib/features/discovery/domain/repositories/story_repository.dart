import 'dart:async';

import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';

abstract class StoryRepository {
  Stream<StoryUpdate> get storyUpdates;

  void initialize();
  void dispose();

  List<ProfileStory> getStoriesForUser(String userId);
  bool hasActiveStories(String userId);
  int getActiveStoryCount(String userId);

  Future<ProfileStory> addStory({
    required String userId,
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? thumbnailUrl,
    Duration? customDuration,
  });

  Future<void> removeStory({required String userId, required String storyId});

  Future<void> viewStory({required String storyId, required String viewerId});

  List<String> getUsersWithActiveStories();
  void forceCleanup();
  void addMockStories();
}
