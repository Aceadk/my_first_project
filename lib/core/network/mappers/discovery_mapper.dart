import 'package:crushhour/core/network/dto/discovery_dto.dart';
import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/privacy_settings.dart';

/// Mapper for discovery-related DTOs to domain models.
class DiscoveryMapper {
  DiscoveryMapper._();

  /// Convert DiscoveryProfileDto to Profile domain model.
  static Profile profileFromDiscoveryDto(DiscoveryProfileDto dto) {
    return Profile(
      id: dto.id,
      name: dto.displayName,
      age: dto.age ?? 18,
      gender: '',
      sexualOrientation: null,
      dateOfBirth: null,
      photoUrls: dto.photos?.map((p) => p.url).toList() ?? const [],
      videoUrls: const [],
      primaryPhotoIndex: _findPrimaryPhotoIndex(dto.photos),
      bio: dto.bio ?? '',
      interests: dto.interests ?? const [],
      prompts: const [],
      heightCm: dto.height,
      relationshipGoals: null,
      languages: const [],
      zodiacSign: null,
      educationLevel: dto.education,
      familyPlans: null,
      personalityType: null,
      workout: null,
      socialMedia: null,
      sleepingHabits: null,
      smoking: null,
      drinking: null,
      diet: null,
      exercise: null,
      pets: null,
      jobTitle: dto.jobTitle,
      company: dto.company,
      school: dto.education,
      country: '',
      city: dto.location ?? '',
      livingIn: dto.location,
      latitude: null,
      longitude: null,
      distance: dto.distance,
      distanceUnit: dto.distanceUnit,
      favoriteSongs: const [],
      favoriteSinger: null,
      isVerified: dto.isVerified ?? false,
      verificationBadge: dto.isVerified == true ? 'verified' : null,
      preferences: const DiscoveryPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistanceKm: 50,
        showMeGenders: ['women', 'men'],
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: '',
        city: '',
      ),
      privacySettings: const ProfilePrivacySettings(),
    );
  }

  /// Convert MatchDto to CrushMatch domain model.
  static CrushMatch matchFromDto(
    MatchDto dto, {
    required String currentUserId,
  }) {
    return CrushMatch(
      id: dto.id,
      userId: currentUserId,
      otherUserId: dto.matchedUserId,
      status: MatchStatus.mutual,
      preMatchMessageRequestsCount: 0,
      pinnedForUser: false,
      otherUserName: dto.matchedUser?.displayName,
      otherUserPhotoUrl: dto.matchedUser?.primaryPhotoUrl,
    );
  }

  /// Convert CrushMatch to MatchDto.
  static MatchDto matchToDto(CrushMatch match) {
    return MatchDto(
      id: match.id,
      userId: match.userId,
      matchedUserId: match.otherUserId,
      matchedUser: match.otherUserName != null
          ? DiscoveryProfileDto(
              id: match.otherUserId,
              displayName: match.otherUserName!,
              photos: match.otherUserPhotoUrl != null
                  ? [
                      ProfilePhotoDto(
                        id: 'photo_0',
                        url: match.otherUserPhotoUrl!,
                        isPrimary: true,
                      ),
                    ]
                  : null,
            )
          : null,
      isSuperLike: false,
    );
  }

  /// Convert SwipeAction enum to DTO.
  static SwipeAction swipeActionToDto(bool isLike, {bool isSuperLike = false}) {
    if (isSuperLike) return SwipeAction.superLike;
    return isLike ? SwipeAction.like : SwipeAction.pass;
  }

  static int _findPrimaryPhotoIndex(List<ProfilePhotoDto>? photos) {
    if (photos == null || photos.isEmpty) return 0;
    final primaryIndex = photos.indexWhere((p) => p.isPrimary == true);
    return primaryIndex >= 0 ? primaryIndex : 0;
  }
}
