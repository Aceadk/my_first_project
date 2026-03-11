import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mock/stub_analytics_service.dart';

void main() {
  setUp(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDown(() {
    AnalyticsService.resetInstance();
  });

  testWidgets('treats keyboard as visible from View insets and avoids overflow', (
    tester,
  ) async {
    final authRepository = _NoopAuthRepository();
    final profileRepository = _NoopProfileRepository(currentUser: _testUser);
    final profileMediaRepository = _NoopProfileMediaRepository();
    final passportLocationsRepository = _NoopPassportLocationsRepository();
    final authBloc = _TestAuthBloc(_authenticatedState);
    final profileBloc = _TestProfileBloc(
      const ProfileState(user: _testUser, status: ProfileStatus.loaded),
    );

    addTearDown(() async {
      await authBloc.close();
      await profileBloc.close();
    });

    tester.view
      ..physicalSize = const Size(800, 900)
      ..devicePixelRatio = 1.0
      ..viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<ProfileRepository>.value(value: profileRepository),
          RepositoryProvider<ProfileMediaRepository>.value(
            value: profileMediaRepository,
          ),
          RepositoryProvider<PassportLocationsRepository>.value(
            value: passportLocationsRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                // Keep MediaQuery insets at zero to force View-insets fallback path.
                data: mediaQuery.copyWith(viewInsets: EdgeInsets.zero),
                child: child!,
              );
            },
            home: const ProfileSetupScreen(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    final errors = _drainTestExceptions(tester);
    expect(
      errors,
      isEmpty,
      reason: 'Unexpected widget test exceptions: $errors',
    );
    expect(
      find.textContaining('Start Matching'),
      findsNothing,
      reason: 'Bottom CTA should be hidden while keyboard is visible.',
    );
    expect(
      find.text('Profile Completion'),
      findsNothing,
      reason:
          'Top progress summary should be hidden while keyboard is visible.',
    );
  });
}

const _testPreferences = DiscoveryPreferences(
  minAge: 18,
  maxAge: 50,
  maxDistanceKm: 80,
  showMeGenders: ['female'],
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
  photoUrls: [],
  videoUrls: [],
  bio: 'Hello',
  interests: ['music'],
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
  plan: SubscriptionPlan.free,
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

List<Object> _drainTestExceptions(WidgetTester tester) {
  final errors = <Object>[];
  while (true) {
    final error = tester.takeException();
    if (error == null) {
      break;
    }
    errors.add(error);
  }
  return errors;
}

class _NoopAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authStateChanges) {
      return const Stream<CrushUser?>.empty();
    }
    if (invocation.memberName == #bootstrapSession) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _NoopProfileRepository implements ProfileRepository {
  _NoopProfileRepository({this.currentUser});

  final CrushUser? currentUser;

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
