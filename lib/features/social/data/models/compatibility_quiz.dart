import 'package:equatable/equatable.dart';

/// A compatibility quiz that matches can take together.
class CompatibilityQuiz extends Equatable {
  const CompatibilityQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.category = QuizCategory.general,
    this.estimatedMinutes = 5,
    this.imageUrl,
  });

  /// Unique quiz identifier.
  final String id;

  /// Quiz title.
  final String title;

  /// Quiz description.
  final String description;

  /// Questions in the quiz.
  final List<QuizQuestion> questions;

  /// Quiz category.
  final QuizCategory category;

  /// Estimated time to complete in minutes.
  final int estimatedMinutes;

  /// Cover image URL.
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'category': category.name,
      'estimatedMinutes': estimatedMinutes,
      'imageUrl': imageUrl,
    };
  }

  factory CompatibilityQuiz.fromJson(Map<String, dynamic> json) {
    return CompatibilityQuiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      category: QuizCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => QuizCategory.general,
      ),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        questions,
        category,
        estimatedMinutes,
        imageUrl,
      ];
}

/// A single quiz question.
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.emoji,
    this.category,
  });

  /// Question ID.
  final String id;

  /// The question text.
  final String question;

  /// Available options.
  final List<QuizOption> options;

  /// Emoji for the question.
  final String? emoji;

  /// Category this question belongs to.
  final QuestionCategory? category;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'emoji': emoji,
      'category': category?.name,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      emoji: json['emoji'] as String?,
      category: json['category'] != null
          ? QuestionCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => QuestionCategory.lifestyle,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [id, question, options, emoji, category];
}

/// A single quiz option.
class QuizOption extends Equatable {
  const QuizOption({
    required this.id,
    required this.text,
    this.emoji,
    this.value,
  });

  /// Option ID.
  final String id;

  /// Option text.
  final String text;

  /// Emoji for this option.
  final String? emoji;

  /// Numeric value for scoring.
  final int? value;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'emoji': emoji,
      'value': value,
    };
  }

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      value: json['value'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, text, emoji, value];
}

/// Results of a compatibility quiz taken by two users.
class QuizResult extends Equatable {
  const QuizResult({
    required this.quizId,
    required this.user1Id,
    required this.user2Id,
    required this.user1Answers,
    required this.user2Answers,
    required this.completedAt,
    this.overallScore,
    this.categoryScores = const {},
    this.insights = const [],
  });

  /// Quiz that was taken.
  final String quizId;

  /// First user ID.
  final String user1Id;

  /// Second user ID.
  final String user2Id;

  /// User 1's answers (questionId -> optionId).
  final Map<String, String> user1Answers;

  /// User 2's answers (questionId -> optionId).
  final Map<String, String> user2Answers;

  /// When the quiz was completed.
  final DateTime completedAt;

  /// Overall compatibility score (0-100).
  final int? overallScore;

  /// Scores by category.
  final Map<String, int> categoryScores;

  /// Compatibility insights.
  final List<CompatibilityInsight> insights;

  /// Get score display text.
  String get scoreDisplay {
    if (overallScore == null) return 'Calculating...';
    return '$overallScore%';
  }

  /// Get score rating.
  ScoreRating get rating {
    if (overallScore == null) return ScoreRating.unknown;
    if (overallScore! >= 90) return ScoreRating.excellent;
    if (overallScore! >= 75) return ScoreRating.great;
    if (overallScore! >= 60) return ScoreRating.good;
    if (overallScore! >= 40) return ScoreRating.moderate;
    return ScoreRating.low;
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Answers': user1Answers,
      'user2Answers': user2Answers,
      'completedAt': completedAt.toIso8601String(),
      'overallScore': overallScore,
      'categoryScores': categoryScores,
      'insights': insights.map((i) => i.toJson()).toList(),
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] as String,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      user1Answers: (json['user1Answers'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String)),
      user2Answers: (json['user2Answers'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String)),
      completedAt: DateTime.parse(json['completedAt'] as String),
      overallScore: json['overallScore'] as int?,
      categoryScores: (json['categoryScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      insights: (json['insights'] as List<dynamic>?)
              ?.map(
                  (i) => CompatibilityInsight.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        quizId,
        user1Id,
        user2Id,
        user1Answers,
        user2Answers,
        completedAt,
        overallScore,
        categoryScores,
        insights,
      ];
}

/// An insight about compatibility.
class CompatibilityInsight extends Equatable {
  const CompatibilityInsight({
    required this.type,
    required this.title,
    required this.description,
    this.emoji,
    this.isPositive = true,
  });

  final InsightType type;
  final String title;
  final String description;
  final String? emoji;
  final bool isPositive;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'emoji': emoji,
      'isPositive': isPositive,
    };
  }

  factory CompatibilityInsight.fromJson(Map<String, dynamic> json) {
    return CompatibilityInsight(
      type: InsightType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InsightType.general,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String?,
      isPositive: json['isPositive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [type, title, description, emoji, isPositive];
}

/// Quiz categories.
enum QuizCategory {
  general,
  romance,
  lifestyle,
  coreValues,
  communication,
  future,
}

/// Question categories.
enum QuestionCategory {
  lifestyle,
  coreValues,
  communication,
  intimacy,
  family,
  career,
  leisure;

  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case QuestionCategory.lifestyle:
        return 'Lifestyle';
      case QuestionCategory.coreValues:
        return 'Core Values';
      case QuestionCategory.communication:
        return 'Communication';
      case QuestionCategory.intimacy:
        return 'Intimacy';
      case QuestionCategory.family:
        return 'Family';
      case QuestionCategory.career:
        return 'Career';
      case QuestionCategory.leisure:
        return 'Leisure';
    }
  }
}

/// Types of insights.
enum InsightType {
  general,
  strength,
  growthArea,
  funFact,
  tip,
}

/// Score ratings.
enum ScoreRating {
  excellent,
  great,
  good,
  moderate,
  low,
  unknown,
}

extension ScoreRatingExtension on ScoreRating {
  String get displayText {
    switch (this) {
      case ScoreRating.excellent:
        return 'Excellent Match!';
      case ScoreRating.great:
        return 'Great Compatibility';
      case ScoreRating.good:
        return 'Good Connection';
      case ScoreRating.moderate:
        return 'Room to Grow';
      case ScoreRating.low:
        return 'Different Perspectives';
      case ScoreRating.unknown:
        return 'Calculating...';
    }
  }

  String get emoji {
    switch (this) {
      case ScoreRating.excellent:
        return '🌟';
      case ScoreRating.great:
        return '✨';
      case ScoreRating.good:
        return '👍';
      case ScoreRating.moderate:
        return '🌱';
      case ScoreRating.low:
        return '🔮';
      case ScoreRating.unknown:
        return '⏳';
    }
  }
}

/// Pre-defined compatibility quizzes.
class CompatibilityQuizzes {
  CompatibilityQuizzes._();

  static const CompatibilityQuiz basicCompatibility = CompatibilityQuiz(
    id: 'basic_compatibility',
    title: 'Basic Compatibility',
    description: 'Discover how well you match on the fundamentals',
    estimatedMinutes: 5,
    questions: [
      QuizQuestion(
        id: 'q1',
        question: 'How do you prefer to spend your weekends?',
        emoji: '🗓️',
        options: [
          QuizOption(id: 'a', text: 'Going out and socializing', emoji: '🎉'),
          QuizOption(id: 'b', text: 'Quiet time at home', emoji: '🏠'),
          QuizOption(id: 'c', text: 'Active outdoor activities', emoji: '🏃'),
          QuizOption(id: 'd', text: 'Mix of everything', emoji: '🎯'),
        ],
      ),
      QuizQuestion(
        id: 'q2',
        question: 'What\'s your communication style?',
        emoji: '💬',
        options: [
          QuizOption(id: 'a', text: 'Constant texting throughout the day', emoji: '📱'),
          QuizOption(id: 'b', text: 'A few meaningful messages', emoji: '💭'),
          QuizOption(id: 'c', text: 'Prefer calls over texts', emoji: '📞'),
          QuizOption(id: 'd', text: 'Quality time in person', emoji: '👥'),
        ],
      ),
      QuizQuestion(
        id: 'q3',
        question: 'How do you handle disagreements?',
        emoji: '🤝',
        options: [
          QuizOption(id: 'a', text: 'Talk it out immediately', emoji: '🗣️'),
          QuizOption(id: 'b', text: 'Take time to cool off first', emoji: '❄️'),
          QuizOption(id: 'c', text: 'Write out my thoughts', emoji: '✍️'),
          QuizOption(id: 'd', text: 'Seek compromise quickly', emoji: '🤝'),
        ],
      ),
      QuizQuestion(
        id: 'q4',
        question: 'What\'s most important in a relationship?',
        emoji: '❤️',
        options: [
          QuizOption(id: 'a', text: 'Trust and honesty', emoji: '🔐'),
          QuizOption(id: 'b', text: 'Adventure and excitement', emoji: '✨'),
          QuizOption(id: 'c', text: 'Emotional support', emoji: '🤗'),
          QuizOption(id: 'd', text: 'Shared goals and values', emoji: '🎯'),
        ],
      ),
      QuizQuestion(
        id: 'q5',
        question: 'How do you show love?',
        emoji: '💕',
        options: [
          QuizOption(id: 'a', text: 'Words of affirmation', emoji: '💬'),
          QuizOption(id: 'b', text: 'Quality time together', emoji: '⏰'),
          QuizOption(id: 'c', text: 'Thoughtful gifts', emoji: '🎁'),
          QuizOption(id: 'd', text: 'Acts of service', emoji: '🙌'),
        ],
      ),
    ],
  );

  static const CompatibilityQuiz lifestyleQuiz = CompatibilityQuiz(
    id: 'lifestyle',
    title: 'Lifestyle Match',
    description: 'See how your daily lives align',
    category: QuizCategory.lifestyle,
    estimatedMinutes: 4,
    questions: [
      QuizQuestion(
        id: 'l1',
        question: 'Are you a morning person or night owl?',
        emoji: '🌙',
        options: [
          QuizOption(id: 'a', text: 'Early bird', emoji: '🌅'),
          QuizOption(id: 'b', text: 'Night owl', emoji: '🦉'),
          QuizOption(id: 'c', text: 'Somewhere in between', emoji: '😴'),
        ],
      ),
      QuizQuestion(
        id: 'l2',
        question: 'How tidy is your living space?',
        emoji: '🏠',
        options: [
          QuizOption(id: 'a', text: 'Spotless at all times', emoji: '✨'),
          QuizOption(id: 'b', text: 'Organized chaos', emoji: '🌪️'),
          QuizOption(id: 'c', text: 'Clean when needed', emoji: '🧹'),
        ],
      ),
      QuizQuestion(
        id: 'l3',
        question: 'How often do you work out?',
        emoji: '💪',
        options: [
          QuizOption(id: 'a', text: 'Daily', emoji: '🏋️'),
          QuizOption(id: 'b', text: 'A few times a week', emoji: '🏃'),
          QuizOption(id: 'c', text: 'Occasionally', emoji: '🚶'),
          QuizOption(id: 'd', text: 'Working out? What\'s that?', emoji: '🛋️'),
        ],
      ),
      QuizQuestion(
        id: 'l4',
        question: 'What\'s your ideal vacation?',
        emoji: '✈️',
        options: [
          QuizOption(id: 'a', text: 'Beach relaxation', emoji: '🏖️'),
          QuizOption(id: 'b', text: 'City exploration', emoji: '🏙️'),
          QuizOption(id: 'c', text: 'Adventure and hiking', emoji: '⛰️'),
          QuizOption(id: 'd', text: 'Staycation', emoji: '🏠'),
        ],
      ),
    ],
  );

  static List<CompatibilityQuiz> get all => [
        basicCompatibility,
        lifestyleQuiz,
      ];
}
