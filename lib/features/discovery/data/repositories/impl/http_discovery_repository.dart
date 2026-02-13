import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/discovery_dto.dart';
import 'package:crushhour/core/network/mappers/discovery_mapper.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/match.dart';
import '../discovery_repository.dart';

/// HTTP-based implementation of DiscoveryRepository.
class HttpDiscoveryRepository implements DiscoveryRepository {
  HttpDiscoveryRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
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

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.discoveryDeck,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpDiscoveryRepository: Failed to fetch deck - ${result.error}');
      return [];
    }

    final deckDto = DiscoveryDeckDto.fromJson(result.data!);
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
          'HttpDiscoveryRepository: Swipe right failed - ${result.error}');
      return null;
    }

    final response = SwipeResponseDto.fromJson(result.data!);

    if (response.isMatch == true && response.match != null) {
      return DiscoveryMapper.matchFromDto(response.match!,
          currentUserId: userId);
    }

    return null;
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
          'HttpDiscoveryRepository: Swipe left failed - ${result.error}');
    }
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/discovery/top-picks',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpDiscoveryRepository: Failed to fetch top picks - ${result.error}');
      return [];
    }

    // Support both 'candidates' (new) and 'profiles' (legacy) keys
    final profiles = result.data!['candidates'] as List<dynamic>? ??
        result.data!['profiles'] as List<dynamic>? ??
        [];
    return profiles
        .map((json) => DiscoveryMapper.profileFromDiscoveryDto(
              DiscoveryProfileDto.fromJson(json as Map<String, dynamic>),
            ))
        .toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/discovery/likes-you',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpDiscoveryRepository: Failed to fetch likes - ${result.error}');
      return [];
    }

    // Support both 'candidates' (new) and 'profiles' (legacy) keys
    final profiles = result.data!['candidates'] as List<dynamic>? ??
        result.data!['profiles'] as List<dynamic>? ??
        [];
    return profiles
        .map((json) => DiscoveryMapper.profileFromDiscoveryDto(
              DiscoveryProfileDto.fromJson(json as Map<String, dynamic>),
            ))
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
          'HttpDiscoveryRepository: Failed to fetch matches - ${result.error}');
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
      '/profiles/$profileId',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpDiscoveryRepository: Failed to fetch profile - ${result.error}');
      return null;
    }

    final data = result.data!['profile'] as Map<String, dynamic>?;
    if (data == null) return null;
    return DiscoveryMapper.profileFromDiscoveryDto(
      DiscoveryProfileDto.fromJson(data),
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
      '/discovery/super-like',
      body: request.toJson(),
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpDiscoveryRepository: Super like failed - ${result.error}');
      return null;
    }

    final response = SwipeResponseDto.fromJson(result.data!);
    if (response.isMatch == true && response.match != null) {
      return DiscoveryMapper.matchFromDto(response.match!,
          currentUserId: userId);
    }

    return null;
  }

  @override
  Future<Profile?> rewindLastSwipe(String userId) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/discovery/rewind',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error('HttpDiscoveryRepository: Rewind failed - ${result.error}');
      return null;
    }

    final profileData = result.data!['profile'] as Map<String, dynamic>?;
    if (profileData == null) return null;
    return DiscoveryMapper.profileFromDiscoveryDto(
      DiscoveryProfileDto.fromJson(profileData),
    );
  }
}
