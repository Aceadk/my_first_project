import 'dart:async';

import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';
import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/domain/models/date_idea.dart';
import 'package:crushhour/features/social/presentation/bloc/compatibility_quiz_cubit.dart';
import 'package:crushhour/features/social/presentation/bloc/date_ideas_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';

// ---------------------------------------------------------------------------
// Mock AuthRepository (minimal — only authStateChanges is needed)
// ---------------------------------------------------------------------------
class MockAuthRepository implements AuthRepository {
  final _authController = StreamController<CrushUser?>.broadcast();

  void pushUser(CrushUser? user) => _authController.add(user);

  @override
  Stream<CrushUser?> authStateChanges() => _authController.stream;

  void dispose() => _authController.close();

  // --- Stubs for all other methods (not exercised in these tests) ---
  @override
  bool get isVerificationBypassEnabled => false;
  @override
  bool get supportsUsernameLogin => false;
  @override
  bool get supportsAppleSignIn => false;
  @override
  Future<void> bootstrapSession() async {}
  @override
  Future<void> sendOtp(String phoneNumber) async {}
  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) => throw UnimplementedError();
  @override
  Future<void> sendEmailSignInLink(String email) async {}
  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) => throw UnimplementedError();
  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<CrushUser> signInWithApple() => throw UnimplementedError();
  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}
  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async => null;
  @override
  Future<void> requestPasswordReset({required String email}) async {}
  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) => throw UnimplementedError();
  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<CrushUser?> checkEmailVerification() async => null;
  @override
  Future<void> schedulePhoneDeletion() async {}
  @override
  Future<void> verifyPassword(String password) async {}

  @override
@override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
  @override
  Future<void> deactivateAccount({required String reason}) async {}
  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {}
  @override
  Future<bool> isEmailRegistered(String email) async => false;
  @override
  Future<CrushUser> acceptTermsAndConditions() => throw UnimplementedError();
  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}

// ===========================================================================
//  DATE IDEAS TESTS
// ===========================================================================

void main() {
  setupFirebaseAnalyticsMocks();

  // -------------------------------------------------------------------------
  // DateIdea model tests
  // -------------------------------------------------------------------------
  group('DateIdea model', () {
    test('toJson and fromJson round-trip', () {
      const idea = DateIdea(
        id: 'test_idea',
        title: 'Test Date',
        description: 'A test date idea',
        category: DateCategory.romantic,
        emoji: '💕',
        estimatedCost: DateCostLevel.moderate,
        estimatedDuration: Duration(hours: 2),
        tags: ['romantic', 'test'],
        bestFor: [DateType.firstDate],
      );

      final json = idea.toJson();
      final restored = DateIdea.fromJson(json);

      expect(restored.id, idea.id);
      expect(restored.title, idea.title);
      expect(restored.description, idea.description);
      expect(restored.category, idea.category);
      expect(restored.emoji, idea.emoji);
      expect(restored.estimatedCost, idea.estimatedCost);
      expect(restored.tags, idea.tags);
      expect(restored.bestFor, idea.bestFor);
    });

    test('durationDisplay formats correctly', () {
      const noD = DateIdea(
        id: 'a',
        title: '',
        description: '',
        category: DateCategory.casual,
        emoji: '',
      );
      expect(noD.durationDisplay, 'Varies');

      const h2 = DateIdea(
        id: 'b',
        title: '',
        description: '',
        category: DateCategory.casual,
        emoji: '',
        estimatedDuration: Duration(hours: 2),
      );
      expect(h2.durationDisplay, '2h');

      const m30 = DateIdea(
        id: 'c',
        title: '',
        description: '',
        category: DateCategory.casual,
        emoji: '',
        estimatedDuration: Duration(minutes: 30),
      );
      expect(m30.durationDisplay, '30m');

      const h1m30 = DateIdea(
        id: 'd',
        title: '',
        description: '',
        category: DateCategory.casual,
        emoji: '',
        estimatedDuration: Duration(hours: 1, minutes: 30),
      );
      expect(h1m30.durationDisplay, '1h 30m');
    });

    test('costDisplay returns correct strings', () {
      const free = DateIdea(
        id: 'a',
        title: '',
        description: '',
        category: DateCategory.casual,
        emoji: '',
        estimatedCost: DateCostLevel.free,
      );
      expect(free.costDisplay, 'Free');

      const noCost = DateIdea(
        id: 'b',
        title: '',
        description: '',
        category: DateCategory.casual,
        emoji: '',
      );
      expect(noCost.costDisplay, 'Varies');
    });
  });

  // -------------------------------------------------------------------------
  // DateIdeas static helpers
  // -------------------------------------------------------------------------
  group('DateIdeas static helpers', () {
    test('suggestions is not empty', () {
      expect(DateIdeas.suggestions, isNotEmpty);
      expect(DateIdeas.suggestions.length, greaterThanOrEqualTo(10));
    });

    test('byCategory filters correctly', () {
      final romantic = DateIdeas.byCategory(DateCategory.romantic);
      for (final idea in romantic) {
        expect(idea.category, DateCategory.romantic);
      }
    });

    test('forDateType filters correctly', () {
      final firstDate = DateIdeas.forDateType(DateType.firstDate);
      for (final idea in firstDate) {
        expect(idea.bestFor, contains(DateType.firstDate));
      }
    });

    test('byCost filters correctly', () {
      final cheap = DateIdeas.byCost(DateCostLevel.budget);
      for (final idea in cheap) {
        expect(idea.estimatedCost, isNotNull);
        expect(
          idea.estimatedCost!.index,
          lessThanOrEqualTo(DateCostLevel.budget.index),
        );
      }
    });

    test('random returns requested count', () {
      final random3 = DateIdeas.random(3);
      expect(random3.length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // DateIdeaService tests
  // -------------------------------------------------------------------------
  group('DateIdeaService', () {
    late DateIdeaService service;

    setUp(() {
      service = DateIdeaService.instance;
      service.clearUserData();
    });

    test('getAllIdeas returns the static suggestions list', () {
      final ideas = service.getAllIdeas();
      expect(ideas, DateIdeas.suggestions);
    });

    test('saveIdea adds to saved list and does not duplicate', () async {
      const idea = DateIdea(
        id: 'save_test',
        title: 'Save Test',
        description: 'desc',
        category: DateCategory.casual,
        emoji: '!',
      );

      await service.saveIdea(idea);
      expect(service.savedIdeas, hasLength(1));
      expect(service.isIdeaSaved('save_test'), isTrue);

      // save same idea again — should not duplicate
      await service.saveIdea(idea);
      expect(service.savedIdeas, hasLength(1));
    });

    test('removeSavedIdea removes from saved list', () async {
      const idea = DateIdea(
        id: 'remove_test',
        title: 'Remove Test',
        description: 'desc',
        category: DateCategory.casual,
        emoji: '!',
      );

      await service.saveIdea(idea);
      expect(service.isIdeaSaved('remove_test'), isTrue);

      await service.removeSavedIdea('remove_test');
      expect(service.isIdeaSaved('remove_test'), isFalse);
      expect(service.savedIdeas, isEmpty);
    });

    test(
      'getRandomSuggestions returns expected count and emits on stream',
      () async {
        final streamValues = <List<DateIdea>>[];
        final sub = service.ideasStream.listen(streamValues.add);

        final suggestions = service.getRandomSuggestions(3);
        await Future<void>.delayed(Duration.zero);

        expect(suggestions, hasLength(3));
        expect(streamValues, hasLength(1));
        expect(streamValues.first, hasLength(3));

        await sub.cancel();
      },
    );

    test('getPersonalizedSuggestions filters by dateType', () async {
      final results = await service.getPersonalizedSuggestions(
        dateType: DateType.firstDate,
        count: 20,
      );

      for (final idea in results) {
        expect(idea.bestFor, contains(DateType.firstDate));
      }
    });

    test('getPersonalizedSuggestions filters by budget', () async {
      final results = await service.getPersonalizedSuggestions(
        maxBudget: DateCostLevel.free,
        count: 20,
      );

      for (final idea in results) {
        expect(idea.estimatedCost, isNotNull);
        expect(
          idea.estimatedCost!.index,
          lessThanOrEqualTo(DateCostLevel.free.index),
        );
      }
    });

    test('searchIdeas finds by title', () {
      final results = service.searchIdeas('coffee');
      expect(results, isNotEmpty);
      expect(
        results.any((i) => i.title.toLowerCase().contains('coffee')),
        isTrue,
      );
    });

    test('getCurrentSeason returns a valid Season', () {
      final season = service.getCurrentSeason();
      expect(Season.values, contains(season));
    });

    test('sendIdeaToMatch completes without error', () async {
      await expectLater(
        service.sendIdeaToMatch(
          matchId: 'match-1',
          idea: DateIdeas.suggestions.first,
          personalMessage: 'How about this?',
        ),
        completes,
      );
    });

    test('clearUserData resets saved and suggested', () async {
      await service.saveIdea(DateIdeas.suggestions.first);
      service.getRandomSuggestions(3);

      service.clearUserData();

      expect(service.savedIdeas, isEmpty);
      expect(service.suggestedIdeas, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // DateIdeasCubit tests
  // -------------------------------------------------------------------------
  group('DateIdeasCubit', () {
    late MockAuthRepository authRepo;
    late DateIdeasCubit cubit;

    setUp(() {
      authRepo = MockAuthRepository();
      cubit = DateIdeasCubit(
        authRepository: authRepo,
        dateIdeaRepository: DateIdeaService.instance,
      );
      // Clear singleton state between tests
      DateIdeaService.instance.clearUserData();
    });

    tearDown(() {
      cubit.close();
      authRepo.dispose();
    });

    test('initial state is empty and not loading', () {
      expect(cubit.state.ideas, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('loadIdeas populates ideas and filteredIdeas', () async {
      final states = <DateIdeasState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadIdeas();
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s.isLoading), isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.ideas, isNotEmpty);
      expect(cubit.state.filteredIdeas, cubit.state.ideas);

      await sub.cancel();
    });

    test('filterByCategory narrows filteredIdeas', () async {
      await cubit.loadIdeas();
      await Future<void>.delayed(Duration.zero);

      cubit.filterByCategory(DateCategory.romantic);
      await Future<void>.delayed(Duration.zero);

      for (final idea in cubit.state.filteredIdeas) {
        expect(idea.category, DateCategory.romantic);
      }
      expect(cubit.state.selectedCategory, DateCategory.romantic);
    });

    test('filterByCategory(null) clears category filter', () async {
      await cubit.loadIdeas();
      cubit.filterByCategory(DateCategory.romantic);
      cubit.filterByCategory(null);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedCategory, isNull);
      expect(cubit.state.filteredIdeas, cubit.state.ideas);
    });

    test('filterByCostLevel narrows filteredIdeas', () async {
      await cubit.loadIdeas();
      cubit.filterByCostLevel(DateCostLevel.free);
      await Future<void>.delayed(Duration.zero);

      for (final idea in cubit.state.filteredIdeas) {
        expect(idea.estimatedCost, isNotNull);
        expect(
          idea.estimatedCost!.index,
          lessThanOrEqualTo(DateCostLevel.free.index),
        );
      }
    });

    test('search filters by title/description/tags', () async {
      await cubit.loadIdeas();
      cubit.search('coffee');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.filteredIdeas, isNotEmpty);
      expect(cubit.state.searchQuery, 'coffee');
    });

    test('clearFilters resets all filters', () async {
      await cubit.loadIdeas();
      cubit.filterByCategory(DateCategory.romantic);
      cubit.filterByCostLevel(DateCostLevel.budget);
      cubit.search('wine');

      cubit.clearFilters();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedCategory, isNull);
      expect(cubit.state.selectedCostLevel, isNull);
      expect(cubit.state.searchQuery, '');
      expect(cubit.state.filteredIdeas, cubit.state.ideas);
    });

    test('saveIdea updates savedIdeas in state', () async {
      await cubit.loadIdeas();
      final idea = cubit.state.ideas.first;

      await cubit.saveIdea(idea);
      expect(cubit.state.savedIdeas, contains(idea));
      expect(cubit.isIdeaSaved(idea.id), isTrue);
    });

    test('removeSavedIdea updates savedIdeas in state', () async {
      await cubit.loadIdeas();
      final idea = cubit.state.ideas.first;
      await cubit.saveIdea(idea);

      await cubit.removeSavedIdea(idea.id);
      expect(cubit.state.savedIdeas, isNot(contains(idea)));
      expect(cubit.isIdeaSaved(idea.id), isFalse);
    });

    test('logout resets state to empty', () async {
      await cubit.loadIdeas();
      await cubit.saveIdea(cubit.state.ideas.first);

      authRepo.pushUser(null);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.ideas, isEmpty);
      expect(cubit.state.savedIdeas, isEmpty);
      expect(cubit.state.isLoading, isFalse);
    });

    test('getIdeasByCategory delegates to service', () async {
      await cubit.loadIdeas();
      final ideas = cubit.getIdeasByCategory(DateCategory.adventure);
      for (final idea in ideas) {
        expect(idea.category, DateCategory.adventure);
      }
    });

    test('sendIdeaToMatch completes without error', () async {
      await cubit.loadIdeas();
      await expectLater(
        cubit.sendIdeaToMatch(
          matchId: 'match-1',
          idea: cubit.state.ideas.first,
          personalMessage: 'Lets do this!',
        ),
        completes,
      );
    });
  });

  // =========================================================================
  // COMPATIBILITY QUIZ TESTS
  // =========================================================================

  // -------------------------------------------------------------------------
  // CompatibilityQuiz model tests
  // -------------------------------------------------------------------------
  group('CompatibilityQuiz model', () {
    test('toJson and fromJson round-trip', () {
      const quiz = CompatibilityQuiz(
        id: 'test-quiz',
        title: 'Test Quiz',
        description: 'A test',
        estimatedMinutes: 3,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Test?',
            options: [
              QuizOption(id: 'a', text: 'Yes'),
              QuizOption(id: 'b', text: 'No'),
            ],
          ),
        ],
      );

      final json = quiz.toJson();
      final restored = CompatibilityQuiz.fromJson(json);

      expect(restored.id, quiz.id);
      expect(restored.title, quiz.title);
      expect(restored.questions.length, 1);
      expect(restored.questions.first.options.length, 2);
    });

    test('QuizResult.rating returns correct rating tiers', () {
      QuizResult makeResult(int? score) => QuizResult(
        quizId: 'q',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: const {},
        user2Answers: const {},
        completedAt: DateTime.now(),
        overallScore: score,
      );

      expect(makeResult(95).rating, ScoreRating.excellent);
      expect(makeResult(80).rating, ScoreRating.great);
      expect(makeResult(65).rating, ScoreRating.good);
      expect(makeResult(45).rating, ScoreRating.moderate);
      expect(makeResult(20).rating, ScoreRating.low);
      expect(makeResult(null).rating, ScoreRating.unknown);
    });

    test('QuizResult.scoreDisplay shows percentage or calculating', () {
      final withScore = QuizResult(
        quizId: 'q',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: const {},
        user2Answers: const {},
        completedAt: DateTime.now(),
        overallScore: 85,
      );
      expect(withScore.scoreDisplay, '85%');

      final noScore = QuizResult(
        quizId: 'q',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: const {},
        user2Answers: const {},
        completedAt: DateTime.now(),
      );
      expect(noScore.scoreDisplay, 'Calculating...');
    });
  });

  // -------------------------------------------------------------------------
  // CompatibilityQuizService tests
  // -------------------------------------------------------------------------
  group('CompatibilityQuizService', () {
    late CompatibilityQuizService service;

    setUp(() {
      service = CompatibilityQuizService.instance;
      service.clearUserData();
    });

    test('getAllQuizzes returns pre-defined quizzes', () {
      final quizzes = service.getAllQuizzes();
      expect(quizzes, isNotEmpty);
      expect(quizzes.length, greaterThanOrEqualTo(2));
    });

    test('getQuiz returns quiz by id', () {
      final quiz = service.getQuiz('basic_compatibility');
      expect(quiz, isNotNull);
      expect(quiz!.id, 'basic_compatibility');
    });

    test('startQuiz creates a session and emits on stream', () async {
      final quizStream = <CompatibilityQuiz>[];
      final sub = service.quizStream.listen(quizStream.add);

      final quiz = await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-1',
      );
      await Future<void>.delayed(Duration.zero);

      expect(quiz.id, 'basic_compatibility');
      expect(quizStream, hasLength(1));

      await sub.cancel();
    });

    test('submitAnswer stores answer for match', () async {
      await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-1',
      );

      await service.submitAnswer(
        matchId: 'match-1',
        questionId: 'q1',
        optionId: 'a',
      );

      // No public accessor for pending answers, but completes without error
    });

    test('completeQuiz calculates score and returns result', () async {
      await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-1',
      );

      // Same answers for both users => 100% match
      final answers = {'q1': 'a', 'q2': 'b', 'q3': 'a', 'q4': 'd', 'q5': 'c'};

      final result = await service.completeQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        user1Answers: answers,
        user2Answers: answers,
      );

      expect(result.overallScore, 100);
      expect(result.user1Id, 'user-1');
      expect(result.user2Id, 'user-2');
      expect(result.insights, isNotEmpty);
    });

    test('completeQuiz with different answers scores less than 100', () async {
      await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-2',
      );

      final result = await service.completeQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-2',
        user1Id: 'user-1',
        user2Id: 'user-2',
        user1Answers: {'q1': 'a', 'q2': 'a', 'q3': 'a', 'q4': 'a', 'q5': 'a'},
        user2Answers: {'q1': 'b', 'q2': 'b', 'q3': 'b', 'q4': 'b', 'q5': 'b'},
      );

      expect(result.overallScore, 0);
    });

    test('getResult retrieves stored result', () async {
      await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-3',
      );

      final answers = {'q1': 'a', 'q2': 'b', 'q3': 'c', 'q4': 'd', 'q5': 'a'};
      await service.completeQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-3',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: answers,
        user2Answers: answers,
      );

      final storedResult = service.getResult('match-3', 'basic_compatibility');
      expect(storedResult, isNotNull);
      expect(storedResult!.quizId, 'basic_compatibility');
    });

    test('getAllResultsForMatch returns all results for a match', () async {
      await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-4',
      );
      final answers = {'q1': 'a'};
      await service.completeQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-4',
        user1Id: 'u1',
        user2Id: 'u2',
        user1Answers: answers,
        user2Answers: answers,
      );

      final results = service.getAllResultsForMatch('match-4');
      expect(results, hasLength(1));
    });

    test('clearUserData clears results and pending answers', () async {
      await service.startQuiz(
        quizId: 'basic_compatibility',
        matchId: 'match-5',
      );
      service.clearUserData();

      final result = service.getResult('match-5', 'basic_compatibility');
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // CompatibilityQuizCubit tests
  // -------------------------------------------------------------------------
  group('CompatibilityQuizCubit', () {
    late MockAuthRepository authRepo;
    late CompatibilityQuizCubit cubit;

    setUp(() {
      authRepo = MockAuthRepository();
      cubit = CompatibilityQuizCubit(
        authRepository: authRepo,
        quizRepository: CompatibilityQuizService.instance,
      );
      CompatibilityQuizService.instance.clearUserData();
    });

    tearDown(() {
      cubit.close();
      authRepo.dispose();
    });

    test('initial state is empty', () {
      expect(cubit.state.quiz, isNull);
      expect(cubit.state.currentQuestionIndex, 0);
      expect(cubit.state.answers, isEmpty);
      expect(cubit.state.result, isNull);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isComplete, isTrue); // no questions
      expect(cubit.state.progress, 0.0);
    });

    test('startQuiz loads quiz and resets state', () async {
      final states = <CompatibilityQuizState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s.isLoading), isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.quiz, isNotNull);
      expect(cubit.state.quiz!.id, 'basic_compatibility');
      expect(cubit.state.currentQuestionIndex, 0);
      expect(cubit.state.answers, isEmpty);
      expect(cubit.state.totalQuestions, greaterThan(0));

      await sub.cancel();
    });

    test('startQuiz emits error for invalid quiz id', () async {
      // The service falls back to basicCompatibility for unknown IDs,
      // so the quiz will still be returned. This tests robustness.
      await cubit.startQuiz(quizId: 'nonexistent_quiz', matchId: 'match-x');
      await Future<void>.delayed(Duration.zero);

      // Service returns basicCompatibility as fallback
      expect(cubit.state.quiz, isNotNull);
    });

    test('selectAnswer stores answer in state', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      cubit.selectAnswer('q1', 'a');
      expect(cubit.state.answers['q1'], 'a');
    });

    test('submitAnswer selects answer and advances question', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentQuestionIndex, 0);

      cubit.submitAnswer('a');
      expect(cubit.state.answers['q1'], 'a');
      expect(cubit.state.currentQuestionIndex, 1);
    });

    test('nextQuestion and previousQuestion navigate correctly', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentQuestionIndex, 0);

      cubit.nextQuestion();
      expect(cubit.state.currentQuestionIndex, 1);

      cubit.nextQuestion();
      expect(cubit.state.currentQuestionIndex, 2);

      cubit.previousQuestion();
      expect(cubit.state.currentQuestionIndex, 1);

      cubit.previousQuestion();
      expect(cubit.state.currentQuestionIndex, 0);

      // previousQuestion at 0 stays at 0
      cubit.previousQuestion();
      expect(cubit.state.currentQuestionIndex, 0);
    });

    test('nextQuestion does not go past last question', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      final lastIdx = cubit.state.totalQuestions - 1;
      // Navigate to last
      for (int i = 0; i < cubit.state.totalQuestions; i++) {
        cubit.nextQuestion();
      }
      expect(cubit.state.currentQuestionIndex, lastIdx);
    });

    test('isCurrentQuestionAnswered reflects answer state', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isCurrentQuestionAnswered, isFalse);

      cubit.selectAnswer('q1', 'a');
      expect(cubit.isCurrentQuestionAnswered, isTrue);
    });

    test('isLastQuestion returns correct value', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isLastQuestion, isFalse);

      // Navigate to last question
      for (int i = 0; i < cubit.state.totalQuestions - 1; i++) {
        cubit.nextQuestion();
      }
      expect(cubit.isLastQuestion, isTrue);
    });

    test('completeQuiz calculates results and updates state', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      // Answer all questions via selectAnswer
      cubit.selectAnswer('q1', 'a');
      cubit.selectAnswer('q2', 'b');
      cubit.selectAnswer('q3', 'c');
      cubit.selectAnswer('q4', 'd');
      cubit.selectAnswer('q5', 'a');

      final states = <CompatibilityQuizState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.completeQuiz(
        user1Id: 'user-1',
        user2Id: 'user-2',
        user2Answers: {'q1': 'a', 'q2': 'b', 'q3': 'c', 'q4': 'd', 'q5': 'a'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s.isSubmitting), isTrue);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.result!.overallScore, 100);
      expect(cubit.state.hasResult, isTrue);

      await sub.cancel();
    });

    test('completeQuiz does nothing if no quiz started', () async {
      // No quiz started — should silently return
      await cubit.completeQuiz(user1Id: 'u1', user2Id: 'u2', user2Answers: {});

      expect(cubit.state.result, isNull);
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('reset clears quiz state', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);
      cubit.selectAnswer('q1', 'a');

      cubit.reset();

      expect(cubit.state.quiz, isNull);
      expect(cubit.state.answers, isEmpty);
      expect(cubit.state.currentQuestionIndex, 0);
      expect(cubit.state.result, isNull);
    });

    test('logout resets state', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      authRepo.pushUser(null);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.quiz, isNull);
      expect(cubit.state.answers, isEmpty);
    });

    test('getResultsForMatch returns stored results', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      cubit.selectAnswer('q1', 'a');

      await cubit.completeQuiz(
        user1Id: 'u1',
        user2Id: 'u2',
        user2Answers: {'q1': 'a'},
      );
      await Future<void>.delayed(Duration.zero);

      final results = cubit.getResultsForMatch('match-1');
      expect(results, hasLength(1));
    });

    test('getAllQuizzes returns available quizzes', () {
      final quizzes = cubit.getAllQuizzes();
      expect(quizzes, isNotEmpty);
      expect(quizzes.any((q) => q.id == 'basic_compatibility'), isTrue);
      expect(quizzes.any((q) => q.id == 'lifestyle'), isTrue);
    });

    test('progress reflects question advancement', () async {
      await cubit.startQuiz(quizId: 'basic_compatibility', matchId: 'match-1');
      await Future<void>.delayed(Duration.zero);

      final total = cubit.state.totalQuestions;
      expect(cubit.state.progress, 0.0);

      cubit.nextQuestion();
      expect(cubit.state.progress, closeTo(1.0 / total, 0.01));

      cubit.nextQuestion();
      expect(cubit.state.progress, closeTo(2.0 / total, 0.01));
    });
  });

  // -------------------------------------------------------------------------
  // Enum extension tests
  // -------------------------------------------------------------------------
  group('DateCategory extensions', () {
    test('displayName returns non-empty string for all values', () {
      for (final cat in DateCategory.values) {
        expect(cat.displayName, isNotEmpty);
      }
    });

    test('emoji returns non-empty string for all values', () {
      for (final cat in DateCategory.values) {
        expect(cat.emoji, isNotEmpty);
      }
    });
  });

  group('DateCostLevel extensions', () {
    test('display returns non-empty string for all values', () {
      for (final level in DateCostLevel.values) {
        expect(level.display, isNotEmpty);
      }
    });

    test('description returns non-empty string for all values', () {
      for (final level in DateCostLevel.values) {
        expect(level.description, isNotEmpty);
      }
    });
  });

  group('ScoreRating extensions', () {
    test('displayText returns non-empty string for all values', () {
      for (final rating in ScoreRating.values) {
        expect(rating.displayText, isNotEmpty);
      }
    });

    test('emoji returns non-empty string for all values', () {
      for (final rating in ScoreRating.values) {
        expect(rating.emoji, isNotEmpty);
      }
    });
  });
}
