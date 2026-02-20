import 'package:equatable/equatable.dart';

/// Photo verification status and data for a user.
class PhotoVerification extends Equatable {
  const PhotoVerification({
    required this.userId,
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.selfieUrl,
    this.poseType,
    this.confidenceScore,
    this.rejectionReason,
    this.attempts = 0,
  });

  /// User ID being verified.
  final String userId;

  /// Current verification status.
  final VerificationStatus status;

  /// When the verification was submitted.
  final DateTime? submittedAt;

  /// When the verification was approved.
  final DateTime? verifiedAt;

  /// URL of the selfie used for verification.
  final String? selfieUrl;

  /// The pose type that was requested.
  final VerificationPose? poseType;

  /// AI confidence score (0.0 - 1.0) for face match.
  final double? confidenceScore;

  /// Reason if verification was rejected.
  final String? rejectionReason;

  /// Number of verification attempts.
  final int attempts;

  /// Maximum allowed attempts per day.
  static const int maxDailyAttempts = 3;

  /// Minimum confidence score to pass verification.
  static const double minConfidenceScore = 0.85;

  /// Check if user is verified.
  bool get isVerified => status == VerificationStatus.verified;

  /// Check if verification is pending review.
  bool get isPending => status == VerificationStatus.pending;

  /// Check if user can attempt verification again.
  bool get canRetry => attempts < maxDailyAttempts;

  PhotoVerification copyWith({
    String? userId,
    VerificationStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? selfieUrl,
    VerificationPose? poseType,
    double? confidenceScore,
    String? rejectionReason,
    int? attempts,
  }) {
    return PhotoVerification(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      poseType: poseType ?? this.poseType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status.name,
      'submittedAt': submittedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'selfieUrl': selfieUrl,
      'poseType': poseType?.name,
      'confidenceScore': confidenceScore,
      'rejectionReason': rejectionReason,
      'attempts': attempts,
    };
  }

  factory PhotoVerification.fromJson(Map<String, dynamic> json) {
    return PhotoVerification(
      userId: json['userId'] as String,
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VerificationStatus.unverified,
      ),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      selfieUrl: json['selfieUrl'] as String?,
      poseType: json['poseType'] != null
          ? VerificationPose.values.firstWhere(
              (e) => e.name == json['poseType'],
              orElse: () => VerificationPose.neutral,
            )
          : null,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      rejectionReason: json['rejectionReason'] as String?,
      attempts: json['attempts'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    status,
    submittedAt,
    verifiedAt,
    selfieUrl,
    poseType,
    confidenceScore,
    rejectionReason,
    attempts,
  ];
}

/// Verification status states.
enum VerificationStatus { unverified, pending, verified, rejected, expired }

/// Pose types for verification selfies.
enum VerificationPose { neutral, smiling, thumbsUp, peace, waving, pointingUp }

/// Get display name for a pose.
extension VerificationPoseExtension on VerificationPose {
  String get displayName {
    switch (this) {
      case VerificationPose.neutral:
        return 'Look straight at the camera';
      case VerificationPose.smiling:
        return 'Smile at the camera';
      case VerificationPose.thumbsUp:
        return 'Give a thumbs up';
      case VerificationPose.peace:
        return 'Show a peace sign';
      case VerificationPose.waving:
        return 'Wave at the camera';
      case VerificationPose.pointingUp:
        return 'Point up with one finger';
    }
  }

  String get emoji {
    switch (this) {
      case VerificationPose.neutral:
        return '😐';
      case VerificationPose.smiling:
        return '😊';
      case VerificationPose.thumbsUp:
        return '👍';
      case VerificationPose.peace:
        return '✌️';
      case VerificationPose.waving:
        return '👋';
      case VerificationPose.pointingUp:
        return '☝️';
    }
  }

  String get instruction {
    switch (this) {
      case VerificationPose.neutral:
        return 'Keep a neutral expression and look directly at the camera';
      case VerificationPose.smiling:
        return 'Show your natural smile while looking at the camera';
      case VerificationPose.thumbsUp:
        return 'Hold your thumb up next to your face';
      case VerificationPose.peace:
        return 'Make a peace sign next to your face';
      case VerificationPose.waving:
        return 'Wave your hand next to your face';
      case VerificationPose.pointingUp:
        return 'Point upward with your index finger';
    }
  }
}
