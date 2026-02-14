import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';

void main() {
  AuthState buildState({required AuthStatus status, CrushUser? user}) {
    return AuthState(
      status: status,
      user: user,
      phoneInProgress: null,
      emailInProgress: null,
      emailOtpIdentifier: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  CrushUser buildUser({
    bool hasAcceptedTerms = true,
    bool hasSkippedBasicInfo = true,
    bool hasSkippedProfileSetup = true,
    bool isEmailVerified = true,
    bool isPhoneVerified = false,
  }) {
    return CrushUser(
      id: 'user-1',
      phoneNumber: '+15555550123',
      email: 'user@example.com',
      username: 'tester',
      isEmailVerified: isEmailVerified,
      profile: null,
      isPhoneVerified: isPhoneVerified,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
      hasAcceptedTerms: hasAcceptedTerms,
      hasSkippedBasicInfo: hasSkippedBasicInfo,
      hasSkippedProfileSetup: hasSkippedProfileSetup,
    );
  }

  group('resolveRouteRedirect', () {
    test('unknown auth status forces splash except when already on splash', () {
      final unknown = buildState(status: AuthStatus.unknown);

      expect(
        resolveRouteRedirect(authState: unknown, path: CrushRoutes.home),
        CrushRoutes.splash,
      );
      expect(
        resolveRouteRedirect(authState: unknown, path: CrushRoutes.splash),
        isNull,
      );
    });

    test(
      'unauthenticated users are redirected to auth on protected routes',
      () {
        final unauth = buildState(status: AuthStatus.unauthenticated);

        expect(
          resolveRouteRedirect(authState: unauth, path: CrushRoutes.home),
          CrushRoutes.authGateway,
        );
        expect(
          resolveRouteRedirect(authState: unauth, path: CrushRoutes.settings),
          CrushRoutes.authGateway,
        );
        expect(
          resolveRouteRedirect(authState: unauth, path: CrushRoutes.login),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: unauth, path: CrushRoutes.splash),
          CrushRoutes.authGateway,
        );
      },
    );

    test('splash redirects logged-in users through onboarding in order', () {
      final needsTerms = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(hasAcceptedTerms: false),
      );
      expect(
        resolveRouteRedirect(authState: needsTerms, path: CrushRoutes.splash),
        CrushRoutes.termsConditions,
      );

      final needsBasicInfo = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(hasAcceptedTerms: true, hasSkippedBasicInfo: false),
      );
      expect(
        resolveRouteRedirect(
          authState: needsBasicInfo,
          path: CrushRoutes.splash,
        ),
        CrushRoutes.basicInfo,
      );

      final needsProfileSetup = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: false,
        ),
      );
      expect(
        resolveRouteRedirect(
          authState: needsProfileSetup,
          path: CrushRoutes.splash,
        ),
        CrushRoutes.profileSetup,
      );

      final needsVerification = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: true,
          isEmailVerified: false,
          isPhoneVerified: false,
        ),
      );
      expect(
        resolveRouteRedirect(
          authState: needsVerification,
          path: CrushRoutes.splash,
        ),
        CrushRoutes.emailVerification,
      );

      final complete = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(),
      );
      expect(
        resolveRouteRedirect(authState: complete, path: CrushRoutes.splash),
        CrushRoutes.home,
      );
    });

    test(
      'terms acceptance gate allows terms/public and blocks other routes',
      () {
        final state = buildState(
          status: AuthStatus.authenticated,
          user: buildUser(hasAcceptedTerms: false),
        );

        expect(
          resolveRouteRedirect(
            authState: state,
            path: CrushRoutes.termsConditions,
          ),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.support),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.home),
          CrushRoutes.termsConditions,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.login),
          isNull,
        );
      },
    );

    test(
      'basic-info gate allows onboarding/profile/settings/public routes',
      () {
        final state = buildState(
          status: AuthStatus.authenticated,
          user: buildUser(hasAcceptedTerms: true, hasSkippedBasicInfo: false),
        );

        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.basicInfo),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.profileEdit),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.settings),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.pricing),
          isNull,
        );
        expect(
          resolveRouteRedirect(
            authState: state,
            path: CrushRoutes.termsConditions,
          ),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.login),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.home),
          CrushRoutes.basicInfo,
        );
      },
    );

    test(
      'profile-setup gate allows profile/settings/public and blocks others',
      () {
        final state = buildState(
          status: AuthStatus.authenticated,
          user: buildUser(
            hasAcceptedTerms: true,
            hasSkippedBasicInfo: true,
            hasSkippedProfileSetup: false,
          ),
        );

        expect(
          resolveRouteRedirect(
            authState: state,
            path: CrushRoutes.profileSetup,
          ),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.profile),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.settings),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.support),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.login),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.home),
          CrushRoutes.profileSetup,
        );
      },
    );

    test(
      'account-verification gate allows onboarding/settings/public routes',
      () {
        final state = buildState(
          status: AuthStatus.authenticated,
          user: buildUser(
            hasAcceptedTerms: true,
            hasSkippedBasicInfo: true,
            hasSkippedProfileSetup: true,
            isEmailVerified: false,
            isPhoneVerified: false,
          ),
        );

        expect(
          resolveRouteRedirect(
            authState: state,
            path: CrushRoutes.emailVerification,
          ),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.settings),
          isNull,
        );
        expect(
          resolveRouteRedirect(
            authState: state,
            path: CrushRoutes.idVerification,
          ),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.support),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.login),
          isNull,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.home),
          CrushRoutes.emailVerification,
        );
      },
    );

    test(
      'fully onboarded users are redirected away from auth/onboarding routes',
      () {
        final state = buildState(
          status: AuthStatus.authenticated,
          user: buildUser(),
        );

        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.authGateway),
          CrushRoutes.home,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.login),
          CrushRoutes.home,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.basicInfo),
          CrushRoutes.home,
        );
        expect(
          resolveRouteRedirect(authState: state, path: CrushRoutes.home),
          isNull,
        );
      },
    );

    test('root path redirects by auth and onboarding status', () {
      final unauth = buildState(status: AuthStatus.unauthenticated);
      expect(
        resolveRouteRedirect(authState: unauth, path: CrushRoutes.root),
        CrushRoutes.authGateway,
      );

      final complete = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(),
      );
      expect(
        resolveRouteRedirect(authState: complete, path: CrushRoutes.root),
        CrushRoutes.home,
      );

      final needsVerification = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: true,
          isEmailVerified: false,
          isPhoneVerified: false,
        ),
      );
      expect(
        resolveRouteRedirect(
          authState: needsVerification,
          path: CrushRoutes.root,
        ),
        CrushRoutes.emailVerification,
      );

      final needsTerms = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(hasAcceptedTerms: false),
      );
      expect(
        resolveRouteRedirect(authState: needsTerms, path: CrushRoutes.root),
        CrushRoutes.termsConditions,
      );

      final needsBasicInfo = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(hasAcceptedTerms: true, hasSkippedBasicInfo: false),
      );
      expect(
        resolveRouteRedirect(authState: needsBasicInfo, path: CrushRoutes.root),
        CrushRoutes.basicInfo,
      );

      final needsProfileSetup = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: false,
        ),
      );
      expect(
        resolveRouteRedirect(
          authState: needsProfileSetup,
          path: CrushRoutes.root,
        ),
        CrushRoutes.profileSetup,
      );
    });
  });
}
