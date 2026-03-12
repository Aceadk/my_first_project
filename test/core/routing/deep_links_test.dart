import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/routing/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkConfig.parse', () {
    test('parses user-profile links with auth requirement', () {
      final result = DeepLinkConfig.parse(
        Uri.parse('https://crushhour.app/user-profile/user_123'),
      );

      expect(result, isNotNull);
      expect(result!.route, '${CrushRoutes.userProfile}/user_123');
      expect(result.params?['userId'], 'user_123');
      expect(result.requiresAuth, isTrue);
    });

    test('parses support category links', () {
      final result = DeepLinkConfig.parse(
        Uri.parse('https://crushhour.app/support/category/matching'),
      );

      expect(result, isNotNull);
      expect(result!.route, CrushRoutes.supportCategoryPath('matching'));
      expect(result.params?['categoryId'], 'matching');
      expect(result.requiresAuth, isFalse);
    });

    test('parses match links as chat routes with auth requirement', () {
      final result = DeepLinkConfig.parse(
        Uri.parse('https://crushhour.app/match/m_700'),
      );

      expect(result, isNotNull);
      expect(result!.route, '${CrushRoutes.chat}/m_700');
      expect(result.params?['matchId'], 'm_700');
      expect(result.requiresAuth, isTrue);
    });

    test(
      'parses premium and upgrade links to paywall with auth requirement',
      () {
        final premiumResult = DeepLinkConfig.parse(
          Uri.parse('https://crushhour.app/premium'),
        );
        expect(premiumResult?.route, CrushRoutes.paywall);
        expect(premiumResult?.queryParams?['source'], 'deep_link');
        expect(premiumResult?.requiresAuth, isTrue);

        final upgradeResult = DeepLinkConfig.parse(
          Uri.parse('https://crushhour.app/upgrade'),
        );
        expect(upgradeResult?.route, CrushRoutes.paywall);
        expect(upgradeResult?.queryParams?['source'], 'deep_link');
        expect(upgradeResult?.requiresAuth, isTrue);
      },
    );

    test('parses verify-email links and preserves query parameters', () {
      final result = DeepLinkConfig.parse(
        Uri.parse(
          'https://crushhour.app/verify-email?email=qa%40example.com&token=tok123',
        ),
      );

      expect(result, isNotNull);
      expect(result!.route, CrushRoutes.emailVerification);
      expect(result.queryParams?['email'], 'qa@example.com');
      expect(result.queryParams?['token'], 'tok123');
      expect(
        result.fullPath,
        '${CrushRoutes.emailVerification}?email=qa%40example.com&token=tok123',
      );
    });

    test('buildProfileShareLink generates parseable profile routes', () {
      final link = DeepLinkConfig.buildProfileShareLink('abc123');
      final result = DeepLinkConfig.parse(link);

      expect(result, isNotNull);
      expect(result!.route, '${CrushRoutes.userProfile}/abc123');
      expect(result.params?['userId'], 'abc123');
    });
  });

  group('DeepLinkHandler', () {
    test('stores pending auth-required link and triggers auth callback', () {
      final navigatedRoutes = <String>[];
      DeepLinkResult? pendingLink;
      final handler = DeepLinkHandler(
        onNavigate: (route, {extra}) => navigatedRoutes.add(route),
        onAuthRequired: (pending) => pendingLink = pending,
      );

      handler.handleDeepLink(
        Uri.parse('https://crushhour.app/chat/match_123'),
        isAuthenticated: false,
      );

      expect(navigatedRoutes, isEmpty);
      expect(pendingLink, isNotNull);
      expect(handler.pendingLink?.route, '${CrushRoutes.chat}/match_123');
    });

    test('processes pending link after authentication', () {
      final navigatedRoutes = <String>[];
      final handler = DeepLinkHandler(
        onNavigate: (route, {extra}) => navigatedRoutes.add(route),
        onAuthRequired: (_) {},
      );

      handler.handleDeepLink(
        Uri.parse('https://crushhour.app/chat/match_999'),
        isAuthenticated: false,
      );
      expect(handler.pendingLink, isNotNull);

      handler.processPendingLink();

      expect(navigatedRoutes, contains('${CrushRoutes.chat}/match_999'));
      expect(handler.pendingLink, isNull);
    });
  });
}
