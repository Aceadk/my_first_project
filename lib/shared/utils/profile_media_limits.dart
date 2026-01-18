/// Shared limits for profile media across setup and edit flows.
class ProfileMediaLimits {
  static const int maxPhotos = 9;
  static const int maxVideos = 1; // Only 1 video allowed
  static const int minPhotos = 1;

  /// Maximum video duration (15 seconds)
  static const Duration maxVideoDuration = Duration(seconds: 15);

  static const int maxTotal = maxPhotos + maxVideos;

  const ProfileMediaLimits._();
}
