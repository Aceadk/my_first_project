import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'mock/firebase_mock.dart';

void main() {
  setupFirebaseAnalyticsMocks();
  group('DiscoveryBloc', () {
    test('emits empty status when deck is empty', () async {
      final bloc = DiscoveryBloc(
        discoveryRepository: _StubDiscoveryRepository(deck: const []),
        subscriptionRepository:
            _StubSubscriptionRepository(SubscriptionPlan.free),
        authRepository: _StubAuthRepository(),
      );

      bloc.add(DiscoveryDeckRequested('user-1'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DiscoveryState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.status, 'status', DeckStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.status, 'status', DeckStatus.empty)
              .having((s) => s.deck.isEmpty, 'deck empty', true),
        ]),
      );

      await bloc.close();
    });
  });
}

class _StubDiscoveryRepository implements DiscoveryRepository {
  _StubDiscoveryRepository({required this.deck});

  final List<Profile> deck;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async => deck;

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    return null;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {}

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async => const [];

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async => const [];

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => const [];

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    try {
      return deck.firstWhere((p) => p.id == profileId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async => null;

  @override
  Future<Profile?> rewindLastSwipe(String userId) async => null;
}

class _StubSubscriptionRepository implements SubscriptionRepository {
  _StubSubscriptionRepository(this.plan);

  final SubscriptionPlan plan;

  @override
  Stream<SubscriptionPlan> watchPlan() => Stream.value(plan);

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => plan;

  @override
  Future<String> startPlusCheckout() async => 'stub';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<void> purchasePlusPlan() async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(plan: plan);
}

/// Stub AuthRepository for testing - emits no auth state changes.
class _StubAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  Stream<CrushUser?> authStateChanges() => const Stream.empty();

  @override
  Future<void> bootstrapSession() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => null;

  @override
  Future<void> schedulePhoneDeletion() async {}

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
  Future<CrushUser> acceptTermsAndConditions() {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
