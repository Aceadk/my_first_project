import 'package:flutter/foundation.dart';

/// Enhanced photo verification service for identity confirmation.
/// Provides selfie-based verification with pose matching and
/// multi-level verification badges.
class PhotoVerificationService {
  PhotoVerificationService._();

  static final PhotoVerificationService _instance =
      PhotoVerificationService._();
  static PhotoVerificationService get instance => _instance;

  // ==========================================================================
  // VERIFICATION LEVELS
  // ==========================================================================

  /// Get verification badge info for display.
  static VerificationBadge getBadgeInfo(VerificationLevel level) {
    return switch (level) {
      VerificationLevel.none => const VerificationBadge(
          level: VerificationLevel.none,
          label: 'Not Verified',
          description: 'This profile has not been verified',
          iconName: 'shield_outlined',
          color: 0xFF6B7280, // Gray
        ),
      VerificationLevel.basic => const VerificationBadge(
          level: VerificationLevel.basic,
          label: 'Basic Verified',
          description: 'Email or phone verified',
          iconName: 'verified_outlined',
          color: 0xFF3B82F6, // Blue
        ),
      VerificationLevel.photo => const VerificationBadge(
          level: VerificationLevel.photo,
          label: 'Photo Verified',
          description: 'Selfie matches profile photos',
          iconName: 'verified',
          color: 0xFF8B5CF6, // Purple
        ),
      VerificationLevel.id => const VerificationBadge(
          level: VerificationLevel.id,
          label: 'ID Verified',
          description: 'Government ID verified',
          iconName: 'verified_user',
          color: 0xFF10B981, // Green
        ),
      VerificationLevel.premium => const VerificationBadge(
          level: VerificationLevel.premium,
          label: 'Premium Verified',
          description: 'Full verification with video call',
          iconName: 'workspace_premium',
          color: 0xFFF59E0B, // Gold
        ),
    };
  }

  // ==========================================================================
  // SELFIE VERIFICATION
  // ==========================================================================

  /// Available verification poses for selfie capture.
  static const List<VerificationPose> verificationPoses = [
    VerificationPose(
      id: 'smile',
      instruction: 'Smile at the camera',
      detectionHint: 'smile_detected',
    ),
    VerificationPose(
      id: 'turn_left',
      instruction: 'Turn your head slightly left',
      detectionHint: 'left_turn_detected',
    ),
    VerificationPose(
      id: 'turn_right',
      instruction: 'Turn your head slightly right',
      detectionHint: 'right_turn_detected',
    ),
    VerificationPose(
      id: 'thumbs_up',
      instruction: 'Show a thumbs up',
      detectionHint: 'thumbs_up_detected',
    ),
    VerificationPose(
      id: 'peace_sign',
      instruction: 'Make a peace sign',
      detectionHint: 'peace_sign_detected',
    ),
  ];

  /// Get a random verification pose for the user.
  VerificationPose getRandomPose() {
    final random = DateTime.now().millisecondsSinceEpoch % verificationPoses.length;
    return verificationPoses[random];
  }

  /// Start a selfie verification session.
  Future<VerificationSession> startVerificationSession({
    required String userId,
    required List<String> profilePhotoUrls,
  }) async {
    final pose = getRandomPose();
    final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

    return VerificationSession(
      sessionId: sessionId,
      userId: userId,
      requiredPose: pose,
      profilePhotoUrls: profilePhotoUrls,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      status: VerificationSessionStatus.pending,
    );
  }

  /// Submit selfie for verification.
  /// Returns verification result with confidence score.
  Future<SelfieVerificationResult> verifySelfie({
    required VerificationSession session,
    required Uint8List selfieBytes,
  }) async {
    // In production, this should:
    // 1. Upload selfie to secure storage
    // 2. Call face comparison API (AWS Rekognition, Google Vision, etc.)
    // 3. Verify pose matches requirement
    // 4. Check liveness detection
    // 5. Compare against profile photos

    if (kDebugMode) {
      debugPrint('[PhotoVerification] Would call face comparison API');
      debugPrint('[PhotoVerification] Session: ${session.sessionId}');
      debugPrint('[PhotoVerification] Required pose: ${session.requiredPose.id}');
    }

    // Simulate verification for development
    // In production, replace with actual API calls
    await Future.delayed(const Duration(seconds: 2));

    return SelfieVerificationResult(
      sessionId: session.sessionId,
      isVerified: true,
      confidenceScore: 0.95,
      poseMatched: true,
      livenessConfirmed: true,
      faceMatchScore: 0.92,
      verifiedAt: DateTime.now(),
    );
  }

  /// Validate image quality before submission.
  ImageQualityResult validateImageQuality(Uint8List imageBytes) {
    final issues = <String>[];

    // Check file size (minimum 100KB, maximum 10MB)
    if (imageBytes.length < 100 * 1024) {
      issues.add('Image resolution is too low. Please use a clearer photo.');
    }
    if (imageBytes.length > 10 * 1024 * 1024) {
      issues.add('Image file is too large. Please use a smaller photo.');
    }

    // Additional checks would include:
    // - Face detection (is there a face?)
    // - Lighting quality
    // - Blur detection
    // - Multiple faces check

    return ImageQualityResult(
      isAcceptable: issues.isEmpty,
      issues: issues,
      brightness: 0.7, // Placeholder - actual implementation would analyze image
      sharpness: 0.8,
      faceDetected: true,
    );
  }

  // ==========================================================================
  // ID DOCUMENT VERIFICATION
  // ==========================================================================

  /// Supported ID document types.
  static const List<IdDocumentType> supportedDocuments = [
    IdDocumentType(
      id: 'passport',
      name: 'Passport',
      description: 'International passport',
      iconName: 'badge',
    ),
    IdDocumentType(
      id: 'drivers_license',
      name: "Driver's License",
      description: 'Government-issued driving license',
      iconName: 'directions_car',
    ),
    IdDocumentType(
      id: 'national_id',
      name: 'National ID Card',
      description: 'Government-issued national ID',
      iconName: 'credit_card',
    ),
  ];

  /// Submit ID document for verification.
  Future<IdVerificationResult> verifyIdDocument({
    required String userId,
    required String documentType,
    required Uint8List frontImageBytes,
    Uint8List? backImageBytes,
  }) async {
    // In production, this should:
    // 1. Upload documents to secure storage
    // 2. Call document verification API
    // 3. Extract and validate document data
    // 4. Compare face on ID with profile photos
    // 5. Check document expiration
    // 6. Verify document authenticity

    if (kDebugMode) {
      debugPrint('[PhotoVerification] Would call ID verification API');
      debugPrint('[PhotoVerification] Document type: $documentType');
    }

    // Simulate verification for development
    await Future.delayed(const Duration(seconds: 3));

    return IdVerificationResult(
      userId: userId,
      documentType: documentType,
      isVerified: true,
      extractedData: const IdExtractedData(
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: null,
        documentNumber: '***REDACTED***',
        expirationDate: null,
      ),
      confidenceScore: 0.98,
      verifiedAt: DateTime.now(),
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Verification levels from lowest to highest trust.
enum VerificationLevel {
  none,
  basic,
  photo,
  id,
  premium,
}

/// Extension for verification level comparison.
extension VerificationLevelExtension on VerificationLevel {
  bool isAtLeast(VerificationLevel other) {
    return index >= other.index;
  }

  bool isHigherThan(VerificationLevel other) {
    return index > other.index;
  }
}

/// Verification badge display information.
class VerificationBadge {
  final VerificationLevel level;
  final String label;
  final String description;
  final String iconName;
  final int color;

  const VerificationBadge({
    required this.level,
    required this.label,
    required this.description,
    required this.iconName,
    required this.color,
  });
}

/// A verification pose requirement.
class VerificationPose {
  final String id;
  final String instruction;
  final String detectionHint;

  const VerificationPose({
    required this.id,
    required this.instruction,
    required this.detectionHint,
  });
}

/// Status of a verification session.
enum VerificationSessionStatus {
  pending,
  inProgress,
  completed,
  failed,
  expired,
}

/// A verification session for selfie capture.
class VerificationSession {
  final String sessionId;
  final String userId;
  final VerificationPose requiredPose;
  final List<String> profilePhotoUrls;
  final DateTime startedAt;
  final DateTime expiresAt;
  final VerificationSessionStatus status;

  const VerificationSession({
    required this.sessionId,
    required this.userId,
    required this.requiredPose,
    required this.profilePhotoUrls,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  VerificationSession copyWith({
    VerificationSessionStatus? status,
  }) {
    return VerificationSession(
      sessionId: sessionId,
      userId: userId,
      requiredPose: requiredPose,
      profilePhotoUrls: profilePhotoUrls,
      startedAt: startedAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
    );
  }
}

/// Result of selfie verification.
class SelfieVerificationResult {
  final String sessionId;
  final bool isVerified;
  final double confidenceScore;
  final bool poseMatched;
  final bool livenessConfirmed;
  final double faceMatchScore;
  final DateTime verifiedAt;
  final String? failureReason;

  const SelfieVerificationResult({
    required this.sessionId,
    required this.isVerified,
    required this.confidenceScore,
    required this.poseMatched,
    required this.livenessConfirmed,
    required this.faceMatchScore,
    required this.verifiedAt,
    this.failureReason,
  });
}

/// Result of image quality validation.
class ImageQualityResult {
  final bool isAcceptable;
  final List<String> issues;
  final double brightness;
  final double sharpness;
  final bool faceDetected;

  const ImageQualityResult({
    required this.isAcceptable,
    required this.issues,
    required this.brightness,
    required this.sharpness,
    required this.faceDetected,
  });
}

/// ID document type information.
class IdDocumentType {
  final String id;
  final String name;
  final String description;
  final String iconName;

  const IdDocumentType({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });
}

/// Result of ID document verification.
class IdVerificationResult {
  final String userId;
  final String documentType;
  final bool isVerified;
  final IdExtractedData extractedData;
  final double confidenceScore;
  final DateTime verifiedAt;
  final String? failureReason;

  const IdVerificationResult({
    required this.userId,
    required this.documentType,
    required this.isVerified,
    required this.extractedData,
    required this.confidenceScore,
    required this.verifiedAt,
    this.failureReason,
  });
}

/// Data extracted from ID document (partially redacted for privacy).
class IdExtractedData {
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? documentNumber;
  final DateTime? expirationDate;

  const IdExtractedData({
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.documentNumber,
    this.expirationDate,
  });

  /// Check if the user is at least a certain age.
  bool isAtLeastAge(int requiredAge) {
    if (dateOfBirth == null) return false;
    final now = DateTime.now();
    final age = now.year -
        dateOfBirth!.year -
        (now.month < dateOfBirth!.month ||
                (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)
            ? 1
            : 0);
    return age >= requiredAge;
  }

  /// Check if document is expired.
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }
}
