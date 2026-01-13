import 'dart:math';
import 'package:crushhour/data/models/profile.dart';

/// Service for generating ice breaker suggestions for new matches.
class IceBreakerService {
  IceBreakerService._();

  static final _random = Random();

  /// Get ice breaker suggestions for a match.
  /// Uses the other user's profile to generate contextual suggestions.
  static List<IceBreakerSuggestion> getSuggestions({
    Profile? otherProfile,
    int maxCount = 4,
  }) {
    final suggestions = <IceBreakerSuggestion>[];

    // Add profile-based suggestions if profile is available
    if (otherProfile != null) {
      suggestions.addAll(_getProfileBasedSuggestions(otherProfile));
    }

    // Add generic suggestions
    suggestions.addAll(_getGenericSuggestions());

    // Shuffle and return max count
    suggestions.shuffle(_random);
    return suggestions.take(maxCount).toList();
  }

  /// Generate suggestions based on the other user's profile.
  static List<IceBreakerSuggestion> _getProfileBasedSuggestions(Profile profile) {
    final suggestions = <IceBreakerSuggestion>[];

    // Based on interests
    if (profile.interests.isNotEmpty) {
      final interest = profile.interests[_random.nextInt(profile.interests.length)];
      suggestions.add(IceBreakerSuggestion(
        text: "I noticed you're into $interest! What got you started?",
        category: IceBreakerCategory.interest,
        icon: '🌟',
      ));

      if (profile.interests.length > 1) {
        final anotherInterest = profile.interests
            .where((i) => i != interest)
            .elementAt(_random.nextInt(profile.interests.length - 1));
        suggestions.add(IceBreakerSuggestion(
          text: "Do you prefer $interest or $anotherInterest?",
          category: IceBreakerCategory.interest,
          icon: '🤔',
        ));
      }
    }

    // Based on prompts
    if (profile.profilePrompts.isNotEmpty) {
      final prompt = profile.profilePrompts[_random.nextInt(profile.profilePrompts.length)];
      suggestions.add(IceBreakerSuggestion(
        text: "Love your answer about '${prompt.question}' - tell me more!",
        category: IceBreakerCategory.prompt,
        icon: '💬',
      ));
    }

    // Based on job
    if (profile.jobTitle != null && profile.jobTitle!.isNotEmpty) {
      suggestions.add(IceBreakerSuggestion(
        text: "What's the best part about being a ${profile.jobTitle}?",
        category: IceBreakerCategory.work,
        icon: '💼',
      ));
    }

    // Based on location
    if (profile.livingIn != null && profile.livingIn!.isNotEmpty) {
      suggestions.add(IceBreakerSuggestion(
        text: "What's your favorite spot in ${profile.livingIn}?",
        category: IceBreakerCategory.location,
        icon: '📍',
      ));
    }

    // Based on pets
    if (profile.pets != null) {
      final petQuestions = {
        'dog': "I see you're a dog person! What breed?",
        'cat': "Cat lover! What's your cat's name?",
        'fish': "You have fish! Do you have a favorite one?",
        'bird': "A bird person! What kind of bird do you have?",
        'want': "I heard you want a pet! What kind are you thinking?",
      };
      final petQ = petQuestions[profile.pets];
      if (petQ != null) {
        suggestions.add(IceBreakerSuggestion(
          text: petQ,
          category: IceBreakerCategory.lifestyle,
          icon: '🐾',
        ));
      }
    }

    // Based on zodiac
    if (profile.zodiacSign != null) {
      suggestions.add(IceBreakerSuggestion(
        text: "Do you actually relate to being a ${profile.zodiacSign}?",
        category: IceBreakerCategory.personality,
        icon: '✨',
      ));
    }

    return suggestions;
  }

  /// Generic ice breaker suggestions that work for anyone.
  static List<IceBreakerSuggestion> _getGenericSuggestions() {
    return [
      // Fun questions
      const IceBreakerSuggestion(
        text: "If you could have dinner with anyone, dead or alive, who would it be?",
        category: IceBreakerCategory.fun,
        icon: '🍽️',
      ),
      const IceBreakerSuggestion(
        text: "What's the last thing that made you laugh out loud?",
        category: IceBreakerCategory.fun,
        icon: '😂',
      ),
      const IceBreakerSuggestion(
        text: "Are you more of a spontaneous adventure or planned vacation person?",
        category: IceBreakerCategory.fun,
        icon: '✈️',
      ),
      const IceBreakerSuggestion(
        text: "What's on your bucket list?",
        category: IceBreakerCategory.fun,
        icon: '🎯',
      ),
      // This or that
      const IceBreakerSuggestion(
        text: "Coffee or tea person?",
        category: IceBreakerCategory.thisOrThat,
        icon: '☕',
      ),
      const IceBreakerSuggestion(
        text: "Beach or mountains?",
        category: IceBreakerCategory.thisOrThat,
        icon: '🏖️',
      ),
      const IceBreakerSuggestion(
        text: "Early bird or night owl?",
        category: IceBreakerCategory.thisOrThat,
        icon: '🌙',
      ),
      // Get to know
      const IceBreakerSuggestion(
        text: "What's something you're really passionate about?",
        category: IceBreakerCategory.getToKnow,
        icon: '💫',
      ),
      const IceBreakerSuggestion(
        text: "What's the best trip you've ever taken?",
        category: IceBreakerCategory.getToKnow,
        icon: '🌍',
      ),
      const IceBreakerSuggestion(
        text: "What's your go-to comfort food?",
        category: IceBreakerCategory.getToKnow,
        icon: '🍕',
      ),
      // Compliment starters
      const IceBreakerSuggestion(
        text: "Your smile in your photos is contagious! What made you choose them?",
        category: IceBreakerCategory.compliment,
        icon: '😊',
      ),
      const IceBreakerSuggestion(
        text: "Your profile really stood out to me! What's your story?",
        category: IceBreakerCategory.compliment,
        icon: '✨',
      ),
      // Simple greetings
      const IceBreakerSuggestion(
        text: "Hey! How's your day going?",
        category: IceBreakerCategory.greeting,
        icon: '👋',
      ),
      const IceBreakerSuggestion(
        text: "Hi there! What are you up to this weekend?",
        category: IceBreakerCategory.greeting,
        icon: '🎉',
      ),
    ];
  }
}

/// A single ice breaker suggestion.
class IceBreakerSuggestion {
  const IceBreakerSuggestion({
    required this.text,
    required this.category,
    required this.icon,
  });

  /// The suggested message text.
  final String text;

  /// The category of the suggestion.
  final IceBreakerCategory category;

  /// An emoji icon for the suggestion.
  final String icon;
}

/// Categories of ice breaker suggestions.
enum IceBreakerCategory {
  interest,
  prompt,
  work,
  location,
  lifestyle,
  personality,
  fun,
  thisOrThat,
  getToKnow,
  compliment,
  greeting,
}
