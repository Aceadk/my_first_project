import 'dart:async';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/domain/models/weekly_picks.dart';
import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/weekly_picks_cubit.dart';
import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/domain/models/date_idea.dart';
import 'package:crushhour/features/social/domain/repositories/compatibility_quiz_repository.dart';
import 'package:crushhour/features/social/domain/repositories/date_idea_repository.dart';
import 'package:crushhour/features/social/presentation/bloc/compatibility_quiz_cubit.dart';
import 'package:crushhour/features/social/presentation/bloc/date_ideas_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

CrushUser _authUser(String id) => CrushUser(
  id: id,
  phoneNumber: '+10000000000',
  isEmailVerified: true,
  isPhoneVerified: true,
  isIdVerified: false,
  plan: SubscriptionPlan.free,
);

class _TestAuthRepository implements AuthRepository {
  final _controller = StreamController<CrushUser?>.broadcast();

  void emitAuth(CrushUser? user) => _controller.add(user);
  Future<void> dispose() => _controller.close();

  @override
  bool get isVerificationBypassEnabled => false;
  @override
  bool get supportsUsernameLogin => false;
  @override
  bool get supportsAppleSignIn => false;
  @override
  Future<void> bootstrapSession() async {}
  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedWeeklyPicksRepository implements WeeklyPicksRepository {
  final _controller = StreamController<WeeklyPicks>.broadcast();
  WeeklyPicks? _current;

  @override
  Stream<WeeklyPicks> get picksStream => _controller.stream;
  @override
  WeeklyPicks? get currentPicks => _current;
  @override
  bool get hasUnseenPicks => (_current?.unseenCount ?? 0) > 0;
  @override
  int get unseenCount => _current?.unseenCount ?? 0;
  @override
  bool get isCurrentWeek => _current?.isCurrentWeek ?? false;

  @override
  Future<WeeklyPicks> loadPicks(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final now = DateTime(2026, 3, 7);
    _current = WeeklyPicks(
      userId: userId,
      weekStart: DateTime(2026, 3, 2),
      weekEnd: DateTime(2026, 3, 9),
      picks: const [
        WeeklyPick(
          id: 'p1',
          profileId: 'profile-1',
          reason: PickReason.topPick,
        ),
      ],
      refreshedAt: now,
    );
    _controller.add(_current!);
    return _current!;
  }

  @override
  Future<void> markPickViewed(String pickId) async {}
  @override
  Future<void> markPickLiked(String pickId) async {}
  @override
  bool isPickViewed(String pickId) => false;
  @override
  bool isPickLiked(String pickId) => false;
  @override
  List<WeeklyPick> getUnviewedPicks() => _current?.picks ?? const [];
  @override
  List<WeeklyPick> getAllPicks() => _current?.picks ?? const [];
  @override
  Duration getTimeUntilRefresh() => Duration.zero;
  @override
  String getNewPicksTimeDisplay() => '';

  @override
  void clearUserData() {
    _current = null;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _DelayedDateIdeaRepository implements DateIdeaRepository {
  final _ideasController = StreamController<List<DateIdea>>.broadcast();
  final List<DateIdea> _savedIdeas = [];
  List<DateIdea> _suggestedIdeas = [];

  static const _ideas = [
    DateIdea(
      id: 'idea-1',
      title: 'Coffee Walk',
      description: 'Take a walk with coffee.',
      category: DateCategory.casual,
      emoji: '☕',
      estimatedCost: DateCostLevel.free,
    ),
  ];

  @override
  Stream<List<DateIdea>> get ideasStream => _ideasController.stream;
  @override
  List<DateIdea> get savedIdeas => _savedIdeas;
  @override
  List<DateIdea> get suggestedIdeas => _suggestedIdeas;

  @override
  List<DateIdea> getAllIdeas() => _ideas;
  @override
  List<DateIdea> getIdeasByCategory(DateCategory category) =>
      _ideas.where((idea) => idea.category == category).toList();
  @override
  List<DateIdea> getIdeasForDateType(DateType type) => _ideas;
  @override
  List<DateIdea> getIdeasByBudget(DateCostLevel maxCost) => _ideas;
  @override
  List<DateIdea> getRandomSuggestions(int count) => _ideas.take(count).toList();

  @override
  Future<List<DateIdea>> getPersonalizedSuggestions({
    DateType? dateType,
    DateCostLevel? maxBudget,
    List<DateCategory>? preferredCategories,
    Season? currentSeason,
    int count = 5,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _suggestedIdeas = _ideas.take(count).toList();
    _ideasController.add(_suggestedIdeas);
    return _suggestedIdeas;
  }

  @override
  Future<void> saveIdea(DateIdea idea) async {
    _savedIdeas.add(idea);
  }

  @override
  Future<void> removeSavedIdea(String ideaId) async {
    _savedIdeas.removeWhere((idea) => idea.id == ideaId);
  }

  @override
  bool isIdeaSaved(String ideaId) =>
      _savedIdeas.any((idea) => idea.id == ideaId);

  @override
  Future<void> sendIdeaToMatch({
    required String matchId,
    required DateIdea idea,
    String? personalMessage,
  }) async {}

  @override
  Season getCurrentSeason() => Season.spring;

  @override
  List<DateIdea> searchIdeas(String query) => _ideas;

  @override
  void clearUserData() {
    _savedIdeas.clear();
    _suggestedIdeas = [];
    _ideasController.add(_suggestedIdeas);
  }

  @override
  void dispose() {
    _ideasController.close();
  }
}

class _DelayedCompatibilityQuizRepository
    implements CompatibilityQuizRepository {
  @override
  Stream<CompatibilityQuiz> get quizStream => const Stream.empty();
  @override
  Stream<QuizResult> get resultStream => const Stream.empty();

  static const _quiz = CompatibilityQuiz(
    id: 'quiz-1',
    title: 'Compatibility',
    description: 'Test quiz',
    estimatedMinutes: 2,
    questions: [
      QuizQuestion(
        id: 'q1',
        question: 'Question 1?',
        options: [
          QuizOption(id: 'a', text: 'A'),
          QuizOption(id: 'b', text: 'B'),
        ],
      ),
    ],
  );

  @override
  List<CompatibilityQuiz> getAllQuizzes() => const [_quiz];

  @override
  CompatibilityQuiz? getQuiz(String quizId) => _quiz;

  @override
  Future<CompatibilityQuiz> startQuiz({
    required String quizId,
    required String matchId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _quiz;
  }

  @override
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  }) async {}

  @override
  Future<QuizResult> completeQuiz({
    required String quizId,
    required String matchId,
    required String user1Id,
    required String user2Id,
    required Map<String, String> user1Answers,
    required Map<String, String> user2Answers,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return QuizResult(
      quizId: quizId,
      user1Id: user1Id,
      user2Id: user2Id,
      user1Answers: user1Answers,
      user2Answers: user2Answers,
      completedAt: DateTime(2026, 3, 7),
      overallScore: 50,
    );
  }

  @override
  QuizResult? getResult(String matchId, String quizId) => null;
  @override
  List<QuizResult> getAllResultsForMatch(String matchId) => const [];
  @override
  Future<void> inviteToQuiz({
    required String matchId,
    required String quizId,
    String? message,
  }) async {}
  @override
  void clearUserData() {}
  @override
  void dispose() {}
}

void main() {
  group('Async state emission guards', () {
    test(
      'WeeklyPicksCubit ignores stale load completion after logout',
      () async {
        final auth = _TestAuthRepository();
        final repo = _DelayedWeeklyPicksRepository();
        final cubit = WeeklyPicksCubit(
          authRepository: auth,
          weeklyPicksRepository: repo,
        );

        final loadFuture = cubit.loadPicks('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        auth.emitAuth(null);

        await loadFuture;
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(cubit.state, const WeeklyPicksState());

        await cubit.close();
        await auth.dispose();
        repo.dispose();
      },
    );

    test('WeeklyPicksCubit resets when authenticated user switches', () async {
      final auth = _TestAuthRepository();
      final repo = _DelayedWeeklyPicksRepository();
      final cubit = WeeklyPicksCubit(
        authRepository: auth,
        weeklyPicksRepository: repo,
      );

      await cubit.loadPicks('user-1');
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(cubit.state.picks, isNotNull);

      auth.emitAuth(_authUser('user-a'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.picks, isNotNull);

      auth.emitAuth(_authUser('user-b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state, const WeeklyPicksState());

      await cubit.close();
      await auth.dispose();
      repo.dispose();
    });

    test('DateIdeasCubit ignores stale suggestions after logout', () async {
      final auth = _TestAuthRepository();
      final repo = _DelayedDateIdeaRepository();
      final cubit = DateIdeasCubit(
        authRepository: auth,
        dateIdeaRepository: repo,
      );

      final future = cubit.getPersonalizedSuggestions(count: 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      auth.emitAuth(null);

      await future;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state, const DateIdeasState());

      await cubit.close();
      await auth.dispose();
      repo.dispose();
    });

    test('DateIdeasCubit resets when authenticated user switches', () async {
      final auth = _TestAuthRepository();
      final repo = _DelayedDateIdeaRepository();
      final cubit = DateIdeasCubit(
        authRepository: auth,
        dateIdeaRepository: repo,
      );

      await cubit.loadIdeas();
      expect(cubit.state.ideas, isNotEmpty);

      auth.emitAuth(_authUser('user-a'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.ideas, isNotEmpty);

      auth.emitAuth(_authUser('user-b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state, const DateIdeasState());

      await cubit.close();
      await auth.dispose();
      repo.dispose();
    });

    test(
      'CompatibilityQuizCubit ignores stale startQuiz completion after logout',
      () async {
        final auth = _TestAuthRepository();
        final repo = _DelayedCompatibilityQuizRepository();
        final cubit = CompatibilityQuizCubit(
          authRepository: auth,
          quizRepository: repo,
        );

        final future = cubit.startQuiz(quizId: 'quiz-1', matchId: 'match-1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        auth.emitAuth(null);

        await future;
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(cubit.state, const CompatibilityQuizState());

        await cubit.close();
        await auth.dispose();
        repo.dispose();
      },
    );

    test(
      'CompatibilityQuizCubit resets when authenticated user switches',
      () async {
        final auth = _TestAuthRepository();
        final repo = _DelayedCompatibilityQuizRepository();
        final cubit = CompatibilityQuizCubit(
          authRepository: auth,
          quizRepository: repo,
        );

        await cubit.startQuiz(quizId: 'quiz-1', matchId: 'match-1');
        await Future<void>.delayed(const Duration(milliseconds: 160));
        expect(cubit.state.quiz, isNotNull);

        auth.emitAuth(_authUser('user-a'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(cubit.state.quiz, isNotNull);

        auth.emitAuth(_authUser('user-b'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(cubit.state, const CompatibilityQuizState());

        await cubit.close();
        await auth.dispose();
        repo.dispose();
      },
    );

    test(
      'DateIdeasCubit does not throw when async completion resolves after close',
      () async {
        final auth = _TestAuthRepository();
        final repo = _DelayedDateIdeaRepository();
        final cubit = DateIdeasCubit(
          authRepository: auth,
          dateIdeaRepository: repo,
        );

        final future = cubit.getPersonalizedSuggestions(count: 1);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await cubit.close();

        await expectLater(future, completes);

        await auth.dispose();
        repo.dispose();
      },
    );
  });
}
