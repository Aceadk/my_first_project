import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_project/data/models/preferences.dart';
import 'package:my_first_project/data/models/profile.dart';
import 'package:my_first_project/data/models/subscription.dart';
import 'package:my_first_project/data/models/user.dart';
import 'package:my_first_project/data/models/match.dart';
import 'package:my_first_project/data/models/message.dart';
import 'package:my_first_project/data/repositories/chat_repository.dart';
import 'package:my_first_project/data/repositories/auth_repository.dart';
import 'package:my_first_project/data/repositories/discovery_repository.dart';
import 'package:my_first_project/data/repositories/profile_repository.dart';
import 'package:my_first_project/data/repositories/subscription_repository.dart';
import 'package:my_first_project/logic/auth/auth_bloc.dart';
import 'package:my_first_project/logic/auth/auth_state.dart';
import 'package:my_first_project/logic/discovery/discovery_bloc.dart';
import 'package:my_first_project/logic/discovery/discovery_state.dart';
import 'package:my_first_project/logic/profile/profile_bloc.dart';
import 'package:my_first_project/logic/profile/profile_state.dart';
import 'package:my_first_project/logic/safety/safety_cubit.dart';
import 'package:my_first_project/presentation/screens/deck_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefs = DiscoveryPreferences(
    minAge: 18,
    maxAge: 45,
    maxDistanceKm: 50,
    showMeGenders: ['female', 'male'],
    showMyDistance: true,
    showMyAge: true,
    hideFromDiscovery: false,
    incognitoMode: false,
    country: 'US',
    city: 'NYC',
  );

  const incompleteProfile = Profile(
    id: 'user-1',
    name: 'Alex',
    age: 26,
    gender: 'other',
    sexualOrientation: null,
    bio: '',
    photoUrls: [],
    videoUrls: [],
    prompts: [],
    isVerified: false,
    jobTitle: null,
    company: null,
    school: null,
    interests: ['music'],
    country: 'US',
    city: 'NYC',
    latitude: null,
    longitude: null,
    preferences: prefs,
  );

  final deckProfile = incompleteProfile.copyWith(id: 'deck-1', name: 'Taylor');

  testWidgets('deck shows gating dialog when profile incomplete on like tap',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefsInstance = await SharedPreferences.getInstance();

    const user = CrushUser(
      id: 'user-1',
      phoneNumber: '+10000000000',
      email: null,
      profile: incompleteProfile,
      isPhoneVerified: true,
      isIdVerified: true,
      plan: SubscriptionPlan.free,
    );

    final authRepo = _StubAuthRepository(user);
    final profileRepo = _StubProfileRepository(user);
    final authBloc = _StubAuthBloc(user, authRepo);
    final profileBloc = _StubProfileBloc(profileRepo, authRepo);
    final discoveryBloc = _StubDiscoveryBloc(deckProfile);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepo),
          RepositoryProvider<ProfileRepository>.value(value: profileRepo),
          RepositoryProvider<SubscriptionRepository>.value(
            value: _StubSubscriptionRepository(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<SafetyCubit>(
              create: (_) => SafetyCubit(
                preferences: prefsInstance,
                chatRepository: _NoopChatRepository(),
              ),
            ),
          ],
          child: const MaterialApp(home: DeckScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(find.textContaining('Complete your profile'), findsOneWidget);
  });
}

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository(this.user);

  final CrushUser user;

  @override
  Stream<CrushUser?> authStateChanges() => Stream.value(user);

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async =>
      user;

  @override
  Future<void> signOut() async {}
}

class _StubProfileRepository implements ProfileRepository {
  _StubProfileRepository(this.user);
  final CrushUser user;

  @override
  Future<CrushUser?> getCurrentUser() async => user;

  @override
  Future<CrushUser> saveBasicInfo({
    required String name,
    required int age,
    required String gender,
    String? sexualOrientation,
  }) async =>
      user;

  @override
  Future<CrushUser> saveProfileDetails({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
    List<String>? prompts,
  }) async =>
      user;

  @override
  Future<void> uploadIdDocument() async {}

  @override
  Future<CrushUser> markIdVerified() async => user;

  @override
  Future<CrushUser> updateProfile(Profile profile) async =>
      user.copyWith(profile: profile);
}

class _StubDiscoveryRepository implements DiscoveryRepository {
  _StubDiscoveryRepository(this.deck);

  final List<Profile> deck;

  @override
  Future<List<Profile>> fetchDeck(String userId) async => deck;

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
  Future<List<Profile>> fetchTopPicks(String userId) async => deck;

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async => deck;

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => const [];
}

class _StubSubscriptionRepository implements SubscriptionRepository {
  @override
  Stream<SubscriptionPlan> watchPlan() => Stream.value(SubscriptionPlan.free);

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => SubscriptionPlan.free;

  @override
  Future<void> purchasePlusPlan() async {}

  @override
  Future<String> startPlusCheckout() async => '';

  @override
  Future<void> launchCheckoutUrl(String url) async {}
}

class _StubAuthBloc extends AuthBloc {
  _StubAuthBloc(CrushUser user, AuthRepository authRepo)
      : super(authRepository: authRepo) {
    emit(AuthState(
      status: AuthStatus.authenticated,
      user: user,
      phoneInProgress: null,
    ));
  }
}

class _StubProfileBloc extends ProfileBloc {
  _StubProfileBloc(ProfileRepository repo, AuthRepository authRepo)
      : super(profileRepository: repo, authRepository: authRepo) {
    emit(ProfileState(
      user: (repo as _StubProfileRepository).user,
      profile: (repo).user.profile,
    ));
  }
}

class _StubDiscoveryBloc extends DiscoveryBloc {
  _StubDiscoveryBloc(Profile profile)
      : super(
          discoveryRepository: _StubDiscoveryRepository([profile]),
          subscriptionRepository: _StubSubscriptionRepository(),
        ) {
    emit(DiscoveryState(
      deck: [profile],
      status: DeckStatus.ready,
      isLoading: false,
      currentIndex: 0,
    ));
  }
}

class _NoopChatRepository implements ChatRepository {
  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {}

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {}

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async => const [];

  @override
  Stream<List<Message>> watchMessages(String matchId) => const Stream.empty();

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {}

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {}

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {}

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {}

  @override
  Stream<Set<String>> watchTyping(String matchId) => const Stream.empty();

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {}

  @override
  Stream<bool> watchPresence(String userId) => const Stream.empty();

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {}

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) => const Stream.empty();

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {}

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {}

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async =>
      '';

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {}

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {}

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {}
}
