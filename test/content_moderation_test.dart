import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/services/content_moderation_service.dart';

import 'mock/firebase_mock.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  late FirebaseFunctionsPlatform originalFunctionsPlatform;
  late _FakeFunctionsPlatform fakeFunctionsPlatform;
  late ContentModerationService service;

  setUpAll(() {
    originalFunctionsPlatform = FirebaseFunctionsPlatform.instance;
    fakeFunctionsPlatform = _FakeFunctionsPlatform();
    FirebaseFunctionsPlatform.instance = fakeFunctionsPlatform;
  });

  tearDownAll(() {
    FirebaseFunctionsPlatform.instance = originalFunctionsPlatform;
  });

  setUp(() {
    fakeFunctionsPlatform.reset();
    service = ContentModerationService.instance;
  });

  // ===========================================================================
  // PROFANITY DETECTION
  // ===========================================================================

  group('Profanity Detection', () {
    // Note: The profanity list contains placeholder patterns 'badword1' and
    // 'badword2'. Patterns are pre-normalized using the leetspeak map, so
    // 'badword1' becomes 'badwordi' in the normalized pattern set. Input text
    // is also normalized, so both 'badword1' and 'badwordi' in input match.
    // The leetspeak-aware regex in filterProfanity handles replacement of
    // variants like 'b4dw0rd1' in the original text.

    test('detects known profanity pattern (badword2) in text', () {
      // 'badword2' pattern: '2' is not in leetspeak map, so it matches
      expect(service.containsProfanity('this has badword2 in it'), isTrue);
    });

    test('returns false for clean text', () {
      expect(service.containsProfanity('hello world'), isFalse);
      expect(service.containsProfanity('nice to meet you'), isFalse);
    });

    test('detects profanity case-insensitively', () {
      expect(service.containsProfanity('BADWORD2'), isTrue);
      expect(service.containsProfanity('BadWord2'), isTrue);
    });

    test('normalization converts leetspeak characters', () {
      // '1' -> 'i', '0' -> 'o', '3' -> 'e', '4' -> 'a', '5' -> 's',
      // '7' -> 't', '8' -> 'b', '@' -> 'a', '\$' -> 's'
      // 'b4dw0rd2' -> 'badword2' after normalization -> matches pattern
      expect(service.containsProfanity('b4dw0rd2'), isTrue);
    });

    test('normalization removes spaces between characters', () {
      // 'b a d w o r d 2' -> 'badword2' after space removal -> matches
      expect(service.containsProfanity('b a d w o r d 2'), isTrue);
    });

    test('normalization removes special character bypasses', () {
      // dots, dashes, underscores, asterisks are stripped
      expect(service.containsProfanity('bad.word.2'), isTrue);
      expect(service.containsProfanity('bad-word-2'), isTrue);
      expect(service.containsProfanity('bad_word_2'), isTrue);
      expect(service.containsProfanity('bad*word*2'), isTrue);
    });

    test('handles empty string', () {
      expect(service.containsProfanity(''), isFalse);
    });

    test('handles very long strings without crashing', () {
      final longText = 'a' * 100000;
      expect(service.containsProfanity(longText), isFalse);
    });

    test('handles string with only special characters', () {
      expect(service.containsProfanity('!@#\$%^&*()'), isFalse);
    });

    test('handles string with only whitespace', () {
      expect(service.containsProfanity('   \t\n  '), isFalse);
    });

    test('detects badword1 after leetspeak normalization (R-125 fix)', () {
      // Both the input and pattern are normalized: 'badword1' → 'badwordi'.
      // This verifies the R-125 fix: patterns with digits now match correctly.
      expect(service.containsProfanity('badword1'), isTrue);
      // 'badwordi' also matches since pattern normalizes to 'badwordi'
      expect(service.containsProfanity('badwordi'), isTrue);
    });

    test('detects leetspeak variants of badword1', () {
      // Various leetspeak combinations should all normalize and match
      expect(service.containsProfanity('b4dword1'), isTrue);
      expect(service.containsProfanity('b@dw0rd1'), isTrue);
      expect(service.containsProfanity('BADWORD1'), isTrue);
    });
  });

  // ===========================================================================
  // PROFANITY FILTERING
  // ===========================================================================

  group('Profanity Filtering', () {
    test('replaces profanity with asterisks', () {
      final result = service.filterProfanity('this is badword2');
      expect(result, contains('********'));
      expect(result, isNot(contains('badword2')));
    });

    test('preserves clean text unchanged', () {
      const clean = 'hello world';
      expect(service.filterProfanity(clean), equals(clean));
    });

    test('handles empty string', () {
      expect(service.filterProfanity(''), equals(''));
    });

    test('handles text with no profanity', () {
      const text = 'This is a perfectly fine sentence.';
      expect(service.filterProfanity(text), equals(text));
    });

    test('filters badword1 and leetspeak variants (R-125 fix)', () {
      // After R-125 fix, badword1 is now detected and filtered
      final result1 = service.filterProfanity('this has badword1 here');
      expect(result1, isNot(contains('badword1')));
      expect(result1, contains('*'));

      // Leetspeak variant should also be filtered
      final result2 = service.filterProfanity('this has b4dw0rd1 here');
      expect(result2, isNot(contains('b4dw0rd1')));
      expect(result2, contains('*'));
    });
  });

  // ===========================================================================
  // LOCAL TEXT ANALYSIS (via _localAnalyzeText fallback)
  // ===========================================================================

  group('Text Analysis (local fallback)', () {
    // analyzeText() calls Firebase Cloud Functions, but falls back to
    // _localAnalyzeText on error. Since Cloud Functions aren't available
    // in test, the local fallback will be exercised.

    test('approves clean text', () async {
      final result = await service.analyzeText('Hello, nice to meet you!');
      expect(result.isApproved, isTrue);
      expect(result.issues, isEmpty);
    });

    test('flags text containing profanity', () async {
      final result = await service.analyzeText('This contains badword2');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.profanity),
        isTrue,
      );
    });

    test('detects phone numbers as personal info', () async {
      final result = await service.analyzeText('Call me at 555-123-4567');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
      expect(result.isApproved, isFalse);
    });

    test('detects email addresses as personal info', () async {
      final result = await service.analyzeText('Email me at john@example.com');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
      expect(result.isApproved, isFalse);
    });

    test('detects social media handles as personal info', () async {
      final result = await service.analyzeText(
        'Follow me @johndoe on instagram.com',
      );
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
    });

    test('detects excessive caps as spam', () async {
      final result = await service.analyzeText(
        'THIS IS ALL CAPS SPAM TEXT HERE',
      );
      expect(result.issues.any((i) => i.type == ContentIssueType.spam), isTrue);
    });

    test('detects repeated characters as spam', () async {
      final result = await service.analyzeText('hellooooooo there');
      expect(result.issues.any((i) => i.type == ContentIssueType.spam), isTrue);
    });

    test('detects URLs as spam', () async {
      final result = await service.analyzeText(
        'Check out https://scam-site.com',
      );
      expect(result.issues.any((i) => i.type == ContentIssueType.spam), isTrue);
    });

    test('detects threat language as harassment', () async {
      final result = await service.analyzeText('I will kill you');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.harassment),
        isTrue,
      );
      expect(result.isApproved, isFalse);
    });

    test('detects "hurt you" as harassment', () async {
      final result = await service.analyzeText('I will hurt you badly');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.harassment),
        isTrue,
      );
    });

    test('detects "find you" as harassment', () async {
      final result = await service.analyzeText('I will find you');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.harassment),
        isTrue,
      );
    });

    test('detects "you will regret" as harassment', () async {
      final result = await service.analyzeText('you will regret this');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.harassment),
        isTrue,
      );
    });

    test('approves text with only low-severity spam issues', () async {
      // Spam issues have low severity => still approved
      final result = await service.analyzeText('Check out https://example.com');
      expect(result.isApproved, isTrue);
      expect(result.issues.any((i) => i.type == ContentIssueType.spam), isTrue);
    });

    test('handles empty string gracefully', () async {
      final result = await service.analyzeText('');
      expect(result.isApproved, isTrue);
      expect(result.issues, isEmpty);
    });

    test('handles very long text without crashing', () async {
      final longText = 'Hello world. ' * 10000;
      final result = await service.analyzeText(longText);
      expect(result, isNotNull);
    });

    test('short caps text is not flagged as spam', () async {
      // Less than 10 characters, even all caps, should not trigger spam
      final result = await service.analyzeText('HELLO');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.spam),
        isFalse,
      );
    });

    test('detects international phone format', () async {
      final result = await service.analyzeText(
        'My number is +1 (555) 123-4567',
      );
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
    });

    test('detects snapchat mention as personal info', () async {
      final result = await service.analyzeText('Add me on snapchat');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
    });

    test('detects whatsapp mention as personal info', () async {
      final result = await service.analyzeText('Message me on whatsapp');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
    });

    test('detects telegram mention as personal info', () async {
      final result = await service.analyzeText('Find me on telegram');
      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
    });

    test('multiple issues can be detected simultaneously', () async {
      // Text with profanity + personal info + harassment
      final result = await service.analyzeText(
        'badword2 email me john@test.com I will kill you',
      );
      expect(result.issues.length, greaterThanOrEqualTo(3));
      expect(result.isApproved, isFalse);
    });
  });

  group('Text Analysis (cloud callable path)', () {
    test('uses callable allow response directly', () async {
      fakeFunctionsPlatform.onCall = (functionName, parameters) async {
        expect(functionName, 'moderateTextContent');
        expect(parameters, containsPair('content', 'hello there'));
        return <String, dynamic>{'action': 'allow'};
      };

      final result = await service.analyzeText('hello there');

      expect(result.isApproved, isTrue);
      expect(result.issues, isEmpty);
      expect(result.filteredText, 'hello there');
    });

    test('maps callable reason/severity branches', () async {
      final cases =
          <
            ({
              String reason,
              String severity,
              ContentIssueType expectedType,
              ContentSeverity expectedSeverity,
            })
          >[
            (
              reason: 'profanity',
              severity: 'low',
              expectedType: ContentIssueType.profanity,
              expectedSeverity: ContentSeverity.low,
            ),
            (
              reason: 'personal info',
              severity: 'medium',
              expectedType: ContentIssueType.personalInfo,
              expectedSeverity: ContentSeverity.medium,
            ),
            (
              reason: 'spam',
              severity: 'high',
              expectedType: ContentIssueType.spam,
              expectedSeverity: ContentSeverity.high,
            ),
            (
              reason: 'harassment',
              severity: 'critical',
              expectedType: ContentIssueType.harassment,
              expectedSeverity: ContentSeverity.critical,
            ),
          ];

      for (final c in cases) {
        fakeFunctionsPlatform.onCall = (functionName, parameters) async {
          expect(functionName, 'moderateTextContent');
          expect(parameters, containsPair('content', 'callable-input'));
          return <String, dynamic>{
            'action': 'block',
            'reason': c.reason,
            'severity': c.severity,
          };
        };

        final result = await service.analyzeText('callable-input');

        expect(result.isApproved, isFalse);
        expect(result.issues, hasLength(1));
        expect(result.issues.first.type, c.expectedType);
        expect(result.issues.first.severity, c.expectedSeverity);
        expect(result.issues.first.description, c.reason);
      }
    });

    test('defaults unknown reason/severity and fallback description', () async {
      fakeFunctionsPlatform.onCall = (functionName, parameters) async {
        expect(functionName, 'moderateTextContent');
        expect(parameters, containsPair('content', 'anything'));
        return <String, dynamic>{
          'action': 'block',
          'severity': 'unexpected-severity',
        };
      };

      final result = await service.analyzeText('anything');

      expect(result.isApproved, isFalse);
      expect(result.issues, hasLength(1));
      expect(result.issues.first.type, ContentIssueType.other);
      expect(result.issues.first.severity, ContentSeverity.medium);
      expect(result.issues.first.description, 'Content flagged for review');
    });

    test(
      'falls back when callable throws FirebaseFunctionsException',
      () async {
        fakeFunctionsPlatform.onCall = (_, __) async {
          throw FirebaseFunctionsException(
            code: 'internal',
            message: 'forced failure',
          );
        };

        final result = await service.analyzeText('badword2');

        expect(
          result.issues.any((i) => i.type == ContentIssueType.profanity),
          isTrue,
        );
      },
    );

    test('falls back when callable throws generic exception', () async {
      fakeFunctionsPlatform.onCall = (_, __) async {
        throw StateError('forced generic failure');
      };

      final result = await service.analyzeText('Call me at 555-123-4567');

      expect(
        result.issues.any((i) => i.type == ContentIssueType.personalInfo),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // REPORT VALIDATION
  // ===========================================================================

  group('Report Validation', () {
    test('validates a proper report', () {
      final result = service.validateReport(
        category: ReportCategory.harassment,
        description: 'This user sent me threatening messages multiple times',
      );
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('rejects description that is too short', () {
      final result = service.validateReport(
        category: ReportCategory.spam,
        description: 'bad',
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues,
        contains('Please provide more detail about the issue'),
      );
    });

    test('rejects description that is too long', () {
      final result = service.validateReport(
        category: ReportCategory.spam,
        description: 'a' * 1001,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues,
        contains('Description is too long (max 1000 characters)'),
      );
    });

    test('requires "who" for impersonation reports', () {
      final result = service.validateReport(
        category: ReportCategory.impersonation,
        description: 'This person is pretending to be someone else here',
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues,
        contains(
          'For impersonation reports, please specify who is being impersonated',
        ),
      );
    });

    test('passes impersonation report that mentions "who"', () {
      final result = service.validateReport(
        category: ReportCategory.impersonation,
        description:
            'This person is impersonating someone who I know personally',
      );
      expect(result.isValid, isTrue);
    });

    test('validates minimum description length with leading spaces', () {
      final result = service.validateReport(
        category: ReportCategory.spam,
        description: '       hi',
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues,
        contains('Please provide more detail about the issue'),
      );
    });

    test('accepts description exactly at minimum length', () {
      final result = service.validateReport(
        category: ReportCategory.spam,
        description: 'Exactly 10', // 10 chars
      );
      expect(result.isValid, isTrue);
    });

    test('accepts description exactly at max length', () {
      final result = service.validateReport(
        category: ReportCategory.spam,
        description: 'a' * 1000,
      );
      expect(result.isValid, isTrue);
    });

    test('can have both short description and impersonation issue', () {
      final result = service.validateReport(
        category: ReportCategory.impersonation,
        description: 'fake',
      );
      expect(result.isValid, isFalse);
      expect(result.issues.length, 2);
    });
  });

  // ===========================================================================
  // IMAGE MODERATION RESULT
  // ===========================================================================

  group('ImageModerationResult.fromApiResponse', () {
    test('approves safe image', () {
      final result = ImageModerationResult.fromApiResponse({
        'adult': 0.1,
        'violence': 0.2,
        'racy': 0.3,
      });
      expect(result.isApproved, isTrue);
      expect(result.rejectionReason, isNull);
    });

    test('rejects adult content above threshold', () {
      final result = ImageModerationResult.fromApiResponse({
        'adult': 0.8,
        'violence': 0.1,
        'racy': 0.1,
      });
      expect(result.isApproved, isFalse);
      expect(result.rejectionReason, 'Image contains adult content');
    });

    test('rejects violent content above threshold', () {
      final result = ImageModerationResult.fromApiResponse({
        'adult': 0.1,
        'violence': 0.85,
        'racy': 0.1,
      });
      expect(result.isApproved, isFalse);
      expect(result.rejectionReason, 'Image contains violent content');
    });

    test('rejects racy content above threshold', () {
      final result = ImageModerationResult.fromApiResponse({
        'adult': 0.1,
        'violence': 0.1,
        'racy': 0.95,
      });
      expect(result.isApproved, isFalse);
      expect(result.rejectionReason, 'Image is too explicit');
    });

    test('handles missing scores defaulting to 0.0', () {
      final result = ImageModerationResult.fromApiResponse({});
      expect(result.isApproved, isTrue);
      expect(result.adultScore, 0.0);
      expect(result.violenceScore, 0.0);
      expect(result.racyScore, 0.0);
    });

    test('handles boundary values at thresholds', () {
      // Adult at exactly threshold (0.7) should be rejected
      final result = ImageModerationResult.fromApiResponse({
        'adult': 0.7,
        'violence': 0.0,
        'racy': 0.0,
      });
      expect(result.isApproved, isFalse);
    });

    test('approves just below thresholds', () {
      final result = ImageModerationResult.fromApiResponse({
        'adult': 0.69,
        'violence': 0.79,
        'racy': 0.89,
      });
      expect(result.isApproved, isTrue);
    });
  });

  // ===========================================================================
  // DATA MODELS
  // ===========================================================================

  group('ContentAnalysisResult', () {
    test('serializes to JSON correctly', () {
      const result = ContentAnalysisResult(
        isApproved: false,
        issues: [
          ContentIssue(
            type: ContentIssueType.profanity,
            severity: ContentSeverity.medium,
            description: 'Contains profanity',
          ),
        ],
        filteredText: 'filtered',
      );

      final json = result.toJson();
      expect(json['isApproved'], isFalse);
      expect(json['filteredText'], 'filtered');
      expect((json['issues'] as List).length, 1);
    });

    test('toJsonString returns valid JSON string', () {
      const result = ContentAnalysisResult(
        isApproved: true,
        issues: [],
        filteredText: 'clean text',
      );

      final jsonStr = result.toJsonString();
      expect(jsonStr, contains('"isApproved":true'));
      expect(jsonStr, contains('"filteredText":"clean text"'));
    });
  });

  group('ContentIssue', () {
    test('serializes to JSON correctly', () {
      const issue = ContentIssue(
        type: ContentIssueType.harassment,
        severity: ContentSeverity.high,
        description: 'Threatening language',
      );

      final json = issue.toJson();
      expect(json['type'], 'harassment');
      expect(json['severity'], 'high');
      expect(json['description'], 'Threatening language');
    });
  });

  group('ReportCategory', () {
    test('has correct display names', () {
      expect(ReportCategory.harassment.displayName, 'Harassment or bullying');
      expect(ReportCategory.spam.displayName, 'Spam or scam');
      expect(ReportCategory.impersonation.displayName, 'Impersonation');
      expect(ReportCategory.underage.displayName, 'Underage user');
      expect(ReportCategory.violence.displayName, 'Threats or violence');
      expect(ReportCategory.hateSpeech.displayName, 'Hate speech');
      expect(ReportCategory.other.displayName, 'Other');
      expect(
        ReportCategory.inappropriateContent.displayName,
        'Inappropriate content',
      );
    });
  });
}

class _FakeFunctionsPlatform extends FirebaseFunctionsPlatform {
  _FakeFunctionsPlatform() : super(null, 'us-central1');

  Future<dynamic> Function(String functionName, Object? parameters)? onCall;

  void reset() {
    onCall = null;
  }

  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) {
    return this;
  }

  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) {
    return _FakeHttpsCallable(this, origin, name, options, null);
  }

  @override
  HttpsCallablePlatform httpsCallableWithUri(
    String? origin,
    Uri uri,
    HttpsCallableOptions options,
  ) {
    return _FakeHttpsCallable(this, origin, null, options, uri);
  }
}

class _FakeHttpsCallable extends HttpsCallablePlatform {
  _FakeHttpsCallable(
    super.functions,
    super.origin,
    super.name,
    super.options,
    super.uri,
  );

  _FakeFunctionsPlatform get _functions => functions as _FakeFunctionsPlatform;

  @override
  Future<dynamic> call([dynamic parameters]) async {
    final handler = _functions.onCall;
    if (handler == null) {
      throw FirebaseFunctionsException(
        code: 'unavailable',
        message: 'No fake callable response configured',
      );
    }
    return handler(name ?? uri.toString(), parameters);
  }

  @override
  Stream<dynamic> stream(Object? parameters) => const Stream<dynamic>.empty();
}
