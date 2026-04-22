import 'base_dto.dart';
import 'profile_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DISCOVERY DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Discovery deck response.
class DiscoveryDeckDto extends BaseDto {
  const DiscoveryDeckDto({
    required this.profiles,
    this.hasMore = false,
    this.nextCursor,
    this.totalCount,
    this.remainingSwipes,
    this.nextRefreshAt,
    this.boostActive,
    this.boostExpiresAt,
  });

  final List<DiscoveryProfileDto> profiles;
  final bool hasMore;
  final String? nextCursor;
  final int? totalCount;
  final int? remainingSwipes;
  final DateTime? nextRefreshAt;
  final bool? boostActive;
  final DateTime? boostExpiresAt;

  factory DiscoveryDeckDto.fromJson(Map<String, dynamic> json) {
    // Support both 'candidates' (new) and 'profiles' (legacy) keys
    final profilesList =
        json.getList(
          'candidates',
          (e) => DiscoveryProfileDto.fromJson(e as Map<String, dynamic>),
        ) ??
        json.getList(
          'profiles',
          (e) => DiscoveryProfileDto.fromJson(e as Map<String, dynamic>),
        ) ??
        [];

    return DiscoveryDeckDto(
      profiles: profilesList,
      hasMore: json.getBool('has_more') ?? json.getBool('hasMore') ?? false,
      nextCursor: json.getString('next_cursor') ?? json.getString('nextCursor'),
      totalCount: json.getInt('total_count') ?? json.getInt('total'),
      remainingSwipes: json.getInt('remaining_swipes'),
      nextRefreshAt: json.getDateTime('next_refresh_at'),
      boostActive: json.getBool('boost_active'),
      boostExpiresAt: json.getDateTime('boost_expires_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'profiles': profiles.map((p) => p.toJson()).toList(),
    'has_more': hasMore,
    if (nextCursor != null) 'next_cursor': nextCursor,
    if (totalCount != null) 'total_count': totalCount,
    if (remainingSwipes != null) 'remaining_swipes': remainingSwipes,
    if (nextRefreshAt != null)
      'next_refresh_at': nextRefreshAt!.toIso8601String(),
    if (boostActive != null) 'boost_active': boostActive,
    if (boostExpiresAt != null)
      'boost_expires_at': boostExpiresAt!.toIso8601String(),
  };
}

/// Discovery profile (subset of full profile for deck).
class DiscoveryProfileDto extends BaseDto {
  const DiscoveryProfileDto({
    required this.id,
    required this.displayName,
    this.age,
    this.bio,
    this.photos,
    this.distance,
    this.distanceUnit,
    this.location,
    this.jobTitle,
    this.company,
    this.education,
    this.height,
    this.interests,
    this.isVerified,
    this.isPremium,
    this.lastActive,
    this.commonInterests,
    this.commonConnections,
  });

  final String id;
  final String displayName;
  final int? age;
  final String? bio;
  final List<ProfilePhotoDto>? photos;
  final double? distance;
  final String? distanceUnit;
  final String? location;
  final String? jobTitle;
  final String? company;
  final String? education;
  final int? height;
  final List<String>? interests;
  final bool? isVerified;
  final bool? isPremium;
  final DateTime? lastActive;
  final List<String>? commonInterests;
  final int? commonConnections;

  /// Get primary photo URL.
  String? get primaryPhotoUrl {
    if (photos == null || photos!.isEmpty) return null;
    return photos!
        .firstWhere((p) => p.isPrimary ?? false, orElse: () => photos!.first)
        .url;
  }

  /// Get distance display string.
  String? get distanceDisplay {
    if (distance == null) return null;
    final unit = distanceUnit ?? 'km';
    if (distance! < 1) {
      return 'Less than 1 $unit away';
    }
    return '${distance!.round()} $unit away';
  }

  factory DiscoveryProfileDto.fromJson(Map<String, dynamic> json) {
    return DiscoveryProfileDto(
      id: json.getString('id') ?? '',
      displayName: json.getString('display_name') ?? '',
      age: json.getInt('age'),
      bio: json.getString('bio'),
      photos: json.getList(
        'photos',
        (e) => ProfilePhotoDto.fromJson(e as Map<String, dynamic>),
      ),
      distance: json.getDouble('distance'),
      distanceUnit: json.getString('distance_unit'),
      location: json.getString('location'),
      jobTitle: json.getString('job_title'),
      company: json.getString('company'),
      education: json.getString('education'),
      height: json.getInt('height'),
      interests: json.getList('interests', (e) => e.toString()),
      isVerified: json.getBool('is_verified'),
      isPremium: json.getBool('is_premium'),
      lastActive: json.getDateTime('last_active'),
      commonInterests: json.getList('common_interests', (e) => e.toString()),
      commonConnections: json.getInt('common_connections'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    if (age != null) 'age': age,
    if (bio != null) 'bio': bio,
    if (photos != null) 'photos': photos!.map((p) => p.toJson()).toList(),
    if (distance != null) 'distance': distance,
    if (distanceUnit != null) 'distance_unit': distanceUnit,
    if (location != null) 'location': location,
    if (jobTitle != null) 'job_title': jobTitle,
    if (company != null) 'company': company,
    if (education != null) 'education': education,
    if (height != null) 'height': height,
    if (interests != null) 'interests': interests,
    if (isVerified != null) 'is_verified': isVerified,
    if (isPremium != null) 'is_premium': isPremium,
    if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
    if (commonInterests != null) 'common_interests': commonInterests,
    if (commonConnections != null) 'common_connections': commonConnections,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIPE DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Swipe action types.
enum SwipeAction {
  like,
  pass,
  superLike,
  rewind;

  String toJson() => name;

  static SwipeAction fromJson(String value) {
    return SwipeAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SwipeAction.pass,
    );
  }
}

/// Swipe request DTO.
class SwipeRequestDto extends BaseDto {
  const SwipeRequestDto({
    required this.targetUserId,
    required this.action,
    this.superLikeMessage,
  });

  final String targetUserId;
  final SwipeAction action;
  final String? superLikeMessage;

  @override
  Map<String, dynamic> toJson() => {
    'target_user_id': targetUserId,
    'action': action.toJson(),
    if (superLikeMessage != null) 'super_like_message': superLikeMessage,
  };

  @override
  String? validate() {
    return DtoValidator()
        .requireNotEmpty(targetUserId, 'target_user_id')
        .build()
        .firstError;
  }
}

/// Swipe response DTO.
class SwipeResponseDto extends BaseDto {
  const SwipeResponseDto({
    required this.success,
    this.isMatch,
    this.match,
    this.remainingSwipes,
    this.remainingSuperLikes,
    this.message,
  });

  final bool success;
  final bool? isMatch;
  final MatchDto? match;
  final int? remainingSwipes;
  final int? remainingSuperLikes;
  final String? message;

  factory SwipeResponseDto.fromJson(Map<String, dynamic> json) {
    return SwipeResponseDto(
      success: json.getBool('success') ?? false,
      isMatch: json.getBool('is_match'),
      match: json.getMap('match') != null
          ? MatchDto.fromJson(json.getMap('match')!)
          : null,
      remainingSwipes: json.getInt('remaining_swipes'),
      remainingSuperLikes: json.getInt('remaining_super_likes'),
      message: json.getString('message'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'success': success,
    if (isMatch != null) 'is_match': isMatch,
    if (match != null) 'match': match!.toJson(),
    if (remainingSwipes != null) 'remaining_swipes': remainingSwipes,
    if (remainingSuperLikes != null)
      'remaining_super_likes': remainingSuperLikes,
    if (message != null) 'message': message,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// MATCH DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Match DTO.
class MatchDto extends BaseDto with DtoMetadata {
  const MatchDto({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    this.matchedUser,
    this.conversationId,
    this.isSuperLike,
    this.superLikeMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String matchedUserId;
  final DiscoveryProfileDto? matchedUser;
  final String? conversationId;
  final bool? isSuperLike;
  final String? superLikeMessage;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String? get serverId => id;

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    final matchedUserId = json.getString('matched_user_id') ?? '';
    final flatMatchedUserName = json.getString('matched_user_name');
    final flatMatchedUserPhoto = json.getString('matched_user_photo');

    return MatchDto(
      id: json.getString('id') ?? '',
      userId: json.getString('user_id') ?? '',
      matchedUserId: matchedUserId,
      matchedUser: json.getMap('matched_user') != null
          ? DiscoveryProfileDto.fromJson(json.getMap('matched_user')!)
          : (flatMatchedUserName != null || flatMatchedUserPhoto != null)
          ? DiscoveryProfileDto(
              id: matchedUserId,
              displayName: flatMatchedUserName ?? '',
              photos: flatMatchedUserPhoto != null
                  ? [
                      ProfilePhotoDto(
                        id: 'photo_0',
                        url: flatMatchedUserPhoto,
                        isPrimary: true,
                      ),
                    ]
                  : null,
            )
          : null,
      conversationId: json.getString('conversation_id'),
      isSuperLike: json.getBool('is_super_like'),
      superLikeMessage: json.getString('super_like_message'),
      createdAt: json.getDateTime('created_at'),
      updatedAt: json.getDateTime('updated_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'matched_user_id': matchedUserId,
    if (matchedUser != null) 'matched_user': matchedUser!.toJson(),
    if (conversationId != null) 'conversation_id': conversationId,
    if (isSuperLike != null) 'is_super_like': isSuperLike,
    if (superLikeMessage != null) 'super_like_message': superLikeMessage,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

/// Matches list response.
class MatchesResponseDto extends BaseDto {
  const MatchesResponseDto({
    required this.matches,
    this.totalCount,
    this.newMatchCount,
    this.hasMore,
    this.nextCursor,
  });

  final List<MatchDto> matches;
  final int? totalCount;
  final int? newMatchCount;
  final bool? hasMore;
  final String? nextCursor;

  factory MatchesResponseDto.fromJson(Map<String, dynamic> json) {
    return MatchesResponseDto(
      matches:
          json.getList(
            'matches',
            (e) => MatchDto.fromJson(e as Map<String, dynamic>),
          ) ??
          [],
      totalCount: json.getInt('total_count'),
      newMatchCount: json.getInt('new_match_count'),
      hasMore: json.getBool('has_more'),
      nextCursor: json.getString('next_cursor'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'matches': matches.map((m) => m.toJson()).toList(),
    if (totalCount != null) 'total_count': totalCount,
    if (newMatchCount != null) 'new_match_count': newMatchCount,
    if (hasMore != null) 'has_more': hasMore,
    if (nextCursor != null) 'next_cursor': nextCursor,
  };
}
