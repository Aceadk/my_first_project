import 'dart:async';

import 'package:crushhour/core/session/session_bootstrap_service.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/shared/dto/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionBootstrapService', () {
    test('boots and forwards auth stream events on success', () async {
      final authStreamController = StreamController<CrushUser?>.broadcast();
      final repo = _SessionBootstrapAuthRepository(
        authStream: authStreamController.stream,
      );
      final service = SessionBootstrapService(
        authFlowUseCases: AuthFlowUseCases(repo),
      );

      final seen = <CrushUser?>[];
      final result = await service.bootstrap(
        onUserChanged: seen.add,
        existingSubscription: null,
      );

      expect(result.isSuccess, isTrue);
      expect(repo.bootstrapCallCount, 1);

      authStreamController.add(_testUser(id: 'u-1'));
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
      expect(seen.first?.id, 'u-1');

      await result.data?.cancel();
      await authStreamController.close();
    });

    test('cancels existing subscription before creating a new one', () async {
      var oldSubscriptionCancelled = false;
      final oldController = StreamController<CrushUser?>.broadcast(
        onCancel: () => oldSubscriptionCancelled = true,
      );
      final existingSubscription = oldController.stream.listen((_) {});
      addTearDown(() async => existingSubscription.cancel());

      final authStreamController = StreamController<CrushUser?>.broadcast();
      final repo = _SessionBootstrapAuthRepository(
        authStream: authStreamController.stream,
      );
      final service = SessionBootstrapService(
        authFlowUseCases: AuthFlowUseCases(repo),
      );

      final result = await service.bootstrap(
        onUserChanged: (_) {},
        existingSubscription: existingSubscription,
      );

      expect(result.isSuccess, isTrue);
      expect(oldSubscriptionCancelled, isTrue);

      await result.data?.cancel();
      await oldController.close();
      await authStreamController.close();
    });

    test('cancels newly-created subscription when bootstrap fails', () async {
      var authSubscriptionCancelled = false;
      final authStreamController = StreamController<CrushUser?>.broadcast(
        onCancel: () => authSubscriptionCancelled = true,
      );
      final repo = _SessionBootstrapAuthRepository(
        authStream: authStreamController.stream,
        shouldFailBootstrap: true,
      );
      final service = SessionBootstrapService(
        authFlowUseCases: AuthFlowUseCases(repo),
      );

      final result = await service.bootstrap(
        onUserChanged: (_) {},
        existingSubscription: null,
      );

      expect(result.isSuccess, isFalse);
      expect(authSubscriptionCancelled, isTrue);

      await authStreamController.close();
    });
  });
}

class _SessionBootstrapAuthRepository implements AuthRepository {
  _SessionBootstrapAuthRepository({
    required Stream<CrushUser?> authStream,
    this.shouldFailBootstrap = false,
  }) : _authStream = authStream;

  final Stream<CrushUser?> _authStream;
  final bool shouldFailBootstrap;
  int bootstrapCallCount = 0;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  Stream<CrushUser?> authStateChanges() => _authStream;

  @override
  Future<void> bootstrapSession() async {
    bootstrapCallCount++;
    if (shouldFailBootstrap) {
      throw Exception('Bootstrap failed');
    }
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() async => _testUser();

  @override
  Future<CrushUser?> checkEmailVerification() async => _testUser();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deactivateAccount({required String reason}) async {}

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {}

  @override
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async => _testUser();

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<CrushUser?> refreshCurrentUser() async => _testUser();

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> schedulePhoneDeletion() async {}

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> signInWithApple() async => _testUser();

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async => _testUser();

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => _testUser();

  @override
  Future<void> signOut() async {}

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async => _testUser();

  @override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async => 'reset-token';

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async => _testUser();

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async => _testUser();
}

CrushUser _testUser({String id = 'u-test'}) {
  return CrushUser(
    id: id,
    phoneNumber: '+10000000000',
    isEmailVerified: true,
    isPhoneVerified: true,
    isIdVerified: false,
    plan: SubscriptionPlan.free,
  );
}
