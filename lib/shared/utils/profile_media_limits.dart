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

  /// Maximum file size for photos (bytes).
  static const int maxPhotoSizeBytes = ValidationConstants.maxPhotoSizeBytes;

  /// Maximum photo dimension (width or height, pixels).
  static const int maxPhotoDimension = ValidationConstants.maxPhotoDimension;

  /// Minimum photo dimension (width and height, pixels).
  static const int minPhotoDimension = ValidationConstants.minPhotoDimension;

  static const int maxTotal = maxPhotos + maxVideos;

  const ProfileMediaLimits._();
}
