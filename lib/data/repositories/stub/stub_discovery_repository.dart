import '../../models/profile.dart';
import '../../models/match.dart';
import '../discovery_repository.dart';

/// Stub implementation of DiscoveryRepository.
/// Replace this with your actual backend implementation.
class StubDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<Profile>> fetchDeck(String userId) async {
    // TODO: Implement fetching discovery deck from your backend
    // Return empty list for now
    return [];
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    // TODO: Implement swipe right action via your backend
    throw UnimplementedError('Swipe right not implemented. Connect your backend.');
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    // TODO: Implement swipe left action via your backend
    throw UnimplementedError('Swipe left not implemented. Connect your backend.');
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    // TODO: Implement fetching top picks from your backend
    return [];
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    // TODO: Implement fetching likes from your backend
    return [];
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    // TODO: Implement fetching matches from your backend
    return [];
  }
}
