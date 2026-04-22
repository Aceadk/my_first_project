import 'package:crushhour/core/app_logger.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'firebase_discovery_repository.dart';
import 'stub_discovery_repository.dart';

/// Hybrid implementation that combines Firebase and stub mock profiles.
/// This shows dummy accounts in the discovery deck alongside real users.
///
/// SECURITY: Stub data is ONLY included in debug/profile builds.
/// In release builds, this behaves identically to FirebaseDiscoveryRepository
/// to prevent fake profiles from appearing in production.
class HybridDiscoveryRepository implements DiscoveryRepository {
  HybridDiscoveryRepository()
    : _firebaseRepo = FirebaseDiscoveryRepository(),
      _stubRepo = kReleaseMode ? null : StubDiscoveryRepository() {
    if (kReleaseMode) {
      AppLogger.debug(
        '⚠️ HybridDiscoveryRepository: Running in RELEASE mode - stub data DISABLED',
      );
    } else {
      AppLogger.debug(
        '🧪 HybridDiscoveryRepository: Running in DEBUG mode - stub data enabled',
      );
    }
  }

  final FirebaseDiscoveryRepository _firebaseRepo;
  final StubDiscoveryRepository? _stubRepo;
  DiscoveryDeckPageInfo? _lastDeckPageInfo;

  @override
  DiscoveryDeckPageInfo? get lastDeckPageInfo => _lastDeckPageInfo;

  /// Returns true if stub data should be included (debug/profile builds only)
  bool get _includeStubData => !kReleaseMode && _stubRepo != null;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
    String? cursor,
  }) async {
    // SECURITY: In release mode, only return real Firebase profiles
    if (!_includeStubData) {
      AppLogger.debug(
        'HybridDiscoveryRepository: RELEASE mode - returning Firebase only',
      );
      final profiles = await _firebaseRepo.fetchDeck(
        userId,
        filter: filter,
        cursor: cursor,
      );
      _lastDeckPageInfo = _firebaseRepo.lastDeckPageInfo;
      return profiles;
    }

    // DEBUG/PROFILE: Fetch from both sources in parallel
    late List<Profile> firebaseProfiles;
    late List<Profile> stubProfiles;

    try {
      AppLogger.debug(
        'HybridDiscoveryRepository: Fetching deck for user $userId',
      );
      final results = await Future.wait([
        _firebaseRepo.fetchDeck(userId, filter: filter, cursor: cursor),
        _stubRepo!.fetchDeck(userId, filter: filter, cursor: cursor),
      ]);
      firebaseProfiles = results[0];
      stubProfiles = results[1];
      AppLogger.debug(
        'HybridDiscoveryRepository: Firebase returned ${firebaseProfiles.length} profiles',
      );
      AppLogger.debug(
        'HybridDiscoveryRepository: Stub returned ${stubProfiles.length} profiles (DEBUG ONLY)',
      );
    } catch (e) {
      // If Firebase fails, just use stub profiles (debug only)
      AppLogger.error('HybridDiscoveryRepository: Firebase error: $e');
      firebaseProfiles = [];
      stubProfiles = await _stubRepo!.fetchDeck(
        userId,
        filter: filter,
        cursor: cursor,
      );
    }

    // Combine and shuffle - stub profiles included in debug mode only
    final combined = <Profile>[...firebaseProfiles, ...stubProfiles];

    // Shuffle to mix real and dummy accounts
    combined.shuffle();

    // Cursor pagination is only deterministic in the Firebase-backed release path.
    _lastDeckPageInfo = const DiscoveryDeckPageInfo(hasMore: false);

    return combined;
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    // Check if this is a mock profile (IDs start with 'mock_')
    // SECURITY: Only allow stub interactions in debug mode
    if (_includeStubData && targetUserId.startsWith('mock_')) {
      return _stubRepo!.swipeRight(
        userId: userId,
        targetUserId: targetUserId,
        attachedMessage: attachedMessage,
      );
    }

    return _firebaseRepo.swipeRight(
      userId: userId,
      targetUserId: targetUserId,
      attachedMessage: attachedMessage,
    );
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    // SECURITY: Only allow stub interactions in debug mode
    if (_includeStubData && targetUserId.startsWith('mock_')) {
      return _stubRepo!.swipeLeft(userId: userId, targetUserId: targetUserId);
    }

    return _firebaseRepo.swipeLeft(userId: userId, targetUserId: targetUserId);
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    // SECURITY: In release mode, only return real Firebase data
    if (!_includeStubData) {
      return _firebaseRepo.fetchTopPicks(userId);
    }

    // DEBUG: Combine top picks from both sources
    List<Profile> firebaseTopPicks = [];
    try {
      firebaseTopPicks = await _firebaseRepo.fetchTopPicks(userId);
    } catch (e) {
      AppLogger.debug(
        'HybridDiscoveryRepository: Firebase fetchTopPicks error (using stub fallback): $e',
      );
    }
    final stubTopPicks = await _stubRepo!.fetchTopPicks(userId);

    return [...firebaseTopPicks, ...stubTopPicks];
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    // SECURITY: In release mode, only return real Firebase data
    if (!_includeStubData) {
      return _firebaseRepo.fetchLikesYou(userId);
    }

    // DEBUG: Combine likes from both sources
    List<Profile> firebaseLikes = [];
    try {
      firebaseLikes = await _firebaseRepo.fetchLikesYou(userId);
    } catch (e) {
      AppLogger.debug(
        'HybridDiscoveryRepository: Firebase fetchLikesYou error (using stub fallback): $e',
      );
    }
    final stubLikes = await _stubRepo!.fetchLikesYou(userId);

    return [...firebaseLikes, ...stubLikes];
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    // SECURITY: In release mode, only return real Firebase data
    if (!_includeStubData) {
      return _firebaseRepo.fetchMatches(userId);
    }

    // DEBUG: Combine matches from both sources
    List<CrushMatch> firebaseMatches = [];
    try {
      firebaseMatches = await _firebaseRepo.fetchMatches(userId);
    } catch (e) {
      AppLogger.debug(
        'HybridDiscoveryRepository: Firebase fetchMatches error (using stub fallback): $e',
      );
    }
    final stubMatches = await _stubRepo!.fetchMatches(userId);

    return [...firebaseMatches, ...stubMatches];
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    // SECURITY: Only allow stub profile lookup in debug mode
    if (_includeStubData && profileId.startsWith('mock_')) {
      return _stubRepo!.fetchProfileById(profileId);
    }

    return _firebaseRepo.fetchProfileById(profileId);
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async {
    // SECURITY: Only allow stub interactions in debug mode
    if (_includeStubData && targetUserId.startsWith('mock_')) {
      return _stubRepo!.superLike(userId: userId, targetUserId: targetUserId);
    }

    return _firebaseRepo.superLike(userId: userId, targetUserId: targetUserId);
  }

  @override
  Future<Profile?> rewindLastSwipe(String userId) async {
    // SECURITY: Only try stub in debug mode
    if (_includeStubData) {
      final stubResult = await _stubRepo!.rewindLastSwipe(userId);
      if (stubResult != null) return stubResult;
    }

    return _firebaseRepo.rewindLastSwipe(userId);
  }
}
