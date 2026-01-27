import 'package:crushhour/core/constants/validation_constants.dart';

/// Shared limits for profile media across setup and edit flows.
///
/// Re-exports values from [ValidationConstants] for convenient access
/// in media-related code.
class ProfileMediaLimits {
  static const int maxPhotos = ValidationConstants.maxProfilePhotos;
  static const int maxVideos = ValidationConstants.maxProfileVideos;
  static const int minPhotos = ValidationConstants.minProfilePhotos;

  /// Maximum video duration
  static const Duration maxVideoDuration = ValidationConstants.maxVideoDuration;

  static const int maxTotal = maxPhotos + maxVideos;

  const ProfileMediaLimits._();
}
