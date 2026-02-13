import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';
import 'core/services/firebase_mocks.dart';

const _firebaseValidationOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:1234567890:ios:test-app-id',
  messagingSenderId: '1234567890',
  projectId: 'test-project-id',
);

void main() {
  group('RemoteProfileCompleteness', () {
    test('fromMap parses normalized score, breakdown, and missing fields', () {
      final model = RemoteProfileCompleteness.fromMap({
        'score': 0.72,
        'breakdown': {'photos': 0.30, 'bio': 0.20, 'interests': 0.12},
        'missing': ['bio', 'prompts'],
        'requiredMissing': ['photos'],
        'meetsSwipeMinimum': true,
        'meetsMessagingMinimum': false,
        'meetsRequiredFields': false,
        'meetsMinimum': false,
        'minimum': 'messaging',
        'threshold': 0.8,
      });

      expect(model.score, 0.72);
      expect(model.breakdown['photos'], 0.30);
      expect(model.missing, ['bio', 'prompts']);
      expect(model.requiredMissing, ['photos']);
      expect(model.minimum, 'messaging');
      expect(model.threshold, 0.8);
      expect(model.allowsSwipe, isFalse);
      expect(model.allowsMessaging, isFalse);
      expect(model.missingForSwipe, ['photos']);
      expect(model.missingForMessaging, ['photos']);
    });

    test('fromMap defaults safely for invalid input shapes', () {
      final model = RemoteProfileCompleteness.fromMap({
        'score': 'bad',
        'breakdown': 'invalid',
        'missing': 'invalid',
        'requiredMissing': null,
        'minimum': null,
      });

      expect(model.score, 0.0);
      expect(model.breakdown, isEmpty);
      expect(model.missing, isEmpty);
      expect(model.requiredMissing, isEmpty);
      expect(model.minimum, 'swipe');
      expect(model.threshold, 0.0);
      expect(model.allowsSwipe, isFalse);
      expect(model.allowsMessaging, isFalse);
    });

    test('missing fallbacks use non-required missing list when needed', () {
      final model = RemoteProfileCompleteness.fromMap({
        'score': 0.5,
        'missing': ['bio'],
        'requiredMissing': [],
        'meetsSwipeMinimum': true,
        'meetsMessagingMinimum': true,
        'meetsRequiredFields': true,
        'meetsMinimum': true,
      });

      expect(model.missingForSwipe, ['bio']);
      expect(model.missingForMessaging, ['bio']);
      expect(model.allowsSwipe, isTrue);
      expect(model.allowsMessaging, isTrue);
    });
  });

  group('ProfileValidationService', () {
    late ProfileValidationService service;

    setUpAll(() async {
      setupFirebaseCoreMocks();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _firebaseValidationOptions);
      }
    });

    setUp(() {
      service = ProfileValidationService();
    });

    test('validate returns permissive default when callable fails', () async {
      final result = await service.validate(minimum: 'messaging');

      expect(result.minimum, 'messaging');
      expect(result.score, 1.0);
      expect(result.threshold, 1.0);
      expect(result.meetsMinimum, isTrue);
      expect(result.meetsSwipeMinimum, isTrue);
      expect(result.meetsMessagingMinimum, isTrue);
      expect(result.meetsRequiredFields, isTrue);
      expect(result.missing, isEmpty);
      expect(result.requiredMissing, isEmpty);
    });

    test('validate keeps requested minimum value in fallback', () async {
      final swipeResult = await service.validate(minimum: 'swipe');
      final messagingResult = await service.validate(minimum: 'messaging');

      expect(swipeResult.minimum, 'swipe');
      expect(messagingResult.minimum, 'messaging');
    });
  });

  group('TimeoutException', () {
    test('toString returns message', () {
      final ex = TimeoutException('timeout!');
      expect(ex.toString(), 'timeout!');
    });
  });
}
