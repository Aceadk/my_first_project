import 'dart:async';
import 'dart:math';
import '../models/photo_verification.dart';

/// Service for managing photo verification with pose matching.
class PhotoVerificationService {
  PhotoVerificationService._();
  static final PhotoVerificationService instance = PhotoVerificationService._();

  final _verificationController =
      StreamController<PhotoVerification>.broadcast();
  final _poseController = StreamController<VerificationPose>.broadcast();

  Stream<PhotoVerification> get verificationStream =>
      _verificationController.stream;
  Stream<VerificationPose> get currentPoseStream => _poseController.stream;

  PhotoVerification? _currentVerification;
  VerificationPose? _currentPose;

  PhotoVerification? get currentVerification => _currentVerification;
  VerificationPose? get currentPose => _currentPose;

  /// Get a random pose for verification.
  VerificationPose getRandomPose() {
    const poses = VerificationPose.values;
    _currentPose = poses[Random().nextInt(poses.length)];
    _poseController.add(_currentPose!);
    return _currentPose!;
  }

  /// Start a new verification session.
  Future<PhotoVerification> startVerification(String userId) async {
    _currentPose = getRandomPose();

    _currentVerification = PhotoVerification(
      userId: userId,
      status: VerificationStatus.pending,
      poseType: _currentPose,
      submittedAt: DateTime.now(),
    );

    _verificationController.add(_currentVerification!);
    return _currentVerification!;
  }

  /// Submit a selfie for verification.
  Future<PhotoVerification> submitSelfie({
    required String userId,
    required String selfieUrl,
  }) async {
    if (_currentVerification == null || _currentPose == null) {
      throw Exception('No active verification session');
    }

    // Simulate AI pose matching (in production, call ML service)
    await Future.delayed(const Duration(seconds: 2));

    // Simulate confidence score (70-100% for demo)
    final confidence = 0.70 + (Random().nextDouble() * 0.30);
    final passed = confidence >= PhotoVerification.minConfidenceScore;

    _currentVerification = _currentVerification!.copyWith(
      selfieUrl: selfieUrl,
      confidenceScore: confidence,
      status:
          passed ? VerificationStatus.verified : VerificationStatus.rejected,
      verifiedAt: passed ? DateTime.now() : null,
      rejectionReason: passed ? null : 'Pose did not match. Please try again.',
      attempts: _currentVerification!.attempts + 1,
    );

    _verificationController.add(_currentVerification!);
    return _currentVerification!;
  }

  /// Get verification status for user.
  Future<PhotoVerification?> getVerificationStatus(String userId) async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentVerification;
  }

  /// Check if user is verified.
  Future<bool> isUserVerified(String userId) async {
    final verification = await getVerificationStatus(userId);
    return verification?.isVerified ?? false;
  }

  /// Reset verification (for retry).
  void resetVerification() {
    if (_currentVerification == null) return;

    _currentVerification = PhotoVerification(
      userId: _currentVerification!.userId,
      status: VerificationStatus.unverified,
      attempts: _currentVerification!.attempts,
    );

    _currentPose = null;
    _verificationController.add(_currentVerification!);
  }

  void dispose() {
    _verificationController.close();
    _poseController.close();
  }
}
