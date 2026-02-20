import 'package:equatable/equatable.dart';
import 'package:crushhour/core/app_logger.dart';

/// A profile prompt with a question and user's answer.
/// Used as conversation starters on dating profiles.
class ProfilePrompt extends Equatable {
  const ProfilePrompt({
    required this.questionId,
    required this.answer,
    this.createdAt,
  });

  /// The ID of the question from [PromptQuestions].
  final String questionId;

  /// The user's answer to the prompt (max 250 characters).
  final String answer;

  /// When this prompt was created/answered.
  final DateTime? createdAt;

  /// Get the question text for this prompt.
  String get question => PromptQuestions.getQuestion(questionId);

  /// Get the category for this prompt.
  String get category => PromptQuestions.getCategory(questionId);

  /// Get the emoji for this prompt category.
  String get emoji => PromptQuestions.getEmoji(questionId);

  ProfilePrompt copyWith({
    String? questionId,
    String? answer,
    DateTime? createdAt,
  }) {
    return ProfilePrompt(
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory ProfilePrompt.fromJson(Map<String, dynamic> json) {
    return ProfilePrompt(
      questionId: json['questionId'] as String,
      answer: json['answer'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [questionId, answer, createdAt];
}

/// Predefined prompt questions organized by category.
class PromptQuestions {
  PromptQuestions._();

  static const int maxAnswerLength = 250;
  static const int maxPromptsPerProfile = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // QUESTION CATEGORIES
  // ═══════════════════════════════════════════════════════════════════════════

  static const String categoryAboutMe = 'about_me';
  static const String categoryDating = 'dating';
  static const String categoryPersonality = 'personality';
  static const String categoryLifestyle = 'lifestyle';
  static const String categoryConversation = 'conversation';
  static const String categoryFun = 'fun';

  // ═══════════════════════════════════════════════════════════════════════════
  // ALL QUESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<PromptQuestion> allQuestions = [
    // About Me
    PromptQuestion(
      id: 'simple_pleasure',
      question: 'A life goal of mine',
      category: categoryAboutMe,
      emoji: '\u{1F3AF}',
    ),
    PromptQuestion(
      id: 'not_obvious',
      question: 'Something not obvious about me',
      category: categoryAboutMe,
      emoji: '\u{1F92B}',
    ),
    PromptQuestion(
      id: 'proud_of',
      question: 'I\'m proud of',
      category: categoryAboutMe,
      emoji: '\u{1F3C6}',
    ),
    PromptQuestion(
      id: 'never_shut_up',
      question: 'I\'ll never shut up about',
      category: categoryAboutMe,
      emoji: '\u{1F5E3}\uFE0F',
    ),
    PromptQuestion(
      id: 'geek_out',
      question: 'I geek out on',
      category: categoryAboutMe,
      emoji: '\u{1F913}',
    ),
    PromptQuestion(
      id: 'fun_fact',
      question: 'A fun fact about me',
      category: categoryAboutMe,
      emoji: '\u2728',
    ),
    PromptQuestion(
      id: 'unusual_skill',
      question: 'My most unusual skill',
      category: categoryAboutMe,
      emoji: '\u{1F3AA}',
    ),
    PromptQuestion(
      id: 'superpower',
      question: 'My superpower',
      category: categoryAboutMe,
      emoji: '\u{1F9B8}',
    ),

    // Dating
    PromptQuestion(
      id: 'looking_for',
      question: 'I\'m looking for',
      category: categoryDating,
      emoji: '\u{1F495}',
    ),
    PromptQuestion(
      id: 'perfect_date',
      question: 'My ideal first date',
      category: categoryDating,
      emoji: '\u{1F339}',
    ),
    PromptQuestion(
      id: 'green_flag',
      question: 'A green flag I look for',
      category: categoryDating,
      emoji: '\u{1F7E2}',
    ),
    PromptQuestion(
      id: 'dealbreaker',
      question: 'My biggest dealbreaker',
      category: categoryDating,
      emoji: '\u{1F6A9}',
    ),
    PromptQuestion(
      id: 'love_language',
      question: 'My love language is',
      category: categoryDating,
      emoji: '\u{1F49D}',
    ),
    PromptQuestion(
      id: 'like_you_if',
      question: 'We\'ll get along if',
      category: categoryDating,
      emoji: '\u{1F91D}',
    ),
    PromptQuestion(
      id: 'way_to_heart',
      question: 'The way to my heart is',
      category: categoryDating,
      emoji: '\u2764\uFE0F',
    ),
    PromptQuestion(
      id: 'together_we',
      question: 'Together, we could',
      category: categoryDating,
      emoji: '\u{1F491}',
    ),

    // Personality
    PromptQuestion(
      id: 'typical_sunday',
      question: 'My typical Sunday',
      category: categoryPersonality,
      emoji: '\u2600\uFE0F',
    ),
    PromptQuestion(
      id: 'go_to_karaoke',
      question: 'My go-to karaoke song',
      category: categoryPersonality,
      emoji: '\u{1F3A4}',
    ),
    PromptQuestion(
      id: 'comfort_food',
      question: 'My comfort food',
      category: categoryPersonality,
      emoji: '\u{1F355}',
    ),
    PromptQuestion(
      id: 'guilty_pleasure',
      question: 'My guilty pleasure',
      category: categoryPersonality,
      emoji: '\u{1F648}',
    ),
    PromptQuestion(
      id: 'best_travel',
      question: 'Best travel story',
      category: categoryPersonality,
      emoji: '\u2708\uFE0F',
    ),
    PromptQuestion(
      id: 'happy_place',
      question: 'My happy place',
      category: categoryPersonality,
      emoji: '\u{1F3D6}\uFE0F',
    ),
    PromptQuestion(
      id: 'rewatch',
      question: 'I could rewatch forever',
      category: categoryPersonality,
      emoji: '\u{1F4FA}',
    ),
    PromptQuestion(
      id: 'current_obsession',
      question: 'My current obsession',
      category: categoryPersonality,
      emoji: '\u{1F60D}',
    ),

    // Lifestyle
    PromptQuestion(
      id: 'weekend_plans',
      question: 'My ideal weekend',
      category: categoryLifestyle,
      emoji: '\u{1F389}',
    ),
    PromptQuestion(
      id: 'morning_routine',
      question: 'My morning routine',
      category: categoryLifestyle,
      emoji: '\u{1F305}',
    ),
    PromptQuestion(
      id: 'workout_routine',
      question: 'My workout routine',
      category: categoryLifestyle,
      emoji: '\u{1F4AA}',
    ),
    PromptQuestion(
      id: 'cooking',
      question: 'I\'m known for cooking',
      category: categoryLifestyle,
      emoji: '\u{1F468}\u200D\u{1F373}',
    ),
    PromptQuestion(
      id: 'pet_peeve',
      question: 'My biggest pet peeve',
      category: categoryLifestyle,
      emoji: '\u{1F624}',
    ),
    PromptQuestion(
      id: 'splurge_on',
      question: 'I splurge on',
      category: categoryLifestyle,
      emoji: '\u{1F4B8}',
    ),

    // Conversation Starters
    PromptQuestion(
      id: 'debate',
      question: 'Let\'s debate this topic',
      category: categoryConversation,
      emoji: '\u{1F3AD}',
    ),
    PromptQuestion(
      id: 'hot_take',
      question: 'My most controversial opinion',
      category: categoryConversation,
      emoji: '\u{1F525}',
    ),
    PromptQuestion(
      id: 'recommend',
      question: 'I\'d recommend this to anyone',
      category: categoryConversation,
      emoji: '\u{1F44D}',
    ),
    PromptQuestion(
      id: 'believe_everyone',
      question: 'I believe everyone should',
      category: categoryConversation,
      emoji: '\u{1F4A1}',
    ),
    PromptQuestion(
      id: 'change_my_mind',
      question: 'Change my mind about',
      category: categoryConversation,
      emoji: '\u{1F914}',
    ),
    PromptQuestion(
      id: 'unpopular_opinion',
      question: 'My unpopular opinion',
      category: categoryConversation,
      emoji: '\u{1F64A}',
    ),

    // Fun
    PromptQuestion(
      id: 'two_truths_lie',
      question: 'Two truths and a lie',
      category: categoryFun,
      emoji: '\u{1F925}',
    ),
    PromptQuestion(
      id: 'worst_idea',
      question: 'Worst idea that worked',
      category: categoryFun,
      emoji: '\u{1F602}',
    ),
    PromptQuestion(
      id: 'celebrity_crush',
      question: 'My celebrity crush',
      category: categoryFun,
      emoji: '\u{1F31F}',
    ),
    PromptQuestion(
      id: 'bucket_list',
      question: 'On my bucket list',
      category: categoryFun,
      emoji: '\u{1F4CB}',
    ),
    PromptQuestion(
      id: 'zombie_apocalypse',
      question: 'In a zombie apocalypse, I\'d be',
      category: categoryFun,
      emoji: '\u{1F9DF}',
    ),
    PromptQuestion(
      id: 'desert_island',
      question: 'Desert island essentials',
      category: categoryFun,
      emoji: '\u{1F3DD}\uFE0F',
    ),
  ];

  /// Get questions by category.
  static List<PromptQuestion> getByCategory(String category) {
    return allQuestions.where((q) => q.category == category).toList();
  }

  /// Get all categories.
  static List<String> get categories => [
    categoryAboutMe,
    categoryDating,
    categoryPersonality,
    categoryLifestyle,
    categoryConversation,
    categoryFun,
  ];

  /// Get display name for category.
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case categoryAboutMe:
        return 'About Me';
      case categoryDating:
        return 'Dating';
      case categoryPersonality:
        return 'Personality';
      case categoryLifestyle:
        return 'Lifestyle';
      case categoryConversation:
        return 'Conversation Starters';
      case categoryFun:
        return 'Fun';
      default:
        return category;
    }
  }

  /// Get question text by ID.
  static String getQuestion(String questionId) {
    final question = allQuestions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => const PromptQuestion(
        id: 'unknown',
        question: 'Tell us something',
        category: categoryAboutMe,
        emoji: '\u{1F4AD}',
      ),
    );
    return question.question;
  }

  /// Get category by question ID.
  static String getCategory(String questionId) {
    final question = allQuestions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => const PromptQuestion(
        id: 'unknown',
        question: 'Tell us something',
        category: categoryAboutMe,
        emoji: '\u{1F4AD}',
      ),
    );
    return question.category;
  }

  /// Get emoji by question ID.
  static String getEmoji(String questionId) {
    final question = allQuestions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => const PromptQuestion(
        id: 'unknown',
        question: 'Tell us something',
        category: categoryAboutMe,
        emoji: '\u{1F4AD}',
      ),
    );
    return question.emoji;
  }

  /// Get question by ID.
  static PromptQuestion? getById(String questionId) {
    try {
      return allQuestions.firstWhere((q) => q.id == questionId);
    } catch (e) {
      AppLogger.error(
        'ProfilePromptQuestions: Question not found for id $questionId: $e',
      );
      return null;
    }
  }
}

/// A prompt question definition.
class PromptQuestion {
  const PromptQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.emoji,
  });

  final String id;
  final String question;
  final String category;
  final String emoji;
}
