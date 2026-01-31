/// Standardized error messages for consistent user experience.
///
/// Format guidelines:
/// - Use active voice: "Could not X" instead of "X failed"
/// - Always include actionable guidance: "Please try again" or specific next step
/// - Keep messages concise but helpful
/// - Use sentence case with period at end
class ErrorMessages {
  ErrorMessages._();

  // Generic errors
  static const String generic = 'Something went wrong. Please try again.';
  static const String networkError =
      'Connection error. Check your internet and try again.';
  static const String timeout = 'Request timed out. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorized = 'Session expired. Please sign in again.';
  static const String notFound = 'The requested item was not found.';
  static const String offline =
      'No internet connection. Check your connection and try again.';

  // Authentication
  static const String loginFailed =
      'Could not sign in. Please check your credentials.';
  static const String signUpFailed =
      'Could not create account. Please try again.';
  static const String logoutFailed = 'Could not sign out. Please try again.';
  static const String invalidCredentials = 'Invalid email or password.';
  static const String emailInUse = 'This email is already registered.';
  static const String weakPassword =
      'Password is too weak. Use at least 8 characters.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String sendCodeFailed = 'Could not send code. Please try again.';
  static const String invalidCode =
      'Invalid or expired code. Please try again.';
  static const String verificationFailed =
      'Verification failed. Please try again.';

  // Profile
  static const String loadProfileFailed =
      'Could not load profile. Please try again.';
  static const String saveProfileFailed =
      'Could not save profile. Please try again.';
  static const String uploadPhotoFailed =
      'Could not upload photo. Please try again.';
  static const String deletePhotoFailed =
      'Could not delete photo. Please try again.';
  static const String updateLocationFailed =
      'Could not update location. Please try again.';
  static const String uploadIdFailed = 'Could not upload ID. Please try again.';

  // Discovery / Deck
  static const String loadDeckFailed =
      'Could not load profiles. Please try again.';
  static const String swipeFailed =
      'Could not process swipe. Please try again.';
  static const String likeFailed = 'Could not like profile. Please try again.';
  static const String passFailed =
      'Could not pass on profile. Please try again.';
  static const String superLikeFailed =
      'Could not super like. Please try again.';
  static const String rewindFailed = 'Could not undo swipe. Please try again.';
  static const String noSwipeToUndo = 'No swipe to undo.';
  static const String freeUndoUsed =
      'You\'ve used your free undo today. Upgrade to Plus for unlimited undos!';
  static const String rewindPremiumOnly =
      'Rewind is a Plus feature. Upgrade to undo swipes!';

  // Chat / Messages
  static const String loadChatsFailed =
      'Could not load chats. Please try again.';
  static const String loadMessagesFailed =
      'Could not load messages. Please try again.';
  static const String sendMessageFailed =
      'Could not send message. Please try again.';
  static const String deleteMessageFailed =
      'Could not delete message. Please try again.';

  // Matches
  static const String loadMatchesFailed =
      'Could not load matches. Please try again.';
  static const String unmatchFailed = 'Could not unmatch. Please try again.';

  // Subscription
  static const String checkoutFailed =
      'Could not start checkout. Please try again.';
  static const String loadSubscriptionFailed =
      'Could not load subscription. Please try again.';
  static const String restorePurchasesFailed =
      'Could not restore purchases. Please try again.';

  // Safety / Moderation
  static const String reportFailed =
      'Could not submit report. Please try again.';
  static const String blockFailed = 'Could not block user. Please try again.';
  static const String unblockFailed =
      'Could not unblock user. Please try again.';

  // Insights / Analytics
  static const String loadInsightsFailed =
      'Could not load insights. Please try again.';

  // Location
  static const String locationDisabled =
      'Location services are disabled. Please enable them in Settings.';
  static const String locationPermissionDenied =
      'Location permission denied. Please allow access in Settings.';
  static const String locationTimeout =
      'Location request timed out. Make sure you have GPS signal and try again.';

  // Media
  static const String mediaLoadFailed =
      'Could not load media. Please try again.';
  static const String mediaUploadFailed =
      'Could not upload media. Please try again.';

  /// Helper to create a custom "could not X" error with retry suggestion.
  static String couldNot(String action) =>
      'Could not $action. Please try again.';

  /// Helper for feature-gated errors.
  static String plusFeature(String feature) =>
      '$feature is a Plus feature. Upgrade to unlock!';
}
