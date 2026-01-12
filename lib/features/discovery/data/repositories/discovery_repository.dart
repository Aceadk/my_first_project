import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/match.dart';

abstract class DiscoveryRepository {
  Future<List<Profile>> fetchDeck(String userId);

  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage, // for premium "message before match"
  });

  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  });

  Future<List<Profile>> fetchTopPicks(String userId);

  Future<List<Profile>> fetchLikesYou(String userId);

  Future<List<CrushMatch>> fetchMatches(String userId);
}
