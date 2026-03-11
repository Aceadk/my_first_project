import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'crush_routes.dart';

/// Determines the redirect target for a given [authState] and [path].
///
/// Returns a redirect path string, or `null` to allow the navigation as-is.
/// This function is intentionally pure (no Flutter context dependency) so that
/// it can be unit-tested independently.
String? resolveRouteRedirect({
  required AuthState authState,
  required String path,
}) {
  final status = authState.status;
  final user = authState.user;
  final isLoggedIn = status == AuthStatus.authenticated;
  final isUnknown = status == AuthStatus.unknown;
  final isAuthRoute = path.startsWith(CrushRoutes.authGateway);
  final isSplash = path == CrushRoutes.splash;
  final isEmailVerificationRoute = path == CrushRoutes.emailVerification;
  final isTermsRoute = path == CrushRoutes.termsConditions;
  final isProfileRoute =
      path == CrushRoutes.profile || path == CrushRoutes.profileMedia;
  final isProfileEditRoute = path == CrushRoutes.profileEdit;
  final isSettingsRoute = path.startsWith(CrushRoutes.settings);
  final isOnboardingRoute =
      path == CrushRoutes.basicInfo ||
      path == CrushRoutes.profileSetup ||
      path == CrushRoutes.idVerification ||
      path == CrushRoutes.termsConditions;

  // Legal/public routes that should always be accessible during onboarding
  final isPublicRoute =
      path == CrushRoutes.privacyPolicy ||
      path == CrushRoutes.termsOfService ||
      path == CrushRoutes.safetyGuidelines ||
      path == CrushRoutes.communityGuidelines ||
      path == CrushRoutes.productFeatures ||
      path == CrushRoutes.pricing ||
      path == CrushRoutes.support ||
      path.startsWith('${CrushRoutes.supportCategoryBase}/') ||
      path == CrushRoutes.weeklyPicks ||
      path == CrushRoutes.safety ||
      path == CrushRoutes.logout;

  // Public routes that must remain accessible without authentication.
  final isPublicUnauthRoute =
      path == CrushRoutes.privacyPolicy ||
      path == CrushRoutes.termsOfService ||
      path == CrushRoutes.safetyGuidelines ||
      path == CrushRoutes.communityGuidelines ||
      path == CrushRoutes.productFeatures ||
      path == CrushRoutes.pricing ||
      path == CrushRoutes.support ||
      path.startsWith('${CrushRoutes.supportCategoryBase}/');

  // Check if user needs account verification
  // Only require verification for users who have neither email nor phone verified
  // Users with phone verification can skip email verification
  final needsAccountVerification =
      isLoggedIn && user != null && !user.isAccountVerified;

  // Check if user needs to accept terms and conditions
  final needsTermsAcceptance =
      isLoggedIn && user != null && !user.hasAcceptedTerms;

  // Check if user needs to complete basic info (after T&C)
  final needsBasicInfo =
      isLoggedIn &&
      user != null &&
      user.hasAcceptedTerms &&
      !user.hasCompletedBasicInfo;

  // Check if user needs to complete profile setup (after basic info)
  final needsProfileSetup =
      isLoggedIn &&
      user != null &&
      user.hasAcceptedTerms &&
      user.hasCompletedBasicInfo &&
      !user.hasCompletedProfileSetup;

  // While auth status is unknown, stay on splash screen
  // Don't redirect - let the splash screen handle navigation via BlocListener
  if (isUnknown) {
    if (!isSplash) {
      return CrushRoutes.splash;
    }
    return null;
  }

  // Auth status is known - redirect away from splash
  if (isSplash) {
    if (isLoggedIn) {
      // Check onboarding steps in order
      if (needsTermsAcceptance) {
        return CrushRoutes.termsConditions;
      }
      if (needsBasicInfo) {
        return CrushRoutes.basicInfo;
      }
      if (needsProfileSetup) {
        return CrushRoutes.profileSetup;
      }
      // Check if email verification is needed
      if (needsAccountVerification) {
        return CrushRoutes.emailVerification;
      }
      return CrushRoutes.home;
    }
    return CrushRoutes.authGateway;
  }

  // Not logged in and trying to access protected route
  if (!isLoggedIn && !isAuthRoute && !isPublicUnauthRoute) {
    return CrushRoutes.authGateway;
  }

  // Logged in but needs to accept terms
  if (needsTermsAcceptance) {
    // Allow staying on terms screen or accessing public routes
    if (isTermsRoute || isPublicRoute) {
      return null;
    }
    // Redirect to terms screen from any other protected route
    if (!isAuthRoute) {
      return CrushRoutes.termsConditions;
    }
  }

  // Logged in but needs to complete basic info
  if (needsBasicInfo) {
    // Allow staying on basic info, proceeding to next onboarding steps,
    // or accessing public/legal routes
    if (path == CrushRoutes.basicInfo ||
        path == CrushRoutes.idVerification ||
        path == CrushRoutes.profileSetup ||
        isProfileRoute ||
        isProfileEditRoute ||
        isSettingsRoute ||
        isPublicRoute) {
      return null;
    }
    // Redirect to basic info from any other protected route
    if (!isAuthRoute && !isTermsRoute) {
      return CrushRoutes.basicInfo;
    }
  }

  // Logged in but needs to complete profile setup
  if (needsProfileSetup) {
    // Allow staying on profile setup, ID verification,
    // or accessing public/legal routes
    if (path == CrushRoutes.profileSetup ||
        path == CrushRoutes.idVerification ||
        isProfileRoute ||
        isProfileEditRoute ||
        isSettingsRoute ||
        isPublicRoute) {
      return null;
    }
    // Redirect to profile setup from any other protected route (including earlier onboarding steps)
    if (!isAuthRoute) {
      return CrushRoutes.profileSetup;
    }
  }

  // Logged in but needs email verification (after completing onboarding)
  if (needsAccountVerification &&
      !needsTermsAcceptance &&
      !needsBasicInfo &&
      !needsProfileSetup) {
    // Allow staying on verification screen, onboarding routes, settings,
    // or accessing public/legal routes
    if (isEmailVerificationRoute ||
        isOnboardingRoute ||
        isSettingsRoute ||
        isPublicRoute) {
      return null;
    }
    // Redirect to verification screen from any other protected route
    if (!isAuthRoute) {
      return CrushRoutes.emailVerification;
    }
  }

  // Logged in with completed onboarding - redirect away from auth/onboarding routes
  if (isLoggedIn &&
      !needsTermsAcceptance &&
      !needsBasicInfo &&
      !needsProfileSetup &&
      !needsAccountVerification) {
    if (isAuthRoute || isEmailVerificationRoute || isOnboardingRoute) {
      return CrushRoutes.home;
    }
  }

  // Root path redirect
  if (path == CrushRoutes.root) {
    if (isLoggedIn) {
      if (needsTermsAcceptance) {
        return CrushRoutes.termsConditions;
      }
      if (needsBasicInfo) {
        return CrushRoutes.basicInfo;
      }
      if (needsProfileSetup) {
        return CrushRoutes.profileSetup;
      }
      if (needsAccountVerification) {
        return CrushRoutes.emailVerification;
      }
      return CrushRoutes.home;
    }
    return CrushRoutes.authGateway;
  }

  return null;
}
