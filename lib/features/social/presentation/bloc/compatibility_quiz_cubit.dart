import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/social/domain/repositories/compatibility_quiz_repository.dart';
import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';
import 'package:crushhour/core/utils/error_messages.dart';

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
  QuizQuestion? get currentQuestion => currentQuestionIndex < questions.length
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
  CompatibilityQuizCubit({
    required AuthRepository authRepository,
    required CompatibilityQuizRepository quizRepository,
  }) : _authRepository = authRepository,
       _service = quizRepository,
       super(const CompatibilityQuizState()) {
    _authSubscription = _authRepository.authStateChanges().listen((user) {
      if (user == null) {
        _resetState();
      }
    });
  }

  final AuthRepository _authRepository;
  final CompatibilityQuizRepository _service;
  String? _currentMatchId;
  StreamSubscription<CrushUser?>? _authSubscription;

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
      final quiz = await _service.startQuiz(quizId: quizId, matchId: matchId);

      emit(
        state.copyWith(
          quiz: quiz,
          currentQuestionIndex: 0,
          answers: {},
          result: null,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: ErrorMessages.generic),
      );
    }
  }

  /// Select an answer for a question (does not auto-advance).
  void selectAnswer(String questionId, String optionId) {
    if (_currentMatchId == null) return;

    _service.submitAnswer(
      matchId: _currentMatchId!,
      questionId: questionId,
      optionId: optionId,
    );

    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[questionId] = optionId;

    emit(state.copyWith(answers: newAnswers));
  }

  /// Submit an answer for the current question and auto-advance.
  void submitAnswer(String optionId) {
    final question = state.currentQuestion;
    if (question == null) return;

    selectAnswer(question.id, optionId);
    nextQuestion();
  }

  /// Move to the next question.
  void nextQuestion() {
    if (state.currentQuestionIndex < state.totalQuestions - 1) {
      emit(
        state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1),
      );
    }
  }

  /// Move to the previous question.
  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      emit(
        state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1),
      );
    }
  }

  /// Check if current question is answered.
  bool get isCurrentQuestionAnswered {
    final question = state.currentQuestion;
    return question != null && state.answers.containsKey(question.id);
  }

  /// Check if this is the last question.
  bool get isLastQuestion {
    return state.currentQuestionIndex == state.totalQuestions - 1;
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

      emit(state.copyWith(result: result, isSubmitting: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: ErrorMessages.generic,
        ),
      );
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

  void _resetState() {
    _service.clearUserData();
    _currentMatchId = null;
    if (!isClosed) {
      emit(const CompatibilityQuizState());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
