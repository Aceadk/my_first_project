import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';
import 'package:crushhour/features/social/data/models/compatibility_quiz.dart';

/// Screen for taking compatibility quizzes with matches.
class CompatibilityQuizScreen extends StatefulWidget {
  const CompatibilityQuizScreen({
    super.key,
    required this.matchId,
    required this.userId,
    this.quizId,
  });

  final String matchId;
  final String userId;
  final String? quizId;

  @override
  State<CompatibilityQuizScreen> createState() => _CompatibilityQuizScreenState();
}

class _CompatibilityQuizScreenState extends State<CompatibilityQuizScreen> {
  final _service = CompatibilityQuizService.instance;
  CompatibilityQuiz? _quiz;
  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  bool _isLoading = true;
  QuizResult? _result;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      final quizId = widget.quizId ?? 'basic_compatibility';
      final quiz = await _service.startQuiz(
        quizId: quizId,
        matchId: widget.matchId,
      );
      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(String questionId, String optionId) {
    setState(() {
      _answers[questionId] = optionId;
    });
    _service.submitAnswer(
      matchId: widget.matchId,
      questionId: questionId,
      optionId: optionId,
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < (_quiz?.questions.length ?? 0) - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _completeQuiz() async {
    if (_quiz == null) return;

    setState(() => _isLoading = true);

    // Simulate partner's answers for demo
    final partnerAnswers = <String, String>{};
    for (final question in _quiz!.questions) {
      final options = question.options;
      partnerAnswers[question.id] = options[options.length ~/ 2].id;
    }

    try {
      final result = await _service.completeQuiz(
        quizId: _quiz!.id,
        matchId: widget.matchId,
        user1Id: widget.userId,
        user2Id: 'partner_${widget.matchId}',
        user1Answers: _answers,
        user2Answers: partnerAnswers,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _quiz?.title ?? 'Compatibility Quiz',
        automaticallyImplyLeading: _result == null,
      ),
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
              ),
              child: const Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: DsGradients.meshRadial),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _result != null
                    ? _buildResultView(textColor)
                    : _quiz == null
                        ? _buildEmptyState(textColor)
                        : _buildQuizContent(context, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: textColor.withValues(alpha: 0.5)),
          DsGap.md,
          Text(
            'Quiz not available',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context, Color textColor) {
    final question = _quiz!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _quiz!.questions.length;
    final isAnswered = _answers.containsKey(question.id);
    final isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(DsSpacing.lg),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: DsColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              DsGap.sm,
              ClipRRect(
                borderRadius: BorderRadius.circular(DsRadius.round),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: textColor.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(DsColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(DsSpacing.xl),
                  child: Column(
                    children: [
                      if (question.emoji != null)
                        Text(
                          question.emoji!,
                          style: const TextStyle(fontSize: 48),
                        ),
                      DsGap.md,
                      Text(
                        question.question,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (question.category != null) ...[
                        DsGap.md,
                        GlassChip(
                          label: question.category!.displayName,
                          icon: Icons.category,
                        ),
                      ],
                    ],
                  ),
                ),
                DsGap.xl,

                // Options
                ...question.options.map((option) {
                  final isSelected = _answers[question.id] == option.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DsSpacing.md),
                    child: GlassCard(
                      onTap: () => _selectAnswer(question.id, option.id),
                      showGradientBorder: isSelected,
                      padding: const EdgeInsets.all(DsSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? DsColors.primary : textColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              color: isSelected ? DsColors.primary : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          DsGap.mdH,
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(DsSpacing.lg),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: GlassOutlinedButton(
                    onPressed: _previousQuestion,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 18),
                        SizedBox(width: DsSpacing.sm),
                        Text('Back'),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              DsGap.mdH,
              Expanded(
                child: GlassPrimaryButton(
                  onPressed: isAnswered
                      ? (isLastQuestion ? _completeQuiz : _nextQuestion)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLastQuestion ? 'See Results' : 'Next'),
                      DsGap.smH,
                      Icon(isLastQuestion ? Icons.check : Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        children: [
          // Score card
          GlassCardAccent(
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: Column(
              children: [
                const Text(
                  'Compatibility Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                DsGap.md,
                Text(
                  '${_result!.overallScore}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DsGap.sm,
                _buildScoreLabel(_result!.overallScore ?? 0),
              ],
            ),
          ),
          DsGap.xl,

          // Insights
          if (_result!.insights.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Insights',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DsGap.md,
            ..._result!.insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.md),
                child: GlassCard(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Row(
                    children: [
                      Text(insight.emoji ?? '💡', style: const TextStyle(fontSize: 32)),
                      DsGap.mdH,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            DsGap.xs,
                            Text(
                              insight.description,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          DsGap.xl,

          // Category scores
          if (_result!.categoryScores.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category Breakdown',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DsGap.md,
            GlassCard(
              padding: const EdgeInsets.all(DsSpacing.lg),
              child: Column(
                children: _result!.categoryScores.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(color: textColor),
                            ),
                            Text(
                              '${entry.value}%',
                              style: const TextStyle(
                                color: DsColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        DsGap.xs,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DsRadius.round),
                          child: LinearProgressIndicator(
                            value: entry.value / 100,
                            backgroundColor: textColor.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(DsColors.primary),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          DsGap.xl,

          // Action button
          GlassPrimaryButton(
            isExpanded: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreLabel(int score) {
    String label;
    if (score >= 80) {
      label = 'Excellent Match!';
    } else if (score >= 60) {
      label = 'Good Compatibility';
    } else if (score >= 40) {
      label = 'Some Common Ground';
    } else {
      label = 'Opposites Attract?';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DsRadius.round),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
