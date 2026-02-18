import 'package:crushhour/features/social/data/models/date_idea.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateIdea hotspots', () {
    test('fromJson falls back for unknown enum values', () {
      final restored = DateIdea.fromJson(const <String, dynamic>{
        'id': 'fallback',
        'title': 'Fallback',
        'description': 'Fallback enum behavior',
        'category': 'unknown-category',
        'emoji': 'x',
        'estimatedCost': 'unknown-cost',
        'estimatedDuration': 15,
        'tags': const <String>['a'],
        'requirements': const <String>['b'],
        'bestFor': const <String>['unknown-date-type'],
        'seasonalAvailability': const <String>['unknown-season'],
      });

      expect(restored.category, DateCategory.casual);
      expect(restored.estimatedCost, DateCostLevel.moderate);
      expect(restored.bestFor, <DateType>[DateType.firstDate]);
      expect(restored.seasonalAvailability, <Season>[Season.spring]);
      expect(restored.durationDisplay, '15m');
    });

    test('DateCategory extension maps all display names and emoji', () {
      const expectedDisplayName = <DateCategory, String>{
        DateCategory.casual: 'Casual',
        DateCategory.romantic: 'Romantic',
        DateCategory.adventure: 'Adventure',
        DateCategory.cultural: 'Cultural',
        DateCategory.foodie: 'Foodie',
        DateCategory.active: 'Active',
        DateCategory.relaxing: 'Relaxing',
        DateCategory.creative: 'Creative',
        DateCategory.nightlife: 'Nightlife',
        DateCategory.outdoor: 'Outdoor',
      };

      const expectedEmoji = <DateCategory, String>{
        DateCategory.casual: '☕',
        DateCategory.romantic: '💕',
        DateCategory.adventure: '🎢',
        DateCategory.cultural: '🎭',
        DateCategory.foodie: '🍽️',
        DateCategory.active: '🏃',
        DateCategory.relaxing: '🧘',
        DateCategory.creative: '🎨',
        DateCategory.nightlife: '🌃',
        DateCategory.outdoor: '🌲',
      };

      for (final category in DateCategory.values) {
        expect(category.displayName, expectedDisplayName[category]);
        expect(category.emoji, expectedEmoji[category]);
      }
    });

    test('DateCostLevel extension maps display and descriptions', () {
      const expectedDisplay = <DateCostLevel, String>{
        DateCostLevel.free: 'Free',
        DateCostLevel.budget: r'$',
        DateCostLevel.moderate: r'$$',
        DateCostLevel.expensive: r'$$$',
        DateCostLevel.splurge: r'$$$$',
      };

      const expectedDescription = <DateCostLevel, String>{
        DateCostLevel.free: 'No cost',
        DateCostLevel.budget: r'Under $25',
        DateCostLevel.moderate: r'$25-$75',
        DateCostLevel.expensive: r'$75-$150',
        DateCostLevel.splurge: r'$150+',
      };

      for (final level in DateCostLevel.values) {
        expect(level.display, expectedDisplay[level]);
        expect(level.description, expectedDescription[level]);
      }
    });

    test('DateType extension maps all display names', () {
      const expected = <DateType, String>{
        DateType.firstDate: 'First Date',
        DateType.secondDate: 'Second Date',
        DateType.established: 'Established Couples',
        DateType.special: 'Special Occasion',
        DateType.virtual: 'Virtual Date',
      };

      for (final type in DateType.values) {
        expect(type.displayName, expected[type]);
      }
    });

    test('DateIdeas.random never exceeds available suggestions', () {
      final picked = DateIdeas.random(999);
      expect(picked.length, DateIdeas.suggestions.length);
      expect(picked.toSet().length, picked.length);
    });
  });
}
