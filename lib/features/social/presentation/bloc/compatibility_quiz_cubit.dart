import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';
import 'package:crushhour/features/social/data/models/compatibility_quiz.dart';

/// State for compatibility quiz.
class CompatibilityQuizState extends Equatable {
  const CompatibilityQuizState({
    this.quiz,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.result,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final CompatibilityQuiz? quiz;
  final int currentQuestionIndex;
  final Map<String, String> answers;
  final QuizResult? result;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  List<QuizQuestion> get questions => quiz?.questions ?? [];
  int get totalQuestions => questions.length;
  QuizQuestion? get currentQuestion =>
      currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;
  bool get isComplete => currentQuestionIndex >= totalQuestions;
  double get progress =>
      totalQuestions > 0 ? currentQuestionIndex / totalQuestions : 0;
  bool get hasResult => result != null;

  CompatibilityQuizState copyWith({
    CompatibilityQuiz? quiz,
    int? currentQuestionIndex,
    Map<String, String>? answers,
    QuizResult? result,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CompatibilityQuizState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        quiz,
        currentQuestionIndex,
        answers,
        result,
        isLoading,
        isSubmitting,
        errorMessage,
      ];
}

/// Cubit for managing compatibility quiz state.
class CompatibilityQuizCubit extends Cubit<CompatibilityQuizState> {
  CompatibilityQuizCubit() : super(const CompatibilityQuizState());

  final _service = CompatibilityQuizService.instance;
  String? _currentMatchId;

  /// Get all available quizzes.
  List<CompatibilityQuiz> getAllQuizzes() => _service.getAllQuizzes();

  /// Start a quiz session.
  Future<void> startQuiz({
    required String quizId,
    required String matchId,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      _currentMatchId = matchId;
      final quiz = await _service.startQuiz(
        quizId: quizId,
        matchId: matchId,
      );

      emit(state.copyWith(
        quiz: quiz,
        currentQuestionIndex: 0,
        answers: {},
        result: null,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start quiz',
      ));
    }
  }

  /// Submit an answer for the current question.
  void submitAnswer(String optionId) {
    final question = state.currentQuestion;
    if (question == null || _currentMatchId == null) return;

    _service.submitAnswer(
      matchId: _currentMatchId!,
      questionId: question.id,
      optionId: optionId,
    );

    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[question.id] = optionId;

    emit(state.copyWith(
      answers: newAnswers,
      currentQuestionIndex: state.currentQuestionIndex + 1,
    ));
  }

  /// Complete the quiz and calculate results.
  Future<void> completeQuiz({
    required String user1Id,
    required String user2Id,
    required Map<String, String> user2Answers,
  }) async {
    if (state.quiz == null || _currentMatchId == null) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final result = await _service.completeQuiz(
        quizId: state.quiz!.id,
        matchId: _currentMatchId!,
        user1Id: user1Id,
        user2Id: user2Id,
        user1Answers: state.answers,
        user2Answers: user2Answers,
      );

      emit(state.copyWith(
        result: result,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to complete quiz',
      ));
    }
  }

  /// Get previous quiz results for a match.
  List<QuizResult> getResultsForMatch(String matchId) {
    return _service.getAllResultsForMatch(matchId);
  }

  /// Reset quiz state.
  void reset() {
    _currentMatchId = null;
    emit(const CompatibilityQuizState());
  }
}
