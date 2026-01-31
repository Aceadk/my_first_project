import 'package:equatable/equatable.dart';

/// A suggested date idea for matches.
class DateIdea extends Equatable {
  const DateIdea({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.emoji,
    this.estimatedCost,
    this.estimatedDuration,
    this.tags = const [],
    this.imageUrl,
    this.requirements = const [],
    this.bestFor = const [],
    this.seasonalAvailability,
  });

  /// Unique identifier.
  final String id;

  /// Title of the date idea.
  final String title;

  /// Description of the date.
  final String description;

  /// Category of date.
  final DateCategory category;

  /// Emoji representing the date.
  final String emoji;

  /// Estimated cost level.
  final DateCostLevel? estimatedCost;

  /// Estimated duration.
  final Duration? estimatedDuration;

  /// Tags for filtering.
  final List<String> tags;

  /// Image URL for the idea.
  final String? imageUrl;

  /// Requirements (e.g., "Car needed", "Reservation required").
  final List<String> requirements;

  /// Best for which type of dates.
  final List<DateType> bestFor;

  /// Seasonal availability (null means year-round).
  final List<Season>? seasonalAvailability;

  /// Get formatted duration.
  String get durationDisplay {
    if (estimatedDuration == null) return 'Varies';
    final hours = estimatedDuration!.inHours;
    final minutes = estimatedDuration!.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Get cost display.
  String get costDisplay => estimatedCost?.display ?? 'Varies';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'emoji': emoji,
      'estimatedCost': estimatedCost?.name,
      'estimatedDuration': estimatedDuration?.inMinutes,
      'tags': tags,
      'imageUrl': imageUrl,
      'requirements': requirements,
      'bestFor': bestFor.map((e) => e.name).toList(),
      'seasonalAvailability': seasonalAvailability?.map((e) => e.name).toList(),
    };
  }

  factory DateIdea.fromJson(Map<String, dynamic> json) {
    return DateIdea(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: DateCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DateCategory.casual,
      ),
      emoji: json['emoji'] as String,
      estimatedCost: json['estimatedCost'] != null
          ? DateCostLevel.values.firstWhere(
              (e) => e.name == json['estimatedCost'],
              orElse: () => DateCostLevel.moderate,
            )
          : null,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'] as int)
          : null,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      imageUrl: json['imageUrl'] as String?,
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bestFor: (json['bestFor'] as List<dynamic>?)
              ?.map((e) => DateType.values.firstWhere(
                    (t) => t.name == e,
                    orElse: () => DateType.firstDate,
                  ))
              .toList() ??
          [],
      seasonalAvailability: (json['seasonalAvailability'] as List<dynamic>?)
          ?.map((e) => Season.values.firstWhere(
                (s) => s.name == e,
                orElse: () => Season.spring,
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        emoji,
        estimatedCost,
        estimatedDuration,
        tags,
        imageUrl,
        requirements,
        bestFor,
        seasonalAvailability,
      ];
}

/// Categories of date ideas.
enum DateCategory {
  casual,
  romantic,
  adventure,
  cultural,
  foodie,
  active,
  relaxing,
  creative,
  nightlife,
  outdoor,
}

extension DateCategoryExtension on DateCategory {
  String get displayName {
    switch (this) {
      case DateCategory.casual:
        return 'Casual';
      case DateCategory.romantic:
        return 'Romantic';
      case DateCategory.adventure:
        return 'Adventure';
      case DateCategory.cultural:
        return 'Cultural';
      case DateCategory.foodie:
        return 'Foodie';
      case DateCategory.active:
        return 'Active';
      case DateCategory.relaxing:
        return 'Relaxing';
      case DateCategory.creative:
        return 'Creative';
      case DateCategory.nightlife:
        return 'Nightlife';
      case DateCategory.outdoor:
        return 'Outdoor';
    }
  }

  String get emoji {
    switch (this) {
      case DateCategory.casual:
        return '☕';
      case DateCategory.romantic:
        return '💕';
      case DateCategory.adventure:
        return '🎢';
      case DateCategory.cultural:
        return '🎭';
      case DateCategory.foodie:
        return '🍽️';
      case DateCategory.active:
        return '🏃';
      case DateCategory.relaxing:
        return '🧘';
      case DateCategory.creative:
        return '🎨';
      case DateCategory.nightlife:
        return '🌃';
      case DateCategory.outdoor:
        return '🌲';
    }
  }
}

/// Cost levels for dates.
enum DateCostLevel {
  free,
  budget,
  moderate,
  expensive,
  splurge,
}

extension DateCostLevelExtension on DateCostLevel {
  String get display {
    switch (this) {
      case DateCostLevel.free:
        return 'Free';
      case DateCostLevel.budget:
        return '\$';
      case DateCostLevel.moderate:
        return '\$\$';
      case DateCostLevel.expensive:
        return '\$\$\$';
      case DateCostLevel.splurge:
        return '\$\$\$\$';
    }
  }

  String get description {
    switch (this) {
      case DateCostLevel.free:
        return 'No cost';
      case DateCostLevel.budget:
        return 'Under \$25';
      case DateCostLevel.moderate:
        return '\$25-\$75';
      case DateCostLevel.expensive:
        return '\$75-\$150';
      case DateCostLevel.splurge:
        return '\$150+';
    }
  }
}

/// Types of dates.
enum DateType {
  firstDate,
  secondDate,
  established,
  special,
  virtual,
}

extension DateTypeExtension on DateType {
  String get displayName {
    switch (this) {
      case DateType.firstDate:
        return 'First Date';
      case DateType.secondDate:
        return 'Second Date';
      case DateType.established:
        return 'Established Couples';
      case DateType.special:
        return 'Special Occasion';
      case DateType.virtual:
        return 'Virtual Date';
    }
  }
}

/// Seasons for availability.
enum Season {
  spring,
  summer,
  fall,
  winter,
}

/// Pre-defined date ideas.
class DateIdeas {
  DateIdeas._();

  static const List<DateIdea> suggestions = [
    DateIdea(
      id: 'coffee_walk',
      title: 'Coffee & Walk',
      description:
          'Grab coffee and take a leisurely walk in the park. Perfect for getting to know someone in a relaxed setting.',
      category: DateCategory.casual,
      emoji: '☕',
      estimatedCost: DateCostLevel.budget,
      estimatedDuration: Duration(hours: 1, minutes: 30),
      tags: ['low-key', 'conversation', 'outdoor'],
      bestFor: [DateType.firstDate],
    ),
    DateIdea(
      id: 'cooking_class',
      title: 'Cooking Class',
      description:
          'Learn to cook a new cuisine together. Great for bonding and creating something delicious.',
      category: DateCategory.creative,
      emoji: '👨‍🍳',
      estimatedCost: DateCostLevel.moderate,
      estimatedDuration: Duration(hours: 2, minutes: 30),
      tags: ['interactive', 'food', 'learning'],
      bestFor: [DateType.secondDate, DateType.established],
      requirements: ['Book in advance'],
    ),
    DateIdea(
      id: 'sunset_picnic',
      title: 'Sunset Picnic',
      description:
          'Pack a picnic basket and watch the sunset together at a scenic spot.',
      category: DateCategory.romantic,
      emoji: '🌅',
      estimatedCost: DateCostLevel.budget,
      estimatedDuration: Duration(hours: 2),
      tags: ['romantic', 'outdoor', 'scenic'],
      bestFor: [DateType.secondDate, DateType.established, DateType.special],
      seasonalAvailability: [Season.spring, Season.summer, Season.fall],
    ),
    DateIdea(
      id: 'museum_day',
      title: 'Museum Exploration',
      description:
          'Explore an art or history museum together and share your interpretations.',
      category: DateCategory.cultural,
      emoji: '🏛️',
      estimatedCost: DateCostLevel.budget,
      estimatedDuration: Duration(hours: 2, minutes: 30),
      tags: ['cultural', 'educational', 'conversation'],
      bestFor: [DateType.firstDate, DateType.secondDate],
    ),
    DateIdea(
      id: 'hiking',
      title: 'Scenic Hike',
      description:
          'Take on a trail together and enjoy nature. Choose difficulty based on fitness levels.',
      category: DateCategory.adventure,
      emoji: '🥾',
      estimatedCost: DateCostLevel.free,
      estimatedDuration: Duration(hours: 3),
      tags: ['active', 'outdoor', 'nature'],
      bestFor: [DateType.secondDate, DateType.established],
      requirements: ['Comfortable shoes', 'Water'],
    ),
    DateIdea(
      id: 'game_night',
      title: 'Board Game Café',
      description:
          'Visit a board game café and play games over drinks. Fun and competitive!',
      category: DateCategory.casual,
      emoji: '🎲',
      estimatedCost: DateCostLevel.budget,
      estimatedDuration: Duration(hours: 2),
      tags: ['fun', 'games', 'social'],
      bestFor: [DateType.firstDate, DateType.secondDate],
    ),
    DateIdea(
      id: 'wine_tasting',
      title: 'Wine Tasting',
      description:
          'Sample wines at a local winery or wine bar. Sophisticated and relaxing.',
      category: DateCategory.foodie,
      emoji: '🍷',
      estimatedCost: DateCostLevel.moderate,
      estimatedDuration: Duration(hours: 2),
      tags: ['wine', 'tasting', 'sophisticated'],
      bestFor: [DateType.secondDate, DateType.established],
    ),
    DateIdea(
      id: 'concert',
      title: 'Live Music',
      description: 'Catch a live concert or open mic night at a local venue.',
      category: DateCategory.nightlife,
      emoji: '🎵',
      estimatedCost: DateCostLevel.moderate,
      estimatedDuration: Duration(hours: 3),
      tags: ['music', 'entertainment', 'night'],
      bestFor: [DateType.secondDate, DateType.established],
    ),
    DateIdea(
      id: 'pottery',
      title: 'Pottery Class',
      description:
          'Get your hands dirty making pottery together. Creative and memorable!',
      category: DateCategory.creative,
      emoji: '🏺',
      estimatedCost: DateCostLevel.moderate,
      estimatedDuration: Duration(hours: 2),
      tags: ['creative', 'hands-on', 'unique'],
      bestFor: [DateType.secondDate, DateType.established],
      requirements: ['Wear clothes you don\'t mind getting dirty'],
    ),
    DateIdea(
      id: 'stargazing',
      title: 'Stargazing',
      description:
          'Find a dark spot away from city lights and watch the stars together.',
      category: DateCategory.romantic,
      emoji: '⭐',
      estimatedCost: DateCostLevel.free,
      estimatedDuration: Duration(hours: 2),
      tags: ['romantic', 'outdoor', 'night'],
      bestFor: [DateType.established, DateType.special],
      requirements: ['Blanket', 'Clear night'],
    ),
  ];

  /// Get ideas filtered by category.
  static List<DateIdea> byCategory(DateCategory category) {
    return suggestions.where((idea) => idea.category == category).toList();
  }

  /// Get ideas suitable for a date type.
  static List<DateIdea> forDateType(DateType type) {
    return suggestions.where((idea) => idea.bestFor.contains(type)).toList();
  }

  /// Get ideas within a cost level.
  static List<DateIdea> byCost(DateCostLevel maxCost) {
    return suggestions
        .where((idea) =>
            idea.estimatedCost != null &&
            idea.estimatedCost!.index <= maxCost.index)
        .toList();
  }

  /// Get random suggestions.
  static List<DateIdea> random(int count) {
    final shuffled = List<DateIdea>.from(suggestions)..shuffle();
    return shuffled.take(count).toList();
  }
}
