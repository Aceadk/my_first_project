import 'dart:async';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/impl/http_auth_repository.dart';
import 'package:crushhour/features/auth/data/repositories/impl/http_auth_session_bridge.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../../mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAnalyticsMocks();

  group('HttpAuthRepository contract bridging', () {
    late _FakeHttpAuthSessionBridge sessionBridge;
    late List<_CallableInvocation> invocations;
    late HttpAuthRepository repository;

    setUp(() {
      clearSecureStorageMock();
      invocations = <_CallableInvocation>[];
      sessionBridge = _FakeHttpAuthSessionBridge(
        refreshedUser: _testUser(),
        idToken: 'id-token-1',
      );
      repository = HttpAuthRepository(
        apiClient: ApiClient(
          config: const ApiConfig(baseUrl: 'https://example.com/api'),
          httpClient: MockClient((http.Request request) async {
            if (request.url.path.endsWith('/auth/logout')) {
              return http.Response('{"error":"Invalid or expired token"}', 401);
            }
            throw StateError('Unexpected HTTP request: ${request.url}');
          }),
        ),
        sessionBridge: sessionBridge,
        callableInvoker: (name, payload) async {
          invocations.add(
            _CallableInvocation(
              name: name,
              payload: Map<String, dynamic>.from(payload),
            ),
          );

          switch (name) {
            case 'loginWithPassword':
              return <String, dynamic>{
                'status': 'ok',
                'customToken': 'custom-token-login',
              };
            case 'signUpWithPassword':
              return <String, dynamic>{
                'status': 'ok',
                'customToken': 'custom-token-signup',
              };
            case 'requestEmailOtp':
              return <String, dynamic>{'status': 'ok'};
            case 'verifyEmailOtp':
              return <String, dynamic>{
                'status': 'ok',
                'customToken': 'custom-token-email-otp',
              };
            case 'requestPasswordReset':
              return <String, dynamic>{'status': 'ok'};
            case 'verifyPasswordResetOtp':
              return <String, dynamic>{
                'status': 'ok',
                'resetToken': 'reset-token-123',
              };
            case 'resetPasswordWithToken':
              return <String, dynamic>{'status': 'ok'};
            case 'requestAccountDeletion':
              return <String, dynamic>{'success': true};
          }

          throw StateError('Unexpected callable $name');
        },
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test(
      'loginWithPassword uses callable sign-in and session bridge',
      () async {
        final user = await repository.loginWithPassword(
          identifier: 'ace',
          password: 'pw-123456',
        );

        expect(user.email, 'ace@example.com');
        expect(invocations, hasLength(1));
        expect(invocations.single.name, 'loginWithPassword');
        expect(invocations.single.payload, <String, dynamic>{
          'identifier': 'ace',
          'password': 'pw-123456',
        });
        expect(sessionBridge.customTokens, ['custom-token-login']);
        expect(await repository.getAccessToken(), 'id-token-1');
        expect(await repository.refreshToken(), isTrue);
        expect(sessionBridge.forcedRefreshes, 1);
      },
    );

    test(
      'email OTP flow uses callable contracts and custom-token exchange',
      () async {
        await repository.requestEmailOtp(
          identifier: 'ace@example.com',
          purpose: EmailOtpPurpose.login,
        );

        final user = await repository.verifyEmailOtp(
          identifier: 'ace@example.com',
          otp: '123456',
          purpose: EmailOtpPurpose.login,
        );

        expect(user?.id, 'user-1');
        expect(invocations.map((item) => item.name).toList(), [
          'requestEmailOtp',
          'verifyEmailOtp',
        ]);
        expect(invocations.last.payload, <String, dynamic>{
          'identifier': 'ace@example.com',
          'otp': '123456',
          'purpose': 'login',
        });
        expect(sessionBridge.customTokens.last, 'custom-token-email-otp');
      },
    );

    test(
      'password reset flow uses callable contracts instead of dead REST routes',
      () async {
        await repository.requestPasswordReset(email: 'ace@example.com');
        final resetToken = await repository.verifyPasswordResetOtp(
          email: 'ace@example.com',
          otp: '654321',
        );
        await repository.resetPasswordWithToken(
          email: 'ace@example.com',
          resetToken: resetToken,
          newPassword: 'new-password-123',
        );

        expect(resetToken, 'reset-token-123');
        expect(invocations.map((item) => item.name).toList(), [
          'requestPasswordReset',
          'verifyPasswordResetOtp',
          'resetPasswordWithToken',
        ]);
        expect(invocations.last.payload, <String, dynamic>{
          'email': 'ace@example.com',
          'resetToken': 'reset-token-123',
          'newPassword': 'new-password-123',
        });
      },
    );

    test(
      'deleteAccount verifies password through login callable then requests deletion',
      () async {
        sessionBridge.emitUser(_testUser(email: 'delete-me@example.com'));

        await repository.deleteAccount(
          password: 'pw-123456',
          reason: 'Need a break',
        );

        expect(invocations.map((item) => item.name).toList(), [
          'loginWithPassword',
          'requestAccountDeletion',
        ]);
        expect(invocations.first.payload, <String, dynamic>{
          'identifier': 'delete-me@example.com',
          'password': 'pw-123456',
        });
        expect(invocations.last.payload, <String, dynamic>{
          'reason': 'Need a break',
        });
        expect(sessionBridge.signOutCount, 1);
      },
    );
  });
}

class _CallableInvocation {
  const _CallableInvocation({required this.name, required this.payload});

  final String name;
  final Map<String, dynamic> payload;
}

class _FakeHttpAuthSessionBridge implements HttpAuthSessionBridge {
  _FakeHttpAuthSessionBridge({CrushUser? refreshedUser, this.idToken})
    : _refreshedUser = refreshedUser;

  final _controller = StreamController<CrushUser?>.broadcast(sync: true);
  final List<String> customTokens = <String>[];
  final String? idToken;
  CrushUser? _refreshedUser;
  int forcedRefreshes = 0;
  int signOutCount = 0;

  void emitUser(CrushUser? user) {
    _refreshedUser = user;
    _controller.add(user);
  }

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      forcedRefreshes += 1;
    }
    return idToken;
  }

  @override
  Future<void> signInWithCustomToken(String customToken) async {
    customTokens.add(customToken);
    if (_refreshedUser != null) {
      _controller.add(_refreshedUser);
    }
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async => _refreshedUser ?? _testUser();

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async => _refreshedUser ?? _testUser();

  @override
  Future<CrushUser> signInWithGoogle() async => _refreshedUser ?? _testUser();

  @override
  Future<CrushUser> signInWithApple() async => _refreshedUser ?? _testUser();

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    _refreshedUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => _refreshedUser;

  @override
  Future<void> schedulePhoneDeletion() async {}

  @override
  Future<void> deactivateAccount({required String reason}) async {}

  @override
  Future<CrushUser> acceptTermsAndConditions() async =>
      _refreshedUser ?? _testUser();

  @override
  Future<CrushUser?> refreshCurrentUser() async => _refreshedUser;

  @override
  void dispose() {
    _controller.close();
  }
}

CrushUser _testUser({String id = 'user-1', String? email = 'ace@example.com'}) {
  return CrushUser(
    id: id,
    phoneNumber: '',
    email: email,
    username: 'ace',
    isEmailVerified: true,
    isPhoneVerified: false,
    isIdVerified: false,
    tier: SubscriptionTier.plus,
    hasAcceptedTerms: true,
  );
}
