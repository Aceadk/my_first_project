/// Centralized profanity filter for text content validation.
///
/// Use this for validating user-generated content like messages,
/// bios, and profile prompts before submission.
class ProfanityFilter {
  ProfanityFilter._();

  /// Comprehensive list of banned words and phrases.
  /// Includes common profanity, slurs, and variations.
  static final Set<String> _banned = {
    // Common profanity
    'fuck',
    'shit',
    'ass',
    'asshole',
    'bitch',
    'bastard',
    'damn',
    'hell',
    'crap',
    'dick',
    'cock',
    'pussy',
    'cunt',
    'whore',
    'slut',
    'piss',
    'bollocks',
    'wanker',
    'twat',
    'prick',

    // Common variations and leetspeak
    'fck',
    'fuk',
    'fuq',
    'f*ck',
    'f**k',
    'sh1t',
    'sh!t',
    's**t',
    'b1tch',
    'b!tch',
    'a55',
    'a\$\$',
    'd1ck',
    'c0ck',
    'pu55y',

    // Slurs (abbreviated for sensitivity - expand as needed)
    'nigger',
    'nigga',
    'faggot',
    'fag',
    'retard',
    'retarded',
    'spic',
    'chink',
    'kike',
    'wetback',
    'tranny',

    // Sexual content indicators
    'blowjob',
    'handjob',
    'masturbate',
    'orgasm',
    'porn',
    'xxx',
    'nude',
    'naked',
    'titties',
    'boobs',
    'nipple',

    // Harassment terms
    'kill yourself',
    'kys',
    'die',
    'rape',
    'molest',
  };

  /// Pre-compiled regex pattern for efficient matching.
  static final RegExp _pattern = _buildPattern();

  static RegExp _buildPattern() {
    // Escape special regex characters and join with word boundaries
    final escaped = _banned
        .map((word) {
          // Handle multi-word phrases
          if (word.contains(' ')) {
            return word.split(' ').map(RegExp.escape).join(r'\s+');
          }
          return RegExp.escape(word);
        })
        .join('|');

    return RegExp(r'\b(' + escaped + r')\b', caseSensitive: false);
  }

  /// Checks if the given text contains any profanity.
  ///
  /// Returns `true` if profanity is detected, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (ProfanityFilter.containsProfanity(userMessage)) {
  ///   showError('Please remove inappropriate language.');
  /// }
  /// ```
  static bool containsProfanity(String text) {
    if (text.isEmpty) return false;
    return _pattern.hasMatch(text.toLowerCase());
  }

  /// Returns the first detected profane word, or null if none found.
  static String? findProfanity(String text) {
    if (text.isEmpty) return null;
    final match = _pattern.firstMatch(text.toLowerCase());
    return match?.group(0);
  }

  /// Returns all detected profane words in the text.
  static List<String> findAllProfanity(String text) {
    if (text.isEmpty) return [];
    return _pattern
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
  }

  /// Censors profanity in the given text by replacing with asterisks.
  ///
  /// Example:
  /// ```dart
  /// final clean = ProfanityFilter.censor('What the fuck?');
  /// // Returns: 'What the ****?'
  /// ```
  static String censor(String text) {
    if (text.isEmpty) return text;

    return text.replaceAllMapped(_pattern, (match) {
      final word = match.group(0)!;
      return '*' * word.length;
    });
  }

  /// Validates text and returns an error message if profanity is found.
  ///
  /// Returns `null` if text is clean.
  ///
  /// Example:
  /// ```dart
  /// final error = ProfanityFilter.validate(message);
  /// if (error != null) {
  ///   showError(error);
  ///   return;
  /// }
  /// ```
  static String? validate(String text, {String fieldName = 'message'}) {
    if (containsProfanity(text)) {
      return 'Your $fieldName contains inappropriate language. Please revise.';
    }
    return null;
  }
}
