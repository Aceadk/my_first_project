/// Centralized configuration for all profile field dropdown options.
/// Each option includes a display label and optional emoji/icon.
class ProfileFieldOptions {
  ProfileFieldOptions._();

  // ═══════════════════════════════════════════════════════════════════════════
  // RELATIONSHIP GOALS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> relationshipGoals = [
    (label: 'Long-term partner', value: 'long_term', emoji: '💍'),
    (label: 'Long-term, open to short', value: 'long_open_short', emoji: '💕'),
    (label: 'Short-term, open to long', value: 'short_open_long', emoji: '🎉'),
    (label: 'Short-term fun', value: 'short_term', emoji: '✨'),
    (label: 'New friends', value: 'friends', emoji: '👋'),
    (label: 'Friends with benefits', value: 'fwb', emoji: '🔥'),
    (label: 'Let\'s see where it goes', value: 'lets_see', emoji: '🤷'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // EDUCATION LEVELS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> educationLevels = [
    (label: 'High school', value: 'high_school', emoji: '🏫'),
    (label: 'Trade school', value: 'trade_school', emoji: '🔧'),
    (label: 'At university', value: 'at_uni', emoji: '📚'),
    (label: 'Bachelor\'s degree', value: 'bachelors', emoji: '🎓'),
    (label: 'On a graduate program', value: 'graduate_program', emoji: '📖'),
    (label: 'Master\'s degree', value: 'masters', emoji: '🎓'),
    (label: 'PhD / Doctorate', value: 'phd', emoji: '🎓'),
    (label: 'Dropout', value: 'dropout', emoji: '🚪'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // FAMILY PLANS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> familyPlans = [
    (label: 'I want children', value: 'want', emoji: '👶'),
    (label: 'I don\'t want children', value: 'dont_want', emoji: '🚫'),
    (label: 'I have children and want more', value: 'have_want_more', emoji: '👨‍👩‍👧‍👦'),
    (label: 'I have children and don\'t want more', value: 'have_no_more', emoji: '👨‍👩‍👧'),
    (label: 'Not sure yet', value: 'not_sure', emoji: '🤔'),
    (label: 'Open to children', value: 'open', emoji: '💭'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONALITY TYPES (MBTI)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String description})> personalityTypes = [
    (label: 'INTJ', value: 'intj', description: 'The Architect'),
    (label: 'INTP', value: 'intp', description: 'The Logician'),
    (label: 'ENTJ', value: 'entj', description: 'The Commander'),
    (label: 'ENTP', value: 'entp', description: 'The Debater'),
    (label: 'INFJ', value: 'infj', description: 'The Advocate'),
    (label: 'INFP', value: 'infp', description: 'The Mediator'),
    (label: 'ENFJ', value: 'enfj', description: 'The Protagonist'),
    (label: 'ENFP', value: 'enfp', description: 'The Campaigner'),
    (label: 'ISTJ', value: 'istj', description: 'The Logistician'),
    (label: 'ISFJ', value: 'isfj', description: 'The Defender'),
    (label: 'ESTJ', value: 'estj', description: 'The Executive'),
    (label: 'ESFJ', value: 'esfj', description: 'The Consul'),
    (label: 'ISTP', value: 'istp', description: 'The Virtuoso'),
    (label: 'ISFP', value: 'isfp', description: 'The Adventurer'),
    (label: 'ESTP', value: 'estp', description: 'The Entrepreneur'),
    (label: 'ESFP', value: 'esfp', description: 'The Entertainer'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKOUT HABITS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> workoutHabits = [
    (label: 'Everyday', value: 'everyday', emoji: '💪'),
    (label: 'Often', value: 'often', emoji: '🏃'),
    (label: 'Sometimes', value: 'sometimes', emoji: '🚶'),
    (label: 'Athlete', value: 'athlete', emoji: '🏆'),
    (label: 'Never', value: 'never', emoji: '🛋️'),
    (label: 'Hates it', value: 'hates', emoji: '😤'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SOCIAL MEDIA USAGE
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> socialMediaUsage = [
    (label: 'Socially active', value: 'active', emoji: '📱'),
    (label: 'Influencer vibes', value: 'influencer', emoji: '✨'),
    (label: 'Not much', value: 'not_much', emoji: '🤷'),
    (label: 'Just for reels', value: 'reels_only', emoji: '🎬'),
    (label: 'Off the grid', value: 'off_grid', emoji: '🏕️'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SLEEPING HABITS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> sleepingHabits = [
    (label: 'Early bird', value: 'early_bird', emoji: '🌅'),
    (label: 'Night owl', value: 'night_owl', emoji: '🦉'),
    (label: 'It varies', value: 'varies', emoji: '🔄'),
    (label: 'Insomniac', value: 'insomniac', emoji: '😵'),
    (label: 'Heavy sleeper', value: 'heavy_sleeper', emoji: '😴'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SMOKING HABITS (Expanded)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> smokingHabits = [
    (label: 'Non-smoker', value: 'non_smoker', emoji: '🚭'),
    (label: 'Social smoker', value: 'social', emoji: '🚬'),
    (label: 'Smoker when drinking', value: 'when_drinking', emoji: '🍺'),
    (label: 'Regular smoker', value: 'regular', emoji: '🚬'),
    (label: 'Trying to quit', value: 'trying_quit', emoji: '💪'),
    (label: 'Quit', value: 'quit', emoji: '✅'),
    (label: 'Just hookah/vape', value: 'hookah_vape', emoji: '💨'),
    (label: 'Just weed', value: 'weed', emoji: '🌿'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // DRINKING HABITS (Expanded)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> drinkingHabits = [
    (label: 'Never', value: 'never', emoji: '🚫'),
    (label: 'Occasionally', value: 'occasionally', emoji: '🍷'),
    (label: 'Socially', value: 'socially', emoji: '🥂'),
    (label: 'Frequently', value: 'frequently', emoji: '🍻'),
    (label: 'Sober', value: 'sober', emoji: '💧'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PETS (30+ options)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String emoji})> petOptions = [
    (label: 'Dog', value: 'dog', emoji: '🐕'),
    (label: 'Cat', value: 'cat', emoji: '🐱'),
    (label: 'Dog and cat', value: 'dog_cat', emoji: '🐕🐱'),
    (label: 'Fish', value: 'fish', emoji: '🐠'),
    (label: 'Bird', value: 'bird', emoji: '🦜'),
    (label: 'Hamster', value: 'hamster', emoji: '🐹'),
    (label: 'Rabbit', value: 'rabbit', emoji: '🐰'),
    (label: 'Guinea pig', value: 'guinea_pig', emoji: '🐹'),
    (label: 'Turtle', value: 'turtle', emoji: '🐢'),
    (label: 'Snake', value: 'snake', emoji: '🐍'),
    (label: 'Lizard', value: 'lizard', emoji: '🦎'),
    (label: 'Frog', value: 'frog', emoji: '🐸'),
    (label: 'Horse', value: 'horse', emoji: '🐴'),
    (label: 'Ferret', value: 'ferret', emoji: '🦡'),
    (label: 'Hedgehog', value: 'hedgehog', emoji: '🦔'),
    (label: 'Chinchilla', value: 'chinchilla', emoji: '🐭'),
    (label: 'Parrot', value: 'parrot', emoji: '🦜'),
    (label: 'Chicken', value: 'chicken', emoji: '🐔'),
    (label: 'Duck', value: 'duck', emoji: '🦆'),
    (label: 'Goat', value: 'goat', emoji: '🐐'),
    (label: 'Pig', value: 'pig', emoji: '🐷'),
    (label: 'Cow', value: 'cow', emoji: '🐮'),
    (label: 'Spider', value: 'spider', emoji: '🕷️'),
    (label: 'Hermit crab', value: 'hermit_crab', emoji: '🦀'),
    (label: 'All the pets!', value: 'all_pets', emoji: '🐾'),
    (label: 'Want a pet', value: 'want_pet', emoji: '🙏'),
    (label: 'Don\'t have but love them', value: 'love_no_have', emoji: '❤️'),
    (label: 'Allergic to pets', value: 'allergic', emoji: '🤧'),
    (label: 'Don\'t like pets', value: 'dont_like', emoji: '🚫'),
    (label: 'No pets', value: 'no_pets', emoji: '➖'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ZODIAC SIGNS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value, String dateRange, String emoji})> zodiacSigns = [
    (label: 'Aries', value: 'aries', dateRange: 'Mar 21 - Apr 19', emoji: '♈'),
    (label: 'Taurus', value: 'taurus', dateRange: 'Apr 20 - May 20', emoji: '♉'),
    (label: 'Gemini', value: 'gemini', dateRange: 'May 21 - Jun 20', emoji: '♊'),
    (label: 'Cancer', value: 'cancer', dateRange: 'Jun 21 - Jul 22', emoji: '♋'),
    (label: 'Leo', value: 'leo', dateRange: 'Jul 23 - Aug 22', emoji: '♌'),
    (label: 'Virgo', value: 'virgo', dateRange: 'Aug 23 - Sep 22', emoji: '♍'),
    (label: 'Libra', value: 'libra', dateRange: 'Sep 23 - Oct 22', emoji: '♎'),
    (label: 'Scorpio', value: 'scorpio', dateRange: 'Oct 23 - Nov 21', emoji: '♏'),
    (label: 'Sagittarius', value: 'sagittarius', dateRange: 'Nov 22 - Dec 21', emoji: '♐'),
    (label: 'Capricorn', value: 'capricorn', dateRange: 'Dec 22 - Jan 19', emoji: '♑'),
    (label: 'Aquarius', value: 'aquarius', dateRange: 'Jan 20 - Feb 18', emoji: '♒'),
    (label: 'Pisces', value: 'pisces', dateRange: 'Feb 19 - Mar 20', emoji: '♓'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // LANGUAGES (50 most spoken + Nepali = 51)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<String> languages = [
    'English',
    'Mandarin Chinese',
    'Hindi',
    'Spanish',
    'French',
    'Arabic',
    'Bengali',
    'Portuguese',
    'Russian',
    'Japanese',
    'German',
    'Korean',
    'Vietnamese',
    'Turkish',
    'Italian',
    'Thai',
    'Polish',
    'Ukrainian',
    'Dutch',
    'Greek',
    'Czech',
    'Swedish',
    'Hungarian',
    'Finnish',
    'Norwegian',
    'Danish',
    'Hebrew',
    'Indonesian',
    'Malay',
    'Filipino',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Nepali',
    'Swahili',
    'Zulu',
    'Afrikaans',
    'Persian',
    'Urdu',
    'Romanian',
    'Serbian',
    'Croatian',
    'Bulgarian',
    'Slovak',
    'Catalan',
    'Slovenian',
    'Latvian',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // GENDER OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value})> genderOptions = [
    (label: 'Female', value: 'female'),
    (label: 'Male', value: 'male'),
    (label: 'Non-binary', value: 'non_binary'),
    (label: 'Transgender woman', value: 'trans_woman'),
    (label: 'Transgender man', value: 'trans_man'),
    (label: 'Genderqueer', value: 'genderqueer'),
    (label: 'Genderfluid', value: 'genderfluid'),
    (label: 'Agender', value: 'agender'),
    (label: 'Two-spirit', value: 'two_spirit'),
    (label: 'Prefer not to say', value: 'prefer_not_say'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SEXUAL ORIENTATION OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<({String label, String value})> sexualOrientationOptions = [
    (label: 'Straight', value: 'straight'),
    (label: 'Gay', value: 'gay'),
    (label: 'Lesbian', value: 'lesbian'),
    (label: 'Bisexual', value: 'bisexual'),
    (label: 'Pansexual', value: 'pansexual'),
    (label: 'Asexual', value: 'asexual'),
    (label: 'Demisexual', value: 'demisexual'),
    (label: 'Queer', value: 'queer'),
    (label: 'Questioning', value: 'questioning'),
    (label: 'Prefer not to say', value: 'prefer_not_say'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERESTS (Common dating app interests)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<String> interests = [
    'Travel',
    'Music',
    'Movies',
    'Reading',
    'Cooking',
    'Fitness',
    'Yoga',
    'Gaming',
    'Photography',
    'Art',
    'Dancing',
    'Hiking',
    'Camping',
    'Beach',
    'Mountains',
    'Coffee',
    'Wine',
    'Craft beer',
    'Foodie',
    'Brunch',
    'Nightlife',
    'Concerts',
    'Festivals',
    'Theater',
    'Comedy',
    'Sports',
    'Football',
    'Basketball',
    'Soccer',
    'Tennis',
    'Golf',
    'Skiing',
    'Snowboarding',
    'Surfing',
    'Swimming',
    'Running',
    'Cycling',
    'Gym',
    'CrossFit',
    'Meditation',
    'Spirituality',
    'Volunteering',
    'Activism',
    'Politics',
    'Entrepreneurship',
    'Startups',
    'Investing',
    'Technology',
    'Science',
    'Nature',
    'Animals',
    'Dogs',
    'Cats',
    'Fashion',
    'Shopping',
    'DIY',
    'Gardening',
    'Board games',
    'Trivia',
    'Karaoke',
    'Podcasts',
    'Netflix',
    'Anime',
    'K-pop',
    'Astrology',
    'True crime',
    'Self-care',
    'Skincare',
    'Tattoos',
    'Writing',
    'Poetry',
    'Languages',
    'History',
    'Philosophy',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get display label for a relationship goal value
  static String? getRelationshipGoalLabel(String? value) {
    if (value == null) return null;
    final match = relationshipGoals.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for an education level value
  static String? getEducationLabel(String? value) {
    if (value == null) return null;
    final match = educationLevels.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a family plan value
  static String? getFamilyPlanLabel(String? value) {
    if (value == null) return null;
    final match = familyPlans.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a personality type value
  static String? getPersonalityLabel(String? value) {
    if (value == null) return null;
    final match = personalityTypes.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.label} - ${match.description}' : null;
  }

  /// Get display label for a workout habit value
  static String? getWorkoutLabel(String? value) {
    if (value == null) return null;
    final match = workoutHabits.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a social media usage value
  static String? getSocialMediaLabel(String? value) {
    if (value == null) return null;
    final match = socialMediaUsage.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a sleeping habit value
  static String? getSleepingLabel(String? value) {
    if (value == null) return null;
    final match = sleepingHabits.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a smoking habit value
  static String? getSmokingLabel(String? value) {
    if (value == null) return null;
    final match = smokingHabits.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a drinking habit value
  static String? getDrinkingLabel(String? value) {
    if (value == null) return null;
    final match = drinkingHabits.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a pet value
  static String? getPetLabel(String? value) {
    if (value == null) return null;
    final match = petOptions.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a zodiac sign value
  static String? getZodiacLabel(String? value) {
    if (value == null) return null;
    final match = zodiacSigns.where((e) => e.value == value).firstOrNull;
    return match != null ? '${match.emoji} ${match.label}' : null;
  }

  /// Get display label for a gender value
  static String? getGenderLabel(String? value) {
    if (value == null) return null;
    final match = genderOptions.where((e) => e.value == value).firstOrNull;
    return match?.label;
  }

  /// Get display label for a sexual orientation value
  static String? getSexualOrientationLabel(String? value) {
    if (value == null) return null;
    final match = sexualOrientationOptions.where((e) => e.value == value).firstOrNull;
    return match?.label;
  }

  /// Convert height in cm to feet and inches string
  static String cmToFeetInchesString(int cm) {
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }

  /// Convert height in cm to separate feet and inches values
  static ({int feet, int inches}) cmToFeetInchesValues(int cm) {
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return (feet: feet, inches: inches);
  }

  /// Format height for display (e.g., "5'10" (178 cm)")
  static String formatHeightDisplay(int cm) {
    return '${cmToFeetInchesString(cm)} ($cm cm)';
  }

  /// Convert feet and inches to cm
  static int feetInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return (totalInches * 2.54).round();
  }
}
