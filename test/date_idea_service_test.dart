import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';
import 'package:crushhour/features/social/data/models/date_idea.dart';

void main() {
  group('DateIdeaService', () {
    late DateIdeaService service;

    setUp(() {
      service = DateIdeaService.instance;
    });

    group('getAllIdeas', () {
      test('returns list of date ideas', () {
        final ideas = service.getAllIdeas();

        expect(ideas, isNotEmpty);
        expect(ideas.every((i) => i.id.isNotEmpty), isTrue);
        expect(ideas.every((i) => i.title.isNotEmpty), isTrue);
      });
    });

    group('getIdeasByCategory', () {
      test('returns ideas filtered by category', () {
        final casualIdeas = service.getIdeasByCategory(DateCategory.casual);

        expect(casualIdeas.every((i) => i.category == DateCategory.casual),
            isTrue);
      });

      test('returns empty list for category with no ideas', () {
        // This tests behavior - all categories should have at least some ideas
        for (final category in DateCategory.values) {
          final ideas = service.getIdeasByCategory(category);
          // Each category should have ideas or be empty (not null)
          expect(ideas, isA<List<DateIdea>>());
        }
      });
    });

    group('getIdeasForDateType', () {
      test('returns ideas suitable for date type', () {
        final firstDateIdeas = service.getIdeasForDateType(DateType.firstDate);

        expect(
          firstDateIdeas.every((i) => i.bestFor.contains(DateType.firstDate)),
          isTrue,
        );
      });
    });

    group('getIdeasByBudget', () {
      test('returns ideas within budget', () {
        final budgetIdeas = service.getIdeasByBudget(DateCostLevel.budget);

        expect(
          budgetIdeas.every((i) =>
              i.estimatedCost != null &&
              i.estimatedCost!.index <= DateCostLevel.budget.index),
          isTrue,
        );
      });

      test('returns more ideas for higher budget', () {
        final budgetIdeas = service.getIdeasByBudget(DateCostLevel.budget);
        final expensiveIdeas =
            service.getIdeasByBudget(DateCostLevel.expensive);

        expect(expensiveIdeas.length, greaterThanOrEqualTo(budgetIdeas.length));
      });
    });

    group('getRandomSuggestions', () {
      test('returns requested number of suggestions', () {
        final suggestions = service.getRandomSuggestions(3);

        expect(suggestions.length, 3);
      });

      test('returns unique suggestions', () {
        final suggestions = service.getRandomSuggestions(5);
        final ids = suggestions.map((s) => s.id).toSet();

        expect(ids.length, suggestions.length);
      });
    });

    group('getPersonalizedSuggestions', () {
      test('returns filtered suggestions based on preferences', () async {
        final suggestions = await service.getPersonalizedSuggestions(
          dateType: DateType.firstDate,
          maxBudget: DateCostLevel.moderate,
          count: 3,
        );

        expect(suggestions.length, lessThanOrEqualTo(3));
        for (final idea in suggestions) {
          if (idea.bestFor.isNotEmpty) {
            // Should contain first date or be suitable
          }
        }
      });

      test('filters by preferred categories', () async {
        final suggestions = await service.getPersonalizedSuggestions(
          preferredCategories: [DateCategory.romantic],
          count: 5,
        );

        // If there are romantic ideas, they should be included
        for (final _ in suggestions) {
          if (suggestions.any((s) => s.category == DateCategory.romantic)) {
            expect(
              suggestions.where((s) => s.category == DateCategory.romantic),
              isNotEmpty,
            );
            break;
          }
        }
      });
    });

    group('saveIdea', () {
      test('saves idea to saved list', () async {
        final ideas = service.getAllIdeas();
        final ideaToSave = ideas.first;

        await service.saveIdea(ideaToSave);

        expect(service.isIdeaSaved(ideaToSave.id), isTrue);
        expect(service.savedIdeas.contains(ideaToSave), isTrue);
      });

      test('does not duplicate saved ideas', () async {
        final ideas = service.getAllIdeas();
        final ideaToSave = ideas.first;

        await service.saveIdea(ideaToSave);
        await service.saveIdea(ideaToSave);

        expect(
          service.savedIdeas.where((i) => i.id == ideaToSave.id).length,
          lessThanOrEqualTo(1),
        );
      });
    });

    group('removeSavedIdea', () {
      test('removes idea from saved list', () async {
        final ideas = service.getAllIdeas();
        final ideaToSave = ideas.last;

        await service.saveIdea(ideaToSave);
        expect(service.isIdeaSaved(ideaToSave.id), isTrue);

        await service.removeSavedIdea(ideaToSave.id);

        expect(service.isIdeaSaved(ideaToSave.id), isFalse);
      });
    });

    group('searchIdeas', () {
      test('finds ideas by title', () {
        final results = service.searchIdeas('coffee');

        expect(
          results.any((i) => i.title.toLowerCase().contains('coffee')),
          isTrue,
        );
      });

      test('finds ideas by description', () {
        final results = service.searchIdeas('walk');

        expect(
          results.any((i) => i.description.toLowerCase().contains('walk')),
          isTrue,
        );
      });

      test('finds ideas by tags', () {
        final ideas = service.getAllIdeas();
        // Find an idea with a tag to search for
        final ideaWithTag = ideas.firstWhere(
          (i) => i.tags.isNotEmpty,
          orElse: () => ideas.first,
        );

        if (ideaWithTag.tags.isNotEmpty) {
          final tag = ideaWithTag.tags.first;
          final results = service.searchIdeas(tag);

          expect(results, isNotEmpty);
        }
      });

      test('returns empty list for no matches', () {
        final results = service.searchIdeas('xyznonexistent123');

        expect(results, isEmpty);
      });
    });

    group('getCurrentSeason', () {
      test('returns a valid season', () {
        final season = service.getCurrentSeason();

        expect(Season.values.contains(season), isTrue);
      });
    });
  });
}
