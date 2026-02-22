import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/features/discovery/presentation/widgets/story_ring.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  ProfileStory story({
    required String id,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return ProfileStory(
      id: id,
      userId: 'user-1',
      mediaUrl: 'https://cdn.example.com/$id.jpg',
      mediaType: StoryMediaType.photo,
      createdAt: createdAt ?? now.subtract(const Duration(minutes: 10)),
      expiresAt: expiresAt,
    );
  }

  group('StoryRing', () {
    testWidgets('renders child only when there are no active stories', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const StoryRing(
            key: ValueKey('story-ring-empty'),
            size: 72,
            stories: [],
            child: CircleAvatar(child: Text('A')),
          ),
        ),
      );

      final ringFinder = find.byKey(const ValueKey('story-ring-empty'));
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(
        find.descendant(of: ringFinder, matching: find.byType(CustomPaint)),
        findsNothing,
      );
    });

    testWidgets('renders ring for active stories and handles tap', (
      tester,
    ) async {
      var tapped = 0;
      final active = story(id: 'active-1');
      final expired = story(
        id: 'expired-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 30)),
      );

      await tester.pumpWidget(
        host(
          StoryRing(
            key: const ValueKey('story-ring-active'),
            size: 72,
            hasUnseenStories: true,
            stories: [active, expired],
            onTap: () => tapped++,
            child: const CircleAvatar(child: Text('B')),
          ),
        ),
      );

      final ringFinder = find.byKey(const ValueKey('story-ring-active'));
      expect(
        find.descendant(of: ringFinder, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      await tester.tap(ringFinder);
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('supports multiple active stories for segmented ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          StoryRing(
            key: const ValueKey('story-ring-segmented'),
            stories: [
              story(id: 's1'),
              story(id: 's2'),
              story(id: 's3'),
            ],
            child: const CircleAvatar(child: Text('C')),
          ),
        ),
      );

      final ringFinder = find.byKey(const ValueKey('story-ring-segmented'));
      expect(
        find.descendant(of: ringFinder, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ringFinder, matching: find.byType(Padding)),
        findsWidgets,
      );
    });
  });

  group('StoryBadge', () {
    testWidgets('hides itself when story count is zero', (tester) async {
      await tester.pumpWidget(host(const StoryBadge(storyCount: 0)));

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('shows badge text and icon for unseen and compact states', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StoryBadge(storyCount: 2, hasUnseen: true),
              StoryBadge(storyCount: 1, compact: true),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('AnimatedStoryRing', () {
    testWidgets('falls back to child-only when no stories', (tester) async {
      await tester.pumpWidget(
        host(
          const AnimatedStoryRing(
            key: ValueKey('animated-story-ring-empty'),
            stories: [],
            child: CircleAvatar(child: Text('D')),
          ),
        ),
      );

      final ringFinder = find.byKey(
        const ValueKey('animated-story-ring-empty'),
      );
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(
        find.descendant(of: ringFinder, matching: find.byType(AnimatedBuilder)),
        findsNothing,
      );
    });

    testWidgets('renders animated ring, handles taps, and updates state', (
      tester,
    ) async {
      var tapped = 0;
      final stories = [story(id: 'active-ring')];

      await tester.pumpWidget(
        host(
          AnimatedStoryRing(
            key: const ValueKey('animated-story-ring-active'),
            stories: stories,
            hasUnseenStories: true,
            onTap: () => tapped++,
            child: const CircleAvatar(child: Text('E')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final ringFinder = find.byKey(
        const ValueKey('animated-story-ring-active'),
      );
      expect(
        find.descendant(of: ringFinder, matching: find.byType(AnimatedBuilder)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ringFinder, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );

      await tester.tap(find.byType(AnimatedStoryRing));
      await tester.pump();
      expect(tapped, 1);

      await tester.pumpWidget(
        host(
          AnimatedStoryRing(
            key: const ValueKey('animated-story-ring-active'),
            stories: stories,
            hasUnseenStories: false,
            onTap: () => tapped++,
            child: const CircleAvatar(child: Text('E')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.descendant(of: ringFinder, matching: find.byType(AnimatedBuilder)),
        findsOneWidget,
      );
    });
  });
}
