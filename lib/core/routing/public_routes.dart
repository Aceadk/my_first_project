import 'package:go_router/go_router.dart';
import 'package:crushhour/presentation/screens/safety_screen.dart';
import 'package:crushhour/presentation/screens/community_guidelines_screen.dart';
import 'package:crushhour/presentation/screens/privacy_policy_screen.dart';
import 'package:crushhour/presentation/screens/terms_of_service_screen.dart';
import 'package:crushhour/features/about/presentation/screens/product_features_screen.dart';
import 'package:crushhour/features/about/presentation/screens/pricing_screen.dart';
import 'crush_routes.dart';
import 'page_builder.dart';

/// Legal, safety, and public information routes.
List<RouteBase> publicRoutes() => [
  GoRoute(
    path: CrushRoutes.safety,
    pageBuilder: (context, state) => buildPage(state, const SafetyScreen()),
  ),
  GoRoute(
    path: CrushRoutes.safetyGuidelines,
    pageBuilder: (context, state) =>
        buildPage(state, const CommunityGuidelinesScreen()),
  ),
  GoRoute(
    path: CrushRoutes.privacyPolicy,
    pageBuilder: (context, state) =>
        buildPage(state, const PrivacyPolicyScreen()),
  ),
  GoRoute(
    path: CrushRoutes.termsOfService,
    pageBuilder: (context, state) =>
        buildPage(state, const TermsOfServiceScreen()),
  ),
  GoRoute(
    path: CrushRoutes.communityGuidelines,
    pageBuilder: (context, state) =>
        buildPage(state, const CommunityGuidelinesScreen()),
  ),
  GoRoute(
    path: CrushRoutes.productFeatures,
    pageBuilder: (context, state) =>
        buildPage(state, const ProductFeaturesScreen()),
  ),
  GoRoute(
    path: CrushRoutes.pricing,
    pageBuilder: (context, state) => buildPage(state, const PricingScreen()),
  ),
];
