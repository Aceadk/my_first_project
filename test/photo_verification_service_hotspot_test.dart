import 'dart:typed_data';

import 'package:crushhour/core/services/photo_verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoVerificationService hotspots', () {
    final service = PhotoVerificationService.instance;

    test('badge info returns expected labels and levels', () {
      final none = PhotoVerificationService.getBadgeInfo(
        VerificationLevel.none,
      );
      final photo = PhotoVerificationService.getBadgeInfo(
        VerificationLevel.photo,
      );
      final premium = PhotoVerificationService.getBadgeInfo(
        VerificationLevel.premium,
      );

      expect(none.level, VerificationLevel.none);
      expect(none.label, contains('Not Verified'));
      expect(photo.label, contains('Photo'));
      expect(premium.label, contains('Premium'));
    });

    test(
      'random pose and session creation produce valid session data',
      () async {
        final pose = service.getRandomPose();
        expect(
          PhotoVerificationService.verificationPoses.map((p) => p.id),
          contains(pose.id),
        );

        final session = await service.startVerificationSession(
          userId: 'user-1',
          profilePhotoUrls: const ['https://example.com/a.jpg'],
        );

        expect(session.userId, 'user-1');
        expect(session.profilePhotoUrls, isNotEmpty);
        expect(session.requiredPose.id, isNotEmpty);
        expect(session.status, VerificationSessionStatus.pending);
        expect(session.expiresAt.isAfter(session.startedAt), isTrue);
      },
    );

    test('validateImageQuality flags too-small and too-large images', () {
      final tooSmall = Uint8List(50 * 1024);
      final tooLarge = Uint8List(11 * 1024 * 1024);
      final acceptable = Uint8List(300 * 1024);

      final smallResult = service.validateImageQuality(tooSmall);
      final largeResult = service.validateImageQuality(tooLarge);
      final okResult = service.validateImageQuality(acceptable);

      expect(smallResult.isAcceptable, isFalse);
      expect(smallResult.issues.join(' '), contains('too low'));
      expect(largeResult.isAcceptable, isFalse);
      expect(largeResult.issues.join(' '), contains('too large'));
      expect(okResult.isAcceptable, isTrue);
    });

    test('verification session helpers and level extensions work', () {
      const pose = VerificationPose(
        id: 'smile',
        instruction: 'Smile',
        detectionHint: 'smile_detected',
      );
      final pastSession = VerificationSession(
        sessionId: 's1',
        userId: 'u1',
        requiredPose: pose,
        profilePhotoUrls: const [],
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: VerificationSessionStatus.inProgress,
      );

      expect(pastSession.isExpired, isTrue);
      expect(
        pastSession
            .copyWith(status: VerificationSessionStatus.completed)
            .status,
        VerificationSessionStatus.completed,
      );

      expect(
        VerificationLevel.photo.isAtLeast(VerificationLevel.basic),
        isTrue,
      );
      expect(
        VerificationLevel.basic.isHigherThan(VerificationLevel.photo),
        isFalse,
      );
    });

    test('id extracted data age and expiration helpers evaluate correctly', () {
      final adult = IdExtractedData(
        dateOfBirth: DateTime(DateTime.now().year - 25, 1, 1),
        expirationDate: DateTime.now().add(const Duration(days: 10)),
      );
      final minor = IdExtractedData(
        dateOfBirth: DateTime(DateTime.now().year - 16, 1, 1),
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(adult.isAtLeastAge(18), isTrue);
      expect(adult.isExpired, isFalse);
      expect(minor.isAtLeastAge(18), isFalse);
      expect(minor.isExpired, isTrue);
    });

    test(
      'selfie and id verification return successful simulated responses',
      () async {
        final session = await service.startVerificationSession(
          userId: 'user-2',
          profilePhotoUrls: const ['https://example.com/photo.jpg'],
        );
        final selfieResult = await service.verifySelfie(
          session: session,
          selfieBytes: Uint8List(200 * 1024),
        );
        final idResult = await service.verifyIdDocument(
          userId: 'user-2',
          documentType: 'passport',
          frontImageBytes: Uint8List(300 * 1024),
        );

        expect(selfieResult.sessionId, session.sessionId);
        expect(selfieResult.isVerified, isTrue);
        expect(selfieResult.confidenceScore, greaterThan(0.9));

        expect(idResult.userId, 'user-2');
        expect(idResult.documentType, 'passport');
        expect(idResult.isVerified, isTrue);
        expect(idResult.confidenceScore, greaterThan(0.9));
        expect(idResult.extractedData.firstName, isNotNull);
      },
    );
  });
}
