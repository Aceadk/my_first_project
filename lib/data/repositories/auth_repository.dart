import '../models/user.dart';

abstract class AuthRepository {
  Stream<CrushUser?> authStateChanges();

  Future<void> sendOtp(String phoneNumber);

  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<void> signOut();
}
