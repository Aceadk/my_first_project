import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/discovery/presentation/bloc/discovery_event.dart';

void main() {
  group('DiscoveryEvent', () {
    test('DiscoveryDeckRequested and load-more events include user id', () {
      expect(DiscoveryDeckRequested('u1').props, ['u1']);
      expect(DiscoveryLoadMoreRequested('u1').props, ['u1']);
      expect(DiscoveryRewindRequested('u1').props, ['u1']);
    });

    test('swipe and super-like events expose user and target ids', () {
      expect(
        DiscoverySwipedRight(
          userId: 'u1',
          targetUserId: 'u2',
          attachedMessage: 'hey',
        ).props,
        ['u1', 'u2', 'hey'],
      );
      expect(DiscoverySwipedLeft(userId: 'u1', targetUserId: 'u2').props, [
        'u1',
        'u2',
      ]);
      expect(DiscoverySuperLiked(userId: 'u1', targetUserId: 'u2').props, [
        'u1',
        'u2',
      ]);
    });

    test('state-reset events have empty props and equatable semantics', () {
      expect(DiscoveryMatchCelebrationShown().props, isEmpty);
      expect(DiscoveryResetRequested().props, isEmpty);
      expect(
        DiscoveryMatchCelebrationShown(),
        DiscoveryMatchCelebrationShown(),
      );
      expect(DiscoveryResetRequested(), DiscoveryResetRequested());
    });
  });
}
