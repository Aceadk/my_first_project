import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/social/presentation/bloc/compatibility_quiz_cubit.dart';

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
  State<CompatibilityQuizScreen> createState() =>
      _CompatibilityQuizScreenState();
}

class _CompatibilityQuizScreenState extends State<CompatibilityQuizScreen> {
  @override
  void initState() {
    super.initState();
    final quizId = widget.quizId ?? 'basic_compatibility';
    context.read<CompatibilityQuizCubit>().startQuiz(
      quizId: quizId,
      matchId: widget.matchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;

    return BlocBuilder<CompatibilityQuizCubit, CompatibilityQuizState>(
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: state.quiz?.title ?? 'Compatibility Quiz',
            automaticallyImplyLeading: !state.hasResult,
          ),
          body: Stack(
            children: [
              // Gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? DsColors.backgroundDark
                        : DsColors.backgroundLight,
                  ),
                  child: const Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: DsGradients.meshRadial,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: DsBreakpoints.contentMaxWidth(
                          constraints.maxWidth,
                        ),
                      ),
                      child: _buildContent(context, textColor, state),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color textColor,
    CompatibilityQuizState state,
  ) {
    if (state.isLoading || state.isSubmitting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _buildErrorState(context, textColor, state.errorMessage!);
    }

    if (state.hasResult) {
      return _buildResultView(context, textColor, state);
    }

    if (state.quiz == null) {
      return _buildEmptyState(textColor);
    }

    return _buildQuizContent(context, textColor, state);
  }

  Widget _buildErrorState(
    BuildContext context,
    Color textColor,
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          DsGap.md,
          Text(
            'Something went wrong',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          DsGap.sm,
          Text(
            message,
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
          DsGap.lg,
          GlassOutlinedButton(
            onPressed: () {
              final quizId = widget.quizId ?? 'basic_compatibility';
              context.read<CompatibilityQuizCubit>().startQuiz(
                quizId: quizId,
                matchId: widget.matchId,
              );
            },
            child: const Text('Try Again'),
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
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          DsGap.md,
          Text(
            'Quiz not available',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(
    BuildContext context,
    Color textColor,
    CompatibilityQuizState state,
  ) {
    final cubit = context.read<CompatibilityQuizCubit>();
    final question = state.currentQuestion!;
    final progress = (state.currentQuestionIndex + 1) / state.totalQuestions;
    final isAnswered = state.answers.containsKey(question.id);
    final isLastQuestion = cubit.isLastQuestion;

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
                    'Question ${state.currentQuestionIndex + 1} of ${state.totalQuestions}',
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
                  final isSelected = state.answers[question.id] == option.id;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: DsSpacing.md,
                    ),
                    child: GlassCard(
                      onTap: () => cubit.selectAnswer(question.id, option.id),
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
                                color: isSelected
                                    ? DsColors.primary
                                    : textColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              color: isSelected
                                  ? DsColors.primary
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: DsColors.surfaceLight,
                                  )
                                : null,
                          ),
                          DsGap.mdH,
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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
              if (state.currentQuestionIndex > 0)
                Expanded(
                  child: GlassOutlinedButton(
                    onPressed: cubit.previousQuestion,
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
                      ? (isLastQuestion
                            ? () => _completeQuiz(context, state)
                            : cubit.nextQuestion)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLastQuestion ? 'See Results' : 'Next'),
                      DsGap.smH,
                      Icon(
                        isLastQuestion ? Icons.check : Icons.arrow_forward,
                        size: 18,
                      ),
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

  Future<void> _completeQuiz(
    BuildContext context,
    CompatibilityQuizState state,
  ) async {
    if (state.quiz == null) return;

    final cubit = context.read<CompatibilityQuizCubit>();

    // Simulate partner's answers for demo
    final partnerAnswers = <String, String>{};
    for (final question in state.quiz!.questions) {
      final options = question.options;
      partnerAnswers[question.id] = options[options.length ~/ 2].id;
    }

    await cubit.completeQuiz(
      user1Id: widget.userId,
      user2Id: 'partner_${widget.matchId}',
      user2Answers: partnerAnswers,
    );
  }

  Widget _buildResultView(
    BuildContext context,
    Color textColor,
    CompatibilityQuizState state,
  ) {
    final result = state.result!;

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
                  style: TextStyle(color: DsColors.surfaceLight, fontSize: 16),
                ),
                DsGap.md,
                Text(
                  '${result.overallScore}%',
                  style: const TextStyle(
                    color: DsColors.surfaceLight,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DsGap.sm,
                _buildScoreLabel(result.overallScore ?? 0),
              ],
            ),
          ),
          DsGap.xl,

          // Insights
          if (result.insights.isNotEmpty) ...[
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
            ...result.insights.map((insight) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: DsSpacing.md),
                child: GlassCard(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Row(
                    children: [
                      Text(
                        insight.emoji ?? '💡',
                        style: const TextStyle(fontSize: 32),
                      ),
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
          if (result.categoryScores.isNotEmpty) ...[
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
                children: result.categoryScores.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: TextStyle(color: textColor)),
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
                            valueColor: const AlwaysStoppedAnimation(
                              DsColors.primary,
                            ),
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
            onPressed: () {
              context.read<CompatibilityQuizCubit>().reset();
              Navigator.pop(context);
            },
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
        color: DsColors.surfaceLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DsRadius.round),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DsColors.surfaceLight,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
