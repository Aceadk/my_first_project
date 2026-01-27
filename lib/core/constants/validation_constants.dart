/// Validation constants for consistent input limits across the app.
///
/// Centralizes all field length limits and validation rules to ensure
/// consistent behavior in forms, API requests, and data models.
class ValidationConstants {
  ValidationConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT FIELD LIMITS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum length for name fields.
  static const int maxNameLength = 100;

  /// Maximum length for bio/about me fields.
  static const int maxBioLength = 500;

  /// Maximum length for city/location fields.
  static const int maxCityLength = 100;

  /// Maximum length for job title fields.
  static const int maxJobTitleLength = 100;

  /// Maximum length for company name fields.
  static const int maxCompanyLength = 100;

  /// Maximum length for school/university name fields.
  static const int maxSchoolLength = 150;

  /// Maximum length for interest/hobby tags.
  static const int maxInterestLength = 50;

  /// Maximum length for prompt answers.
  static const int maxPromptLength = 300;

  /// Maximum length for profile prompt answers.
  static const int maxPromptAnswerLength = 250;

  /// Maximum length for URLs.
  static const int maxUrlLength = 2000;

  /// Maximum length for message text.
  static const int maxMessageLength = 1000;

  /// Maximum length for usernames.
  static const int maxUsernameLength = 30;

  /// Minimum length for usernames.
  static const int minUsernameLength = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIA LIMITS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum number of photos in a profile.
  static const int maxProfilePhotos = 9;

  /// Minimum number of photos required in a profile.
  static const int minProfilePhotos = 1;

  /// Maximum number of videos in a profile.
  static const int maxProfileVideos = 1;

  /// Maximum video duration in seconds.
  static const int maxVideoDurationSeconds = 15;

  /// Maximum video duration.
  static const Duration maxVideoDuration = Duration(seconds: maxVideoDurationSeconds);

  /// Maximum file size for photos (10 MB).
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024;

  /// Maximum file size for videos (50 MB).
  static const int maxVideoSizeBytes = 50 * 1024 * 1024;

  /// Maximum number of chat attachments per message.
  static const int maxChatAttachments = 5;

  // ═══════════════════════════════════════════════════════════════════════════
  // AGE LIMITS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum age to use the app.
  static const int minAge = 18;

  /// Maximum age for the app (practical limit).
  static const int maxAge = 100;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum number of prompts required.
  static const int minPrompts = 0;

  /// Maximum number of prompts allowed.
  static const int maxPrompts = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD REQUIREMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum password length.
  static const int minPasswordLength = 8;

  /// Maximum password length.
  static const int maxPasswordLength = 128;

  // ═══════════════════════════════════════════════════════════════════════════
  // OTP / VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Length of OTP codes.
  static const int otpLength = 6;

  /// OTP expiration time.
  static const Duration otpExpiration = Duration(minutes: 10);

  // ═══════════════════════════════════════════════════════════════════════════
  // USERNAME CHANGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Days before username can be changed again.
  static const int usernameChangeCooldownDays = 28;
}
