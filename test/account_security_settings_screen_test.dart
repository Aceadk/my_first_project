import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/linked_accounts_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/account_security_settings_screen.dart';

void main() {
  Finder tileForProvider(String provider) {
    return find.ancestor(
      of: find.text(provider),
      matching: find.byType(ListTile),
    );
  }

  Finder actionInTile(String provider, String label) {
    return find.descendant(
      of: tileForProvider(provider),
      matching: find.text(label),
    );
  }

  Future<void> ensureProviderVisible(
    WidgetTester tester,
    String provider,
  ) async {
    final providerFinder = find.text(provider);
    await tester.scrollUntilVisible(
      providerFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required _TestLinkedAuthRepository repository,
  }) async {
    final authBloc = AuthBloc(authRepository: repository)..add(AuthStarted());
    addTearDown(() async {
      await authBloc.close();
      repository.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<AuthRepository>.value(
          value: repository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<BiometricCubit>(create: (_) => BiometricCubit()),
            ],
            child: const AccountSecuritySettingsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows link actions for unlinked Google and Apple providers', (
    tester,
  ) async {
    final repository = _TestLinkedAuthRepository(
      user: _testUser(email: 'tester@example.com', phoneNumber: '+15550001111'),
      linkedProviderIds: const <String>{},
    );

    await pumpScreen(tester, repository: repository);
    await ensureProviderVisible(tester, 'Google');
    await ensureProviderVisible(tester, 'Apple');

    expect(actionInTile('Google', 'Link'), findsOneWidget);
    expect(actionInTile('Apple', 'Link'), findsOneWidget);
  });

  testWidgets('links Google provider and updates UI state', (tester) async {
    final repository = _TestLinkedAuthRepository(
      user: _testUser(email: 'tester@example.com', phoneNumber: '+15550001111'),
      linkedProviderIds: const <String>{},
    );

    await pumpScreen(tester, repository: repository);
    await ensureProviderVisible(tester, 'Google');

    await tester.tap(actionInTile('Google', 'Link'));
    await tester.pumpAndSettle();

    expect(find.text('Google linked successfully.'), findsOneWidget);
    expect(actionInTile('Google', 'Linked'), findsAtLeastNWidgets(1));
    expect(actionInTile('Google', 'Unlink'), findsOneWidget);
  });

  testWidgets('blocks unlink when provider is the last recovery method', (
    tester,
  ) async {
    final repository = _TestLinkedAuthRepository(
      user: _testUser(),
      linkedProviderIds: const <String>{'google.com'},
    );

    await pumpScreen(tester, repository: repository);
    await ensureProviderVisible(tester, 'Google');

    await tester.tap(actionInTile('Google', 'Unlink'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Cannot unlink the last recovery method. Add another provider first.',
      ),
      findsOneWidget,
    );
    expect(actionInTile('Google', 'Linked'), findsAtLeastNWidgets(1));
  });
}

CrushUser _testUser({String? email, String phoneNumber = ''}) {
  return CrushUser(
    id: 'test-user-id',
    phoneNumber: phoneNumber,
    email: email,
    username: 'tester',
    isEmailVerified: email != null && email.isNotEmpty,
    isPhoneVerified: phoneNumber.isNotEmpty,
    isIdVerified: false,
    plan: SubscriptionPlan.free,
  );
}

class _TestLinkedAuthRepository
    implements AuthRepository, LinkedAccountsRepository {
  _TestLinkedAuthRepository({
    required CrushUser? user,
    Set<String>? linkedProviderIds,
  }) : _user = user,
       _linkedProviderIds = <String>{...?linkedProviderIds};

  final StreamController<CrushUser?> _controller =
      StreamController<CrushUser?>.broadcast();
  CrushUser? _user;
  Set<String> _linkedProviderIds;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Future<void> bootstrapSession() async {
    _controller.add(_user);
  }

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async => _user;

  @override
  Future<Set<String>> getLinkedProviderIds() async {
    return _linkedProviderIds;
  }

  @override
  Future<void> linkProvider(LinkedAuthProvider provider) async {
    if (_linkedProviderIds.contains(provider.providerId)) {
      throw Exception('${provider.displayName} is already linked.');
    }
    _linkedProviderIds = <String>{..._linkedProviderIds, provider.providerId};
  }

  @override
  Future<void> unlinkProvider(LinkedAuthProvider provider) async {
    _linkedProviderIds = <String>{
      ..._linkedProviderIds.where((id) => id != provider.providerId),
    };
  }

  void dispose() {
    _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: ${invocation.memberName}');
  }
}
