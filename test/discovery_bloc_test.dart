import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/repositories/discovery_repository.dart';
import 'package:crushhour/data/repositories/subscription_repository.dart';
import 'package:crushhour/logic/discovery/discovery_bloc.dart';
import 'package:crushhour/logic/discovery/discovery_event.dart';
import 'package:crushhour/logic/discovery/discovery_state.dart';

void main() {
  group('DiscoveryBloc', () {
    test('emits empty status when deck is empty', () async {
      final bloc = DiscoveryBloc(
        discoveryRepository: _StubDiscoveryRepository(deck: const []),
        subscriptionRepository:
            _StubSubscriptionRepository(SubscriptionPlan.free),
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
  Future<List<Profile>> fetchTopPicks(String userId) async => const [];

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async => const [];

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => const [];
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
