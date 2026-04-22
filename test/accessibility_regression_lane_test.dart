import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/basic_info_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';
import 'package:crushhour/features/discovery/presentation/widgets/swipe_card.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/account_actions_settings_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock/stub_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDown(() {
    AnalyticsService.resetInstance();
  });

  group('Accessibility regression lane', () {
    testWidgets(
      'auth gateway respects reduced motion and keeps age gate readable at large text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _withSemantics(tester, () async {
          final authRepository = StubAuthRepository();

          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            _appShell(
              disableAnimations: true,
              textScaler: const TextScaler.linear(2),
              child: RepositoryProvider<AuthRepository>.value(
                value: authRepository,
                child: const AuthGatewayScreen(),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(
              RegExp('create account', caseSensitive: false),
            ),
            findsWidgets,
          );
          expect(
            find.bySemanticsLabel(
              RegExp('continue with google', caseSensitive: false),
            ),
            findsWidgets,
          );

          final createAccountFinder = find.text('Create account');
          await tester.ensureVisible(createAccountFinder);
          await tester.pumpAndSettle();
          await tester.tap(createAccountFinder);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Age Verification'), findsOneWidget);
          expect(find.text('No'), findsOneWidget);
          expect(find.text('Yes, I am 18+'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'login screen keeps semantics and tab traversal stable at large text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _withSemantics(tester, () async {
          final authRepository = StubAuthRepository();
          final authBloc = AuthBloc(authRepository: authRepository);
          addTearDown(authBloc.close);

          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            _appShell(
              child: RepositoryProvider<AuthRepository>.value(
                value: authRepository,
                child: BlocProvider<AuthBloc>.value(
                  value: authBloc,
                  child: const LoginScreen(),
                ),
              ),
              textScaler: const TextScaler.linear(2),
            ),
          );
          await tester.pump(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(RegExp('sign', caseSensitive: false)),
            findsWidgets,
          );
          expect(
            find.bySemanticsLabel(RegExp('forgot', caseSensitive: false)),
            findsWidgets,
          );

          final fields = find.byType(EditableText);
          expect(fields, findsNWidgets(2));

          await tester.tap(fields.at(0));
          await tester.pump();
          expect(
            tester.widget<EditableText>(fields.at(0)).focusNode.hasFocus,
            isTrue,
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          expect(
            tester.widget<EditableText>(fields.at(1)).focusNode.hasFocus,
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'basic info screen exposes labeled onboarding controls at large text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _withSemantics(tester, () async {
          final authBloc = _TestAuthBloc(_authenticatedState);
          final profileBloc = _TestProfileBloc(
            const ProfileState(user: _testUser, status: ProfileStatus.loaded),
          );
          addTearDown(authBloc.close);
          addTearDown(profileBloc.close);

          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            _appShell(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>.value(value: authBloc),
                  BlocProvider<ProfileBloc>.value(value: profileBloc),
                ],
                child: const BasicInfoScreen(),
              ),
              textScaler: const TextScaler.linear(2),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(RegExp('username', caseSensitive: false)),
            findsWidgets,
          );
          expect(
            find.bySemanticsLabel(RegExp('orientation', caseSensitive: false)),
            findsWidgets,
          );
          expect(
            find.bySemanticsLabel(
              RegExp('Orientation is optional', caseSensitive: false),
            ),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'profile setup exposes semantic pickers and stays stable at large text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _withSemantics(tester, () async {
          final authBloc = _TestAuthBloc(_authenticatedState);
          final profileBloc = _TestProfileBloc(
            const ProfileState(user: _testUser, status: ProfileStatus.loaded),
          );
          addTearDown(authBloc.close);
          addTearDown(profileBloc.close);

          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            _appShell(
              disableAnimations: true,
              textScaler: const TextScaler.linear(2),
              child: MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<ProfileMediaRepository>.value(
                    value: _NoopProfileMediaRepository(),
                  ),
                  RepositoryProvider<PassportLocationsRepository>.value(
                    value: _NoopPassportLocationsRepository(),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<AuthBloc>.value(value: authBloc),
                    BlocProvider<ProfileBloc>.value(value: profileBloc),
                  ],
                  child: const ProfileSetupScreen(),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pumpAndSettle();

          final skipPermission = find.text('Not Now');
          if (skipPermission.evaluate().isNotEmpty) {
            await tester.tap(skipPermission);
            await tester.pumpAndSettle();
          }

          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(
              RegExp('favourite athlete', caseSensitive: false),
            ),
            findsWidgets,
          );

          final travelFinder = find.bySemanticsLabel('Travel');
          expect(travelFinder, findsOneWidget);
          await tester.ensureVisible(travelFinder);
          await tester.pumpAndSettle();
          expect(
            tester.getSemantics(travelFinder),
            matchesSemantics(
              label: 'Travel',
              hasTapAction: true,
              isButton: true,
              hasSelectedState: true,
              hasEnabledState: true,
              isEnabled: true,
            ),
          );

          await tester.tap(travelFinder);
          await tester.pump();

          expect(
            tester.getSemantics(travelFinder),
            matchesSemantics(
              label: 'Travel',
              hasTapAction: true,
              isButton: true,
              hasSelectedState: true,
              hasEnabledState: true,
              isEnabled: true,
              isSelected: true,
            ),
          );
        });
      },
    );

    testWidgets('swipe card keeps discovery semantics readable', (
      tester,
    ) async {
      await _withSemantics(tester, () async {
        await tester.pumpWidget(
          _appShell(
            child: RepositoryProvider<StoryRepository>.value(
              value: _EmptyStoryRepository(),
              child: const SwipeCard(profile: _discoveryProfile),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel(RegExp('Alex, 25')), findsWidgets);
        final node = tester.getSemantics(find.byType(SwipeCard));
        expect(node.hint, 'Swipe right to like, swipe left to pass');
      });
    });

    testWidgets(
      'chat input bar keeps attachment semantics and enter-to-send behavior',
      (tester) async {
        await _withSemantics(tester, () async {
          final chatRepository = _RecordingChatRepository();
          final chatBloc = ChatBloc(
            chatRepository: chatRepository,
            subscriptionRepository: FakeSubscriptionRepository(),
            authRepository: _StaticAuthRepository(user: _testUser),
          );
          addTearDown(chatBloc.close);

          await tester.pumpWidget(
            _appShell(
              child: BlocProvider<ChatBloc>.value(
                value: chatBloc,
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: ChatInputBar(
                      state: ChatState(),
                      isBlocked: false,
                      canMessage: true,
                      isUnmatched: false,
                      completeness: _completeProfileSummary,
                      currentUserId: _testUser.id,
                      otherUserId: 'other-user',
                      otherName: 'Taylor',
                      matchId: 'match-1',
                      onEnsureMessagingAllowed: (_) async => true,
                      onShowMessagingIncomplete: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(
            find.bySemanticsLabel(RegExp('attach', caseSensitive: false)),
            findsWidgets,
          );
          expect(
            find.bySemanticsLabel(RegExp('voice', caseSensitive: false)),
            findsWidgets,
          );
          expect(
            find.bySemanticsLabel(RegExp('send', caseSensitive: false)),
            findsWidgets,
          );

          final field = find.byType(EditableText);
          await tester.tap(field);
          await tester.enterText(field, 'Hello from keyboard');
          await tester.pump();

          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pump();

          expect(chatRepository.sentMessages, isEmpty);

          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          await tester.pump();

          expect(chatRepository.sentMessages, ['Hello from keyboard']);
          expect(tester.widget<EditableText>(field).controller.text, isEmpty);
        });
      },
    );

    testWidgets(
      'account actions screen stays constrained and readable at large text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _withSemantics(tester, () async {
          final prefs = await SharedPreferences.getInstance();
          final authBloc = AuthBloc(
            authRepository: _StaticAuthRepository(user: _testUser),
          )..add(AuthStarted());
          final discoveryCubit = DiscoverySettingsCubit(preferences: prefs);
          addTearDown(authBloc.close);
          addTearDown(discoveryCubit.close);

          await tester.binding.setSurfaceSize(const Size(1200, 1000));
          await tester.pumpWidget(
            _appShell(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>.value(value: authBloc),
                  BlocProvider<DiscoverySettingsCubit>.value(
                    value: discoveryCubit,
                  ),
                ],
                child: const AccountActionsSettingsScreen(),
              ),
              textScaler: const TextScaler.linear(2),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final constrained = tester.widget<ConstrainedBox>(
            find.byKey(accountActionsConstraintKey),
          );
          expect(
            constrained.constraints.maxWidth,
            DsBreakpoints.contentMaxWidth(1200),
          );

          await tester.scrollUntilVisible(
            find.text('Export your data'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.bySemanticsLabel(
              RegExp('Export your data\\.', caseSensitive: false),
            ),
            findsWidgets,
          );
        });
      },
    );
  });
}

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final semantics = tester.ensureSemantics();
  try {
    await body();
  } finally {
    semantics.dispose();
  }
}

Widget _appShell({
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, widget) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: widget!,
      );
    },
    home: Scaffold(body: child),
  );
}

class _StaticAuthRepository implements AuthRepository {
  _StaticAuthRepository({required this.user});

  final CrushUser? user;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => Stream<CrushUser?>.value(user);

  @override
  Future<CrushUser?> refreshCurrentUser() async => user;

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected auth call: ${invocation.memberName}');
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => const Stream<CrushUser?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _NoopProfileRepository implements ProfileRepository {
  _NoopProfileRepository({required this.currentUser});

  final CrushUser currentUser;

  @override
  Future<CrushUser?> getCurrentUser() async => currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _NoopProfileMediaRepository implements ProfileMediaRepository {
  @override
  bool isLocalFile(String path) => path.startsWith('/');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _NoopPassportLocationsRepository implements PassportLocationsRepository {
  @override
  Future<int> getLocationCount(String city, String country) async => 0;

  @override
  Future<List<Map<String, String>>> getPassportLocations() async =>
      const <Map<String, String>>[];

  @override
  Future<List<Map<String, dynamic>>> getTrendingLocations() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> recordLocation(String city, String country) async {}

  @override
  Future<List<Map<String, String>>> searchLocations(String query) async =>
      const <Map<String, String>>[];
}

class _TestAuthBloc extends AuthBloc {
  _TestAuthBloc(AuthState initialState)
    : super(authRepository: _NoopAuthRepository()) {
    emit(initialState);
  }

  @override
  Stream<AuthState> get stream => const Stream<AuthState>.empty();
}

class _TestProfileBloc extends ProfileBloc {
  _TestProfileBloc(ProfileState initialState)
    : super(
        profileRepository: _NoopProfileRepository(currentUser: _testUser),
        authRepository: _NoopAuthRepository(),
      ) {
    emit(initialState);
  }

  @override
  Stream<ProfileState> get stream => const Stream<ProfileState>.empty();
}

class _RecordingChatRepository extends FakeChatRepository {
  _RecordingChatRepository()
    : super(
        FakeSubscriptionRepository(),
        FakeDiscoveryRepository(
          FakeProfileRepository(),
          FakeSubscriptionRepository(),
        ),
      );

  final List<String> sentMessages = <String>[];

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    sentMessages.add(content);
  }
}

class _EmptyStoryRepository implements StoryRepository {
  @override
  Stream<StoryUpdate> get storyUpdates => const Stream<StoryUpdate>.empty();

  @override
  void initialize() {}

  @override
  void dispose() {}

  @override
  List<ProfileStory> getStoriesForUser(String userId) => const <ProfileStory>[];

  @override
  bool hasActiveStories(String userId) => false;

  @override
  int getActiveStoryCount(String userId) => 0;

  @override
  Future<ProfileStory> addStory({
    required String userId,
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? thumbnailUrl,
    Duration? customDuration,
  }) async {
    return ProfileStory(
      id: 'story-$userId',
      userId: userId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime.now(),
      thumbnailUrl: thumbnailUrl,
      expiresAt: customDuration == null
          ? null
          : DateTime.now().add(customDuration),
    );
  }

  @override
  Future<void> removeStory({
    required String userId,
    required String storyId,
  }) async {}

  @override
  Future<void> viewStory({
    required String storyId,
    required String viewerId,
  }) async {}

  @override
  List<String> getUsersWithActiveStories() => const <String>[];

  @override
  void forceCleanup() {}

  @override
  void addMockStories() {}
}

const _testPreferences = DiscoveryPreferences(
  minAge: 18,
  maxAge: 50,
  maxDistanceKm: 80,
  showMeGenders: <String>['female'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'New York',
);

const _testProfile = Profile(
  id: 'profile-1',
  name: 'Taylor',
  age: 26,
  gender: 'female',
  photoUrls: <String>[],
  videoUrls: <String>[],
  bio: 'Hello there',
  interests: <String>['music', 'travel', 'coffee'],
  country: 'US',
  city: 'New York',
  isVerified: false,
  preferences: _testPreferences,
);

const _testUser = CrushUser(
  id: 'user-1',
  phoneNumber: '+15555550123',
  email: 'test@example.com',
  username: 'test_user',
  isEmailVerified: true,
  profile: _testProfile,
  isPhoneVerified: false,
  isIdVerified: false,
  tier: SubscriptionTier.free,
  hasAcceptedTerms: true,
  hasSkippedBasicInfo: false,
  hasSkippedProfileSetup: false,
);

const _authenticatedState = AuthState(
  status: AuthStatus.authenticated,
  user: _testUser,
  phoneInProgress: null,
  emailInProgress: null,
  emailOtpIdentifier: null,
  isLoading: false,
  errorMessage: null,
);

const _completeProfileSummary = ProfileCompletenessSummary(
  score: 1,
  breakdown: <String, double>{},
  missing: <String>[],
  requiredMissing: <String>[],
  recommended: <String>[],
);

const _discoveryProfile = Profile(
  id: 'discovery-1',
  name: 'Alex',
  age: 25,
  gender: 'other',
  bio: 'Hello there',
  photoUrls: <String>[],
  videoUrls: <String>[],
  isVerified: true,
  jobTitle: 'Engineer',
  company: 'Acme',
  interests: <String>['music'],
  country: 'US',
  city: 'NYC',
  preferences: DiscoveryPreferences(
    minAge: 18,
    maxAge: 30,
    maxDistanceKm: 50,
    showMeGenders: <String>['female', 'male'],
    showMyDistance: true,
    showMyAge: true,
    hideFromDiscovery: false,
    incognitoMode: false,
    country: 'US',
    city: 'NYC',
  ),
);
