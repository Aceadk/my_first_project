import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';
import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _clearStories(StoryService service) async {
  service.forceCleanup();
  final users = List<String>.from(service.getUsersWithActiveStories());
  for (final userId in users) {
    final stories = List<ProfileStory>.from(service.getStoriesForUser(userId));
    for (final story in stories) {
      await service.removeStory(userId: userId, storyId: story.id);
    }
  }
  service.forceCleanup();
}

void main() {
  final service = StoryService.instance;

  setUp(() async {
    await _clearStories(service);
  });

  tearDown(() async {
    await _clearStories(service);
  });

  group('StoryService', () {
    test(
      'add/view/remove flow emits update events and tracks counts',
      () async {
        final updates = <StoryUpdate>[];
        final sub = service.storyUpdates.listen(updates.add);

        final story = await service.addStory(
          userId: 'user_a',
          mediaUrl: 'https://example.com/a.jpg',
          mediaType: StoryMediaType.photo,
        );

        await service.viewStory(storyId: story.id, viewerId: 'viewer_1');
        await service.removeStory(userId: 'user_a', storyId: story.id);

        expect(service.hasActiveStories('user_a'), isFalse);
        expect(service.getActiveStoryCount('user_a'), 0);
        expect(
          updates.map((u) => u.type),
          containsAllInOrder([
            StoryUpdateType.added,
            StoryUpdateType.viewed,
            StoryUpdateType.removed,
          ]),
        );

        final viewed = updates.firstWhere(
          (u) => u.type == StoryUpdateType.viewed,
        );
        expect(viewed.viewerId, 'viewer_1');
        expect(viewed.story.viewCount, 1);

        await sub.cancel();
      },
    );

    test(
      'returns stories sorted newest-first and extension getters work',
      () async {
        final older = await service.addStory(
          userId: 'user_b',
          mediaUrl: 'https://example.com/old.jpg',
          mediaType: StoryMediaType.photo,
        );
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final newer = await service.addStory(
          userId: 'user_b',
          mediaUrl: 'https://example.com/new.jpg',
          mediaType: StoryMediaType.video,
          thumbnailUrl: 'https://example.com/new-thumb.jpg',
        );

        final stories = service.getStoriesForUser('user_b');
        expect(stories.length, 2);
        expect(stories.first.id, newer.id);
        expect(stories.last.id, older.id);
        expect(service.hasActiveStories('user_b'), isTrue);
        expect(service.getActiveStoryCount('user_b'), 2);
        expect(stories.map((s) => s.id), containsAll([older.id, newer.id]));
      },
    );

    test('forceCleanup removes expired stories and empty users', () async {
      await service.addStory(
        userId: 'expired_user',
        mediaUrl: 'https://example.com/expired.jpg',
        mediaType: StoryMediaType.photo,
        customDuration: const Duration(milliseconds: -1),
      );
      await service.addStory(
        userId: 'active_user',
        mediaUrl: 'https://example.com/active.jpg',
        mediaType: StoryMediaType.photo,
        customDuration: const Duration(hours: 1),
      );

      service.forceCleanup();

      final users = service.getUsersWithActiveStories();
      expect(users, contains('active_user'));
      expect(users, isNot(contains('expired_user')));
    });

    test('addMockStories seeds demo data with active stories', () {
      service.addMockStories();

      final users = service.getUsersWithActiveStories();
      expect(users, containsAll(['user1', 'user2', 'user3']));
      expect(service.getActiveStoryCount('user1'), greaterThanOrEqualTo(2));
    });
  });
}
