import 'package:flutter/foundation.dart';

/// Filter options for advanced discovery filters.
class DiscoveryFilterOptions {
  DiscoveryFilterOptions._();

  // ═══════════════════════════════════════════════════════════════════════════
  // EDUCATION LEVELS
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> educationLevels = [
    FilterOption(id: 'high_school', label: 'High School'),
    FilterOption(id: 'some_college', label: 'Some College'),
    FilterOption(id: 'associates', label: 'Associate\'s'),
    FilterOption(id: 'bachelors', label: 'Bachelor\'s'),
    FilterOption(id: 'masters', label: 'Master\'s'),
    FilterOption(id: 'phd', label: 'PhD'),
    FilterOption(id: 'professional', label: 'Professional Degree'),
    FilterOption(id: 'trade_school', label: 'Trade School'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RELATIONSHIP GOALS
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> relationshipGoals = [
    FilterOption(id: 'long_term', label: 'Long-term relationship'),
    FilterOption(id: 'long_term_open', label: 'Long-term, open to short'),
    FilterOption(id: 'short_term', label: 'Short-term relationship'),
    FilterOption(id: 'short_term_open', label: 'Short-term, open to long'),
    FilterOption(id: 'friends', label: 'New friends'),
    FilterOption(id: 'figuring_out', label: 'Still figuring it out'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SMOKING
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> smokingOptions = [
    FilterOption(id: 'never', label: 'Non-smoker'),
    FilterOption(id: 'sometimes', label: 'Social smoker'),
    FilterOption(id: 'regularly', label: 'Regular smoker'),
    FilterOption(id: 'trying_to_quit', label: 'Trying to quit'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // DRINKING
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> drinkingOptions = [
    FilterOption(id: 'never', label: 'Never drinks'),
    FilterOption(id: 'sober', label: 'Sober'),
    FilterOption(id: 'sometimes', label: 'Social drinker'),
    FilterOption(id: 'often', label: 'Regular drinker'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> exerciseOptions = [
    FilterOption(id: 'never', label: 'Never'),
    FilterOption(id: 'sometimes', label: 'Sometimes'),
    FilterOption(id: 'often', label: 'Regularly'),
    FilterOption(id: 'daily', label: 'Every day'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PETS
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> petsOptions = [
    FilterOption(id: 'dog', label: 'Dog'),
    FilterOption(id: 'cat', label: 'Cat'),
    FilterOption(id: 'fish', label: 'Fish'),
    FilterOption(id: 'bird', label: 'Bird'),
    FilterOption(id: 'rabbit', label: 'Rabbit'),
    FilterOption(id: 'reptile', label: 'Reptile'),
    FilterOption(id: 'other', label: 'Other'),
    FilterOption(id: 'none', label: 'No pets'),
    FilterOption(id: 'want', label: 'Want a pet'),
    FilterOption(id: 'allergic', label: 'Allergic to pets'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // FAMILY PLANS
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> familyPlansOptions = [
    FilterOption(id: 'want', label: 'Want children'),
    FilterOption(id: 'dont_want', label: 'Don\'t want children'),
    FilterOption(id: 'have_want_more', label: 'Have children, want more'),
    FilterOption(
        id: 'have_dont_want_more', label: 'Have children, don\'t want more'),
    FilterOption(id: 'not_sure', label: 'Not sure yet'),
    FilterOption(id: 'open', label: 'Open to children'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ZODIAC SIGNS
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> zodiacSigns = [
    FilterOption(id: 'aries', label: 'Aries'),
    FilterOption(id: 'taurus', label: 'Taurus'),
    FilterOption(id: 'gemini', label: 'Gemini'),
    FilterOption(id: 'cancer', label: 'Cancer'),
    FilterOption(id: 'leo', label: 'Leo'),
    FilterOption(id: 'virgo', label: 'Virgo'),
    FilterOption(id: 'libra', label: 'Libra'),
    FilterOption(id: 'scorpio', label: 'Scorpio'),
    FilterOption(id: 'sagittarius', label: 'Sagittarius'),
    FilterOption(id: 'capricorn', label: 'Capricorn'),
    FilterOption(id: 'aquarius', label: 'Aquarius'),
    FilterOption(id: 'pisces', label: 'Pisces'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RELIGION
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> religionOptions = [
    FilterOption(id: 'agnostic', label: 'Agnostic'),
    FilterOption(id: 'atheist', label: 'Atheist'),
    FilterOption(id: 'buddhist', label: 'Buddhist'),
    FilterOption(id: 'catholic', label: 'Catholic'),
    FilterOption(id: 'christian', label: 'Christian'),
    FilterOption(id: 'hindu', label: 'Hindu'),
    FilterOption(id: 'jewish', label: 'Jewish'),
    FilterOption(id: 'muslim', label: 'Muslim'),
    FilterOption(id: 'sikh', label: 'Sikh'),
    FilterOption(id: 'spiritual', label: 'Spiritual'),
    FilterOption(id: 'other', label: 'Other'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON LANGUAGES
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<FilterOption> languages = [
    FilterOption(id: 'english', label: 'English'),
    FilterOption(id: 'spanish', label: 'Spanish'),
    FilterOption(id: 'french', label: 'French'),
    FilterOption(id: 'german', label: 'German'),
    FilterOption(id: 'italian', label: 'Italian'),
    FilterOption(id: 'portuguese', label: 'Portuguese'),
    FilterOption(id: 'russian', label: 'Russian'),
    FilterOption(id: 'chinese', label: 'Chinese'),
    FilterOption(id: 'japanese', label: 'Japanese'),
    FilterOption(id: 'korean', label: 'Korean'),
    FilterOption(id: 'arabic', label: 'Arabic'),
    FilterOption(id: 'hindi', label: 'Hindi'),
    FilterOption(id: 'dutch', label: 'Dutch'),
    FilterOption(id: 'polish', label: 'Polish'),
    FilterOption(id: 'turkish', label: 'Turkish'),
    FilterOption(id: 'swedish', label: 'Swedish'),
    FilterOption(id: 'vietnamese', label: 'Vietnamese'),
    FilterOption(id: 'thai', label: 'Thai'),
    FilterOption(id: 'greek', label: 'Greek'),
    FilterOption(id: 'hebrew', label: 'Hebrew'),
  ];

  /// Get label for option ID from any list.
  static String? getLabelForId(String id, List<FilterOption> options) {
    try {
      return options.firstWhere((o) => o.id == id).label;
    } catch (e) {
      debugPrint('DiscoveryFilterOptions: Option not found for id $id: $e');
      return null;
    }
  }
}

/// A filter option with ID and display label.
class FilterOption {
  const FilterOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Height conversion utilities.
class HeightUtils {
  HeightUtils._();

  /// Convert cm to feet and inches display string.
  static String cmToFeetInches(int cm) {
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }

  /// Convert feet and inches to cm.
  static int feetInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return (totalInches * 2.54).round();
  }

  /// Get display string for height in cm (shows both cm and ft/in).
  static String getDisplayHeight(int cm) {
    return '$cm cm (${cmToFeetInches(cm)})';
  }

  /// Common height values for range slider.
  static const int minHeight = 120; // ~4'0"
  static const int maxHeight = 220; // ~7'3"
}
