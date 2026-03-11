import 'package:crushhour/config/support_config.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupportConfig hotspots', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <MethodCall>[];
    var canLaunch = true;

    setUp(() {
      calls.clear();
      canLaunch = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'canLaunch' || call.method == 'canLaunchUrl') {
              return canLaunch;
            }
            if (call.method == 'launch' || call.method == 'launchUrl') {
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('categories and FAQ lists are populated', () {
      expect(SupportConfig.categories, isNotEmpty);
      expect(SupportConfig.frequentlyAsked, isNotEmpty);
      expect(
        SupportConfig.categories.any((c) => c.priority == SupportPriority.high),
        isTrue,
      );
    });

    test('category articles are available for every support category', () {
      for (final category in SupportConfig.categories) {
        final article = SupportConfig.articleForCategory(category.id);
        expect(article.overview, isNotEmpty);
        expect(article.quickSteps, isNotEmpty);
        expect(article.escalationHints, isNotEmpty);
      }
    });

    test('matching and messaging help questions include populated answers', () {
      const requiredQuestions = <MapEntry<String, String>>[
        MapEntry('How do I get more matches?', 'matching'),
        MapEntry('Why am I not seeing new profiles?', 'matching'),
        MapEntry('What is a Super Like?', 'matching'),
        MapEntry('How do I undo a swipe?', 'matching'),
        MapEntry('Why can\'t I send messages?', 'messaging'),
        MapEntry('How do I know if someone read my message?', 'messaging'),
        MapEntry('Can I unsend a message?', 'messaging'),
        MapEntry('How do I report a conversation?', 'messaging'),
      ];

      for (final item in requiredQuestions) {
        final faq = SupportConfig.frequentlyAsked.firstWhere(
          (entry) => entry.question == item.key && entry.category == item.value,
          orElse: () => throw TestFailure('Missing FAQ: ${item.key}'),
        );
        expect(faq.answer.trim(), isNotEmpty, reason: faq.question);
      }
    });

    test(
      'openSupportEmail launches default support and safety mailto links',
      () async {
        await SupportConfig.openSupportEmail(
          subject: 'Need Help',
          body: 'My account has an issue.',
        );
        await SupportConfig.openSupportEmail(
          category: 'safety',
          subject: 'Safety Concern',
        );

        final launches = calls
            .where((c) => c.method == 'launch' || c.method == 'launchUrl')
            .toList();
        expect(launches.length, 2);

        final firstArgs = launches.first.arguments.toString();
        final secondArgs = launches.last.arguments.toString();
        expect(firstArgs, contains('mailto:${SupportConfig.supportEmail}'));
        expect(firstArgs, contains('Need+Help'));
        expect(secondArgs, contains('mailto:${SupportConfig.safetyEmail}'));
        expect(secondArgs, contains('Safety+Concern'));
      },
    );

    test('openHelpCenter and openSafetyCenter launch expected URLs', () async {
      await SupportConfig.openHelpCenter();
      await SupportConfig.openHelpCenter('safety');
      await SupportConfig.openHelpCenter('guidelines');
      await SupportConfig.openHelpCenter('unknown');
      await SupportConfig.openSafetyCenter();

      final launches = calls
          .where((c) => c.method == 'launch' || c.method == 'launchUrl')
          .toList();
      expect(launches.length, 5);

      final launchText = launches.map((c) => c.arguments.toString()).join(' ');
      expect(launchText, contains(SupportConfig.helpCenterBaseUrl));
      expect(launchText, contains(SupportConfig.safetyCenterUrl));
      expect(launchText, contains(SupportConfig.guidelinesUrl));
      expect(launchText, contains(SupportConfig.faqUrl));
    });

    test('no launch occurs when launcher cannot open URL', () async {
      canLaunch = false;

      await SupportConfig.openSupportEmail(subject: 'No launch');
      await SupportConfig.openHelpCenter('safety');
      await SupportConfig.openSafetyCenter();

      final launchCalls = calls.where(
        (c) => c.method == 'launch' || c.method == 'launchUrl',
      );
      expect(launchCalls, isEmpty);
    });

    test('generateSupportBody includes optional technical information', () {
      final body = SupportConfig.generateSupportBody(
        category: 'technical',
        description: 'Chat keeps disconnecting',
        userId: 'user_123',
        deviceInfo: 'iPhone 15 Pro / iOS 18',
      );

      expect(body, contains('Category: technical'));
      expect(body, contains('Chat keeps disconnecting'));
      expect(body, contains('User ID: user_123'));
      expect(body, contains('Device: iPhone 15 Pro / iOS 18'));
      expect(body, contains('App Version:'));
      expect(body, contains('Platform:'));
    });
  });

  group('Core utils and model hotspots', () {
    test('email normalization strips zero-width chars and lowercases', () {
      const raw = '  Te\u200BSt@Example.Com  ';
      expect(normalizeEmail(raw), 'test@example.com');
      expect(looksLikeEmail(raw), isTrue);
      expect(looksLikeEmail('not-an-email'), isFalse);
    });

    test('CrushMatch derived values and copyWith work correctly', () {
      const match = CrushMatch(
        id: 'm1',
        userId: 'u1',
        otherUserId: 'u2',
        status: MatchStatus.pending,
        preMatchMessageRequestsCount: 1,
        pinnedForUser: false,
      );

      expect(match.isMutual, isFalse);
      final updated = match.copyWith(
        status: MatchStatus.mutual,
        pinnedForUser: true,
        otherUserName: 'Alex',
      );

      expect(updated.isMutual, isTrue);
      expect(updated.pinnedForUser, isTrue);
      expect(updated.otherUserName, 'Alex');
      expect(updated, isNot(equals(match)));
    });
  });
}
