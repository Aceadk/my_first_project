import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/discovery_dto.dart';
import 'package:crushhour/core/network/mappers/discovery_mapper.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';

/// HTTP-based implementation of DiscoveryRepository.
class HttpDiscoveryRepository implements DiscoveryRepository {
  HttpDiscoveryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  DiscoveryDeckPageInfo? _lastDeckPageInfo;

  @override
  DiscoveryDeckPageInfo? get lastDeckPageInfo => _lastDeckPageInfo;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
    String? cursor,
  }) async {
    final queryParams = <String, String>{};
    if (filter.maxDistanceKm != null) {
      queryParams['maxDistanceKm'] = filter.maxDistanceKm.toString();
    }
    if (filter.passportModeEnabled) {
      queryParams['passportMode'] = 'true';
    }
    if (filter.effectiveLatitude != null) {
      queryParams['latitude'] = filter.effectiveLatitude.toString();
    }
    if (filter.effectiveLongitude != null) {
      queryParams['longitude'] = filter.effectiveLongitude.toString();
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.discoveryDeck,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Failed to fetch deck - ${result.error}',
      );
      return [];
    }

    final deckDto = DiscoveryDeckDto.fromJson(result.data!);
    _lastDeckPageInfo = DiscoveryDeckPageInfo(
      hasMore: deckDto.hasMore,
      nextCursor: deckDto.nextCursor,
    );
    return deckDto.profiles
        .map((dto) => DiscoveryMapper.profileFromDiscoveryDto(dto))
        .toList();
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    final request = SwipeRequestDto(
      targetUserId: targetUserId,
      action: SwipeAction.like,
      superLikeMessage: attachedMessage,
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.discoverySwipe,
      body: request.toJson(),
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Swipe right failed - ${result.error}',
      );
      return null;
    }

    return _matchFromSwipeResponse(
      responseData: result.data!,
      currentUserId: userId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    final request = SwipeRequestDto(
      targetUserId: targetUserId,
      action: SwipeAction.pass,
    );

    final result = await _apiClient.post<void>(
      ApiEndpoints.discoverySwipe,
      body: request.toJson(),
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Swipe left failed - ${result.error}',
      );
    }
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.discoveryTopPicks,
      queryParams: const <String, String>{
        'limit': '10',
        'requireVerified': 'true',
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Failed to fetch top picks - ${result.error}',
      );
      return [];
    }

    // Support both 'candidates' (new) and 'profiles' (legacy) keys
    final profiles =
        result.data!['candidates'] as List<dynamic>? ??
        result.data!['profiles'] as List<dynamic>? ??
        [];
    return profiles
        .map(
          (json) => DiscoveryMapper.profileFromDiscoveryDto(
            DiscoveryProfileDto.fromJson(json as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.discoveryLikesYou,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Failed to fetch likes - ${result.error}',
      );
      return [];
    }

    // Support both 'candidates' (new) and 'profiles' (legacy) keys
    final profiles =
        result.data!['candidates'] as List<dynamic>? ??
        result.data!['profiles'] as List<dynamic>? ??
        [];
    return profiles
        .map(
          (json) => DiscoveryMapper.profileFromDiscoveryDto(
            DiscoveryProfileDto.fromJson(json as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.matches,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Failed to fetch matches - ${result.error}',
      );
      return [];
    }

    final response = MatchesResponseDto.fromJson(result.data!);
    return response.matches
        .map((dto) => DiscoveryMapper.matchFromDto(dto, currentUserId: userId))
        .toList();
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.profileById(profileId),
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Failed to fetch profile - ${result.error}',
      );
      return null;
    }

    return DiscoveryMapper.profileFromDiscoveryDto(
      DiscoveryProfileDto.fromJson(result.data!),
    );
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async {
    final request = SwipeRequestDto(
      targetUserId: targetUserId,
      action: SwipeAction.superLike,
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.discoverySwipe,
      body: request.toJson(),
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpDiscoveryRepository: Super like failed - ${result.error}',
      );
      return null;
    }

    return _matchFromSwipeResponse(
      responseData: result.data!,
      currentUserId: userId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<Profile?> rewindLastSwipe(String userId) async {
    AppLogger.warning(
      'HttpDiscoveryRepository: Rewind is not yet supported by the REST backend.',
    );
    return null;
  }

  CrushMatch? _matchFromSwipeResponse({
    required Map<String, dynamic> responseData,
    required String currentUserId,
    required String targetUserId,
  }) {
    final response = SwipeResponseDto.fromJson(responseData);
    if (response.isMatch == true && response.match != null) {
      return DiscoveryMapper.matchFromDto(
        response.match!,
        currentUserId: currentUserId,
      );
    }

    final isMatch = response.isMatch == true || responseData['matched'] == true;
    if (!isMatch) {
      return null;
    }

    final matchId =
        responseData['match_id'] as String? ??
        responseData['matchId'] as String?;
    if (matchId == null || matchId.isEmpty) {
      return null;
    }

    return CrushMatch(
      id: matchId,
      userId: currentUserId,
      otherUserId: targetUserId,
      status: MatchStatus.mutual,
      preMatchMessageRequestsCount: 0,
      pinnedForUser: false,
    );
  }
}
