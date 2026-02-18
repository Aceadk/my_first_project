import 'dart:async';
import '../models/compatibility_quiz.dart';
import 'package:crushhour/features/social/domain/repositories/compatibility_quiz_repository.dart';

/// Service for managing compatibility quizzes between matches.
class CompatibilityQuizService implements CompatibilityQuizRepository {
  CompatibilityQuizService._();
  static final CompatibilityQuizService instance = CompatibilityQuizService._();

  final _quizController = StreamController<CompatibilityQuiz>.broadcast();
  final _resultController = StreamController<QuizResult>.broadcast();

  @override
  Stream<CompatibilityQuiz> get quizStream => _quizController.stream;
  @override
  Stream<QuizResult> get resultStream => _resultController.stream;

  final Map<String, QuizResult> _results = {};
  final Map<String, Map<String, String>> _pendingAnswers = {};

  /// Get all available quizzes.
  @override
  List<CompatibilityQuiz> getAllQuizzes() {
    return CompatibilityQuizzes.all;
  }

  /// Get quiz by ID.
  @override
  CompatibilityQuiz? getQuiz(String quizId) {
    return CompatibilityQuizzes.all.firstWhere(
      (q) => q.id == quizId,
      orElse: () => CompatibilityQuizzes.basicCompatibility,
    );
  }

  /// Start a quiz session.
  @override
  Future<CompatibilityQuiz> startQuiz({
    required String quizId,
    required String matchId,
  }) async {
    final quiz = getQuiz(quizId);
    if (quiz == null) {
      throw Exception('Quiz not found');
    }

    _pendingAnswers[matchId] = {};
    _quizController.add(quiz);

    return quiz;
  }

  /// Submit an answer for a question.
  @override
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  }) async {
    _pendingAnswers[matchId] ??= {};
    _pendingAnswers[matchId]![questionId] = optionId;
  }

  /// Complete quiz and calculate results.
  @override
  Future<QuizResult> completeQuiz({
    required String quizId,
    required String matchId,
    required String user1Id,
    required String user2Id,
    required Map<String, String> user1Answers,
    required Map<String, String> user2Answers,
  }) async {
    final quiz = getQuiz(quizId);
    if (quiz == null) {
      throw Exception('Quiz not found');
    }

    // Calculate compatibility score
    final scoreData = _calculateScore(quiz, user1Answers, user2Answers);

    final result = QuizResult(
      quizId: quizId,
      user1Id: user1Id,
      user2Id: user2Id,
      user1Answers: user1Answers,
      user2Answers: user2Answers,
      completedAt: DateTime.now(),
      overallScore: scoreData.overallScore,
      categoryScores: scoreData.categoryScores,
      insights: _generateInsights(
          scoreData.overallScore, quiz, user1Answers, user2Answers),
    );

    _results['${matchId}_$quizId'] = result;
    _resultController.add(result);
    _pendingAnswers.remove(matchId);

    return result;
  }

  /// Get quiz result for a match.
  @override
  QuizResult? getResult(String matchId, String quizId) {
    return _results['${matchId}_$quizId'];
  }

  /// Get all results for a match.
  @override
  List<QuizResult> getAllResultsForMatch(String matchId) {
    return _results.entries
        .where((e) => e.key.startsWith(matchId))
        .map((e) => e.value)
        .toList();
  }

  /// Invite match to take a quiz.
  @override
  Future<void> inviteToQuiz({
    required String matchId,
    required String quizId,
    String? message,
  }) async {
    // In production, send notification/chat message
    await Future.delayed(const Duration(milliseconds: 300));
  }

  _ScoreData _calculateScore(
    CompatibilityQuiz quiz,
    Map<String, String> answers1,
    Map<String, String> answers2,
  ) {
    int matchingAnswers = 0;
    int totalQuestions = quiz.questions.length;
    final categoryScores = <String, int>{};

    for (final question in quiz.questions) {
      final answer1 = answers1[question.id];
      final answer2 = answers2[question.id];

      if (answer1 != null && answer2 != null) {
        if (answer1 == answer2) {
          matchingAnswers++;

          // Track category score
          if (question.category != null) {
            final categoryName = question.category!.name;
            categoryScores[categoryName] =
                (categoryScores[categoryName] ?? 0) + 1;
          }
        }
      }
    }

    // Calculate overall percentage
    final overallScore = totalQuestions > 0
        ? ((matchingAnswers / totalQuestions) * 100).round()
        : 0;

    // Convert category counts to percentages
    final categoryPercentages = <String, int>{};
    for (final entry in categoryScores.entries) {
      final categoryQuestions =
          quiz.questions.where((q) => q.category?.name == entry.key).length;
      if (categoryQuestions > 0) {
        categoryPercentages[entry.key] =
            ((entry.value / categoryQuestions) * 100).round();
      }
    }

    return _ScoreData(
      overallScore: overallScore,
      categoryScores: categoryPercentages,
    );
  }

  List<CompatibilityInsight> _generateInsights(
    int score,
    CompatibilityQuiz quiz,
    Map<String, String> answers1,
    Map<String, String> answers2,
  ) {
    final insights = <CompatibilityInsight>[];

    // Overall insight
    if (score >= 80) {
      insights.add(const CompatibilityInsight(
        type: InsightType.strength,
        title: 'Great Match!',
        description: 'You both see eye to eye on most things.',
        emoji: '💫',
        isPositive: true,
      ));
    } else if (score >= 60) {
      insights.add(const CompatibilityInsight(
        type: InsightType.general,
        title: 'Good Foundation',
        description: 'You have a solid base with room to explore differences.',
        emoji: '🌱',
        isPositive: true,
      ));
    } else {
      insights.add(const CompatibilityInsight(
        type: InsightType.growthArea,
        title: 'Interesting Contrast',
        description: 'Different perspectives can lead to growth and learning.',
        emoji: '🔮',
        isPositive: true,
      ));
    }

    // Find a matching answer for fun fact
    for (final question in quiz.questions) {
      final a1 = answers1[question.id];
      final a2 = answers2[question.id];
      if (a1 == a2 && a1 != null) {
        final option = question.options.firstWhere(
          (o) => o.id == a1,
          orElse: () => question.options.first,
        );
        insights.add(CompatibilityInsight(
          type: InsightType.funFact,
          title: 'You Both Agree',
          description:
              'On "${question.question.replaceAll("'", "")}" - ${option.text}',
          emoji: question.emoji ?? '🎯',
          isPositive: true,
        ));
        break;
      }
    }

    // Add a tip
    insights.add(const CompatibilityInsight(
      type: InsightType.tip,
      title: 'Conversation Starter',
      description: 'Ask about their favorite weekend activity!',
      emoji: '💡',
      isPositive: true,
    ));

    return insights;
  }

  @override
  void clearUserData() {
    _results.clear();
    _pendingAnswers.clear();
  }

  @override
  void dispose() {
    _quizController.close();
    _resultController.close();
  }
}

class _ScoreData {
  const _ScoreData({
    required this.overallScore,
    required this.categoryScores,
  });

  final int overallScore;
  final Map<String, int> categoryScores;
}
