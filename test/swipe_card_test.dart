import 'package:crushhour/data/models/profile_story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';
import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';
import 'package:crushhour/features/discovery/presentation/widgets/swipe_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _prefs = DiscoveryPreferences(
  minAge: 18,
  maxAge: 30,
  maxDistanceKm: 50,
  showMeGenders: ['female', 'male'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'NYC',
);

void main() {
  final storyRepository = _EmptyStoryRepository();

  testWidgets('SwipeCard shows verified badge', (tester) async {
    const profile = Profile(
      id: 'p1',
      name: 'Alex',
      age: 25,
      gender: 'other',
      sexualOrientation: null,
      bio: 'Hello',
      photoUrls: [],
      videoUrls: [],
      isVerified: true,
      jobTitle: 'Engineer',
      company: 'Acme',
      school: 'State U',
      interests: ['music'],
      country: 'US',
      city: 'NYC',
      latitude: null,
      longitude: null,
      preferences: _prefs,
    );

    await tester.pumpWidget(
      RepositoryProvider<StoryRepository>.value(
        value: storyRepository,
        child: const MaterialApp(
          home: SwipeCard(profile: profile),
        ),
      ),
    );

    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('SwipeCard shows fallbacks when data is missing', (tester) async {
    const profile = Profile(
      id: 'p2',
      name: '',
      age: 0,
      gender: 'other',
      sexualOrientation: null,
      bio: '',
      photoUrls: [],
      videoUrls: [],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests: [],
      country: '',
      city: '',
      latitude: null,
      longitude: null,
      preferences: _prefs,
    );

    await tester.pumpWidget(
      RepositoryProvider<StoryRepository>.value(
        value: storyRepository,
        child: const MaterialApp(
          home: SwipeCard(profile: profile),
        ),
      ),
    );

    expect(find.textContaining('Someone new'), findsOneWidget);
    expect(find.text('Location unavailable'), findsOneWidget);
    // Compact card intentionally hides the fallback bio text
    expect(find.textContaining('has not added a bio'), findsNothing);
  });
}

class _EmptyStoryRepository implements StoryRepository {
  @override
  Stream<StoryUpdate> get storyUpdates => const Stream.empty();

  @override
  void initialize() {}

  @override
  void dispose() {}

  @override
  List<ProfileStory> getStoriesForUser(String userId) => const [];

  @override
  bool hasActiveStories(String userId) => false;

  @override
  int getActiveStoryCount(String userId) => 0;

  @override
  Future<ProfileStory> addStory({
    required String userId,
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? thumbnailUrl,
    Duration? customDuration,
  }) async {
    return ProfileStory(
      id: 'story-$userId',
      userId: userId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime.now(),
      thumbnailUrl: thumbnailUrl,
      expiresAt: customDuration == null
          ? null
          : DateTime.now().add(customDuration),
    );
  }

  @override
  Future<void> removeStory({required String userId, required String storyId}) async {}

  @override
  Future<void> viewStory({required String storyId, required String viewerId}) async {}

  @override
  List<String> getUsersWithActiveStories() => const [];

  @override
  void forceCleanup() {}

  @override
  void addMockStories() {}
}
