/// Shared limits for profile media across setup and edit flows.
class ProfileMediaLimits {
  static const int maxPhotos = 9;
  static const int maxVideos = 3;
  static const int minPhotos = 1;

  static const int maxTotal = maxPhotos + maxVideos;

  const ProfileMediaLimits._();
}
