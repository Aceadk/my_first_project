import 'package:crushhour/core/services/in_app_review_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.britannio.in_app_review');

  late bool isAvailable;
  late bool throwOnRequest;
  late int requestCount;
  MethodCall? lastOpenStoreCall;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await InAppReviewService.instance.resetForTesting();

    isAvailable = true;
    throwOnRequest = false;
    requestCount = 0;
    lastOpenStoreCall = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAvailable':
              return isAvailable;
            case 'requestReview':
              requestCount++;
              if (throwOnRequest) {
                throw PlatformException(code: 'request-failed');
              }
              return null;
            case 'openStoreListing':
              lastOpenStoreCall = call;
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() async {
    await InAppReviewService.instance.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('InAppReviewService', () {
    test('returns false when in-app review is unavailable', () async {
      isAvailable = false;

      final result = await InAppReviewService.instance.maybeRequestReview();

      expect(result, isFalse);
      expect(requestCount, 0);
    });

    test('requests review after match threshold is reached', () async {
      await InAppReviewService.instance.recordMatch();
      await InAppReviewService.instance.recordMatch();
      expect(requestCount, 0);

      await InAppReviewService.instance.recordMatch();

      expect(requestCount, 1);
      final stats = await InAppReviewService.instance.getStats();
      expect(stats['totalMatches'], 3);
      expect(stats['lastPromptDate'], isNotNull);
    });

    test('requests review after message threshold is reached', () async {
      await InAppReviewService.instance.recordMessagesSent(49);
      expect(requestCount, 0);

      await InAppReviewService.instance.recordMessagesSent(1);

      expect(requestCount, 1);
      final stats = await InAppReviewService.instance.getStats();
      expect(stats['totalMessages'], 50);
    });

    test('enforces minimum days between review prompts', () async {
      final first = await InAppReviewService.instance.maybeRequestReview();
      final second = await InAppReviewService.instance.maybeRequestReview();

      expect(first, isTrue);
      expect(second, isFalse);
      expect(requestCount, 1);
    });

    test('returns false when requestReview throws', () async {
      throwOnRequest = true;

      final result = await InAppReviewService.instance.maybeRequestReview();

      expect(result, isFalse);
      expect(requestCount, 1);
    });

    test('openStoreListing marks user as reviewed', () async {
      await InAppReviewService.instance.openStoreListing();

      expect(lastOpenStoreCall, isNotNull);
      expect(lastOpenStoreCall!.method, 'openStoreListing');
      expect(lastOpenStoreCall!.arguments, 'YOUR_APP_STORE_ID');

      final stats = await InAppReviewService.instance.getStats();
      expect(stats['hasReviewed'], isTrue);
    });
  });
}
