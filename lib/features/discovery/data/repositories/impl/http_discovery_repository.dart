import 'package:flutter/foundation.dart';

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
  Future<List<Profile>> fetchDeck(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.discoveryDeck,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      debugPrint('HttpDiscoveryRepository: Failed to fetch deck - ${result.error}');
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
      debugPrint('HttpDiscoveryRepository: Swipe right failed - ${result.error}');
      return null;
    }

    final response = SwipeResponseDto.fromJson(result.data!);

    if (response.isMatch == true && response.match != null) {
      return DiscoveryMapper.matchFromDto(response.match!, currentUserId: userId);
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
      debugPrint('HttpDiscoveryRepository: Swipe left failed - ${result.error}');
    }
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/discovery/top-picks',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      debugPrint('HttpDiscoveryRepository: Failed to fetch top picks - ${result.error}');
      return [];
    }

    final profiles = result.data!['profiles'] as List<dynamic>? ?? [];
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
      debugPrint('HttpDiscoveryRepository: Failed to fetch likes - ${result.error}');
      return [];
    }

    final profiles = result.data!['profiles'] as List<dynamic>? ?? [];
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
      debugPrint('HttpDiscoveryRepository: Failed to fetch matches - ${result.error}');
      return [];
    }

    final response = MatchesResponseDto.fromJson(result.data!);
    return response.matches
        .map((dto) => DiscoveryMapper.matchFromDto(dto, currentUserId: userId))
        .toList();
  }
}
