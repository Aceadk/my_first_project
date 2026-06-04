import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/screens/basic_info_screen.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mock/stub_analytics_service.dart';

/// ONBOARD-UI-002: the basic-info form fields must chain the soft-keyboard
/// action so a user can advance username -> first name -> last name with the
/// keyboard's "next" button, ending with "done".
void main() {
  setUp(() => AnalyticsService.setInstance(StubAnalyticsService()));
  tearDown(AnalyticsService.resetInstance);

  testWidgets('text fields chain next -> next -> done', (tester) async {
    final authBloc = _TestAuthBloc(_authenticatedState);
    final profileBloc = _TestProfileBloc(
      const ProfileState(status: ProfileStatus.loaded, user: _testUser),
    );
    addTearDown(() async {
      await authBloc.close();
      await profileBloc.close();
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: _NoopAuthRepository()),
          RepositoryProvider<ProfileRepository>.value(
            value: _NoopProfileRepository(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BasicInfoScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));

    TextInputAction? actionAt(int i) =>
        tester.widget<TextField>(fields.at(i)).textInputAction;

    expect(actionAt(0), TextInputAction.next, reason: 'username -> next');
    expect(actionAt(1), TextInputAction.next, reason: 'first name -> next');
    expect(actionAt(2), TextInputAction.done, reason: 'last name -> done');
  });
}

const _testUser = CrushUser(
  id: 'user-1',
  phoneNumber: '+15555550123',
  email: 'test@example.com',
  username: '',
  isEmailVerified: true,
  isPhoneVerified: true,
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

class _NoopAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;
  @override
  bool get supportsAppleSignIn => false;
  @override
  bool get supportsUsernameLogin => true;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authStateChanges) {
      return const Stream<CrushUser?>.empty();
    }
    return super.noSuchMethod(invocation);
  }
}

class _NoopProfileRepository implements ProfileRepository {
  @override
  Future<CrushUser?> getCurrentUser() async => _testUser;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
        profileRepository: _NoopProfileRepository(),
        authRepository: _NoopAuthRepository(),
      ) {
    emit(initialState);
  }
  @override
  Stream<ProfileState> get stream => const Stream<ProfileState>.empty();
}
