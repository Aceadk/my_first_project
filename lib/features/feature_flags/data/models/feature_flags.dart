import 'package:equatable/equatable.dart';

/// Feature flags for controlling app behavior remotely.
///
/// These can be toggled via Firebase Remote Config without requiring
/// an app update. Default values ensure the app works offline.
class FeatureFlags extends Equatable {
  const FeatureFlags({
    // Discovery features
    this.enableSuperLike = true,
    this.enableRewind = true,
    this.dailyLikeLimit = 100,
    this.dailySuperLikeLimit = 5,
    this.enableBoost = true,
    this.boostDurationMinutes = 30,

    // Chat features
    this.enableVideoChat = true,
    this.enableVoiceMessages = true,
    this.enableGifMessages = true,
    this.enableReactions = true,
    this.enableReadReceipts = true,
    this.enableTypingIndicators = true,
    this.maxMediaPerDay = 10,

    // Profile features
    this.enableProfileVerification = true,
    this.enableSpotifyIntegration = false,
    this.enableInstagramIntegration = false,
    this.maxPhotos = 6,
    this.maxVideos = 2,
    this.enablePrompts = true,
    this.maxPrompts = 3,

    // Subscription features
    this.enablePlusSubscription = true,
    this.enableFreeTrial = true,
    this.freeTrialDays = 7,
    this.showUpsellAfterSwipes = 10,

    // Safety features
    this.enableSafetyCenter = true,
    this.enableBlockAndReport = true,
    this.enableIncognitoMode = true,
    this.enablePhotoVerification = true,

    // Experiment flags
    this.enableNewMatchAnimation = false,
    this.enableSwipeGestureTutorial = true,
    this.enableProfileCompletenessReminder = true,
    this.profileCompletenessThreshold = 70,

    // Maintenance
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.minAppVersion = '1.0.0',
    this.forceUpdate = false,
    this.forceUpdateMessage = '',

    // Analytics
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.debugLoggingEnabled = false,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable the super like feature
  final bool enableSuperLike;

  /// Enable rewind (undo last swipe) feature
  final bool enableRewind;

  /// Maximum likes per day for free users
  final int dailyLikeLimit;

  /// Maximum super likes per day
  final int dailySuperLikeLimit;

  /// Enable profile boost feature
  final bool enableBoost;

  /// Duration of a boost in minutes
  final int boostDurationMinutes;

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable video chat feature
  final bool enableVideoChat;

  /// Enable voice message feature
  final bool enableVoiceMessages;

  /// Enable GIF messages
  final bool enableGifMessages;

  /// Enable message reactions
  final bool enableReactions;

  /// Enable read receipts
  final bool enableReadReceipts;

  /// Enable typing indicators
  final bool enableTypingIndicators;

  /// Maximum media messages per day for free users
  final int maxMediaPerDay;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable profile verification badge feature
  final bool enableProfileVerification;

  /// Enable Spotify integration for favorite songs
  final bool enableSpotifyIntegration;

  /// Enable Instagram photo import
  final bool enableInstagramIntegration;

  /// Maximum number of photos allowed
  final int maxPhotos;

  /// Maximum number of videos allowed
  final int maxVideos;

  /// Enable profile prompts feature
  final bool enablePrompts;

  /// Maximum number of prompts
  final int maxPrompts;

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable Plus subscription offering
  final bool enablePlusSubscription;

  /// Enable free trial for new users
  final bool enableFreeTrial;

  /// Number of days for free trial
  final int freeTrialDays;

  /// Show upsell dialog after this many swipes
  final int showUpsellAfterSwipes;

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFETY FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable safety center in app
  final bool enableSafetyCenter;

  /// Enable block and report functionality
  final bool enableBlockAndReport;

  /// Enable incognito/hidden mode
  final bool enableIncognitoMode;

  /// Enable photo verification for verified badge
  final bool enablePhotoVerification;

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPERIMENT FLAGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable new match celebration animation
  final bool enableNewMatchAnimation;

  /// Show swipe gesture tutorial for new users
  final bool enableSwipeGestureTutorial;

  /// Show profile completeness reminder
  final bool enableProfileCompletenessReminder;

  /// Minimum profile completeness percentage to enable swiping
  final int profileCompletenessThreshold;

  // ═══════════════════════════════════════════════════════════════════════════
  // MAINTENANCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Put app in maintenance mode
  final bool maintenanceMode;

  /// Message to show during maintenance
  final String maintenanceMessage;

  /// Minimum required app version
  final String minAppVersion;

  /// Force users to update
  final bool forceUpdate;

  /// Message to show for force update
  final String forceUpdateMessage;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable analytics tracking
  final bool enableAnalytics;

  /// Enable crash reporting
  final bool enableCrashReporting;

  /// Enable debug logging (should be false in production)
  final bool debugLoggingEnabled;

  /// Default feature flags
  static const defaults = FeatureFlags();

  /// Create feature flags from a map (typically from Remote Config)
  factory FeatureFlags.fromMap(Map<String, dynamic> map) {
    return FeatureFlags(
      // Discovery
      enableSuperLike: map['enable_super_like'] as bool? ?? true,
      enableRewind: map['enable_rewind'] as bool? ?? true,
      dailyLikeLimit: map['daily_like_limit'] as int? ?? 100,
      dailySuperLikeLimit: map['daily_super_like_limit'] as int? ?? 5,
      enableBoost: map['enable_boost'] as bool? ?? true,
      boostDurationMinutes: map['boost_duration_minutes'] as int? ?? 30,

      // Chat
      enableVideoChat: map['enable_video_chat'] as bool? ?? true,
      enableVoiceMessages: map['enable_voice_messages'] as bool? ?? true,
      enableGifMessages: map['enable_gif_messages'] as bool? ?? true,
      enableReactions: map['enable_reactions'] as bool? ?? true,
      enableReadReceipts: map['enable_read_receipts'] as bool? ?? true,
      enableTypingIndicators: map['enable_typing_indicators'] as bool? ?? true,
      maxMediaPerDay: map['max_media_per_day'] as int? ?? 10,

      // Profile
      enableProfileVerification:
          map['enable_profile_verification'] as bool? ?? true,
      enableSpotifyIntegration:
          map['enable_spotify_integration'] as bool? ?? false,
      enableInstagramIntegration:
          map['enable_instagram_integration'] as bool? ?? false,
      maxPhotos: map['max_photos'] as int? ?? 6,
      maxVideos: map['max_videos'] as int? ?? 2,
      enablePrompts: map['enable_prompts'] as bool? ?? true,
      maxPrompts: map['max_prompts'] as int? ?? 3,

      // Subscription
      enablePlusSubscription:
          map['enable_plus_subscription'] as bool? ?? true,
      enableFreeTrial: map['enable_free_trial'] as bool? ?? true,
      freeTrialDays: map['free_trial_days'] as int? ?? 7,
      showUpsellAfterSwipes: map['show_upsell_after_swipes'] as int? ?? 10,

      // Safety
      enableSafetyCenter: map['enable_safety_center'] as bool? ?? true,
      enableBlockAndReport: map['enable_block_and_report'] as bool? ?? true,
      enableIncognitoMode: map['enable_incognito_mode'] as bool? ?? true,
      enablePhotoVerification:
          map['enable_photo_verification'] as bool? ?? true,

      // Experiments
      enableNewMatchAnimation:
          map['enable_new_match_animation'] as bool? ?? false,
      enableSwipeGestureTutorial:
          map['enable_swipe_gesture_tutorial'] as bool? ?? true,
      enableProfileCompletenessReminder:
          map['enable_profile_completeness_reminder'] as bool? ?? true,
      profileCompletenessThreshold:
          map['profile_completeness_threshold'] as int? ?? 70,

      // Maintenance
      maintenanceMode: map['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: map['maintenance_message'] as String? ?? '',
      minAppVersion: map['min_app_version'] as String? ?? '1.0.0',
      forceUpdate: map['force_update'] as bool? ?? false,
      forceUpdateMessage: map['force_update_message'] as String? ?? '',

      // Analytics
      enableAnalytics: map['enable_analytics'] as bool? ?? true,
      enableCrashReporting: map['enable_crash_reporting'] as bool? ?? true,
      debugLoggingEnabled: map['debug_logging_enabled'] as bool? ?? false,
    );
  }

  /// Convert to map for storage/debugging
  Map<String, dynamic> toMap() {
    return {
      'enable_super_like': enableSuperLike,
      'enable_rewind': enableRewind,
      'daily_like_limit': dailyLikeLimit,
      'daily_super_like_limit': dailySuperLikeLimit,
      'enable_boost': enableBoost,
      'boost_duration_minutes': boostDurationMinutes,
      'enable_video_chat': enableVideoChat,
      'enable_voice_messages': enableVoiceMessages,
      'enable_gif_messages': enableGifMessages,
      'enable_reactions': enableReactions,
      'enable_read_receipts': enableReadReceipts,
      'enable_typing_indicators': enableTypingIndicators,
      'max_media_per_day': maxMediaPerDay,
      'enable_profile_verification': enableProfileVerification,
      'enable_spotify_integration': enableSpotifyIntegration,
      'enable_instagram_integration': enableInstagramIntegration,
      'max_photos': maxPhotos,
      'max_videos': maxVideos,
      'enable_prompts': enablePrompts,
      'max_prompts': maxPrompts,
      'enable_plus_subscription': enablePlusSubscription,
      'enable_free_trial': enableFreeTrial,
      'free_trial_days': freeTrialDays,
      'show_upsell_after_swipes': showUpsellAfterSwipes,
      'enable_safety_center': enableSafetyCenter,
      'enable_block_and_report': enableBlockAndReport,
      'enable_incognito_mode': enableIncognitoMode,
      'enable_photo_verification': enablePhotoVerification,
      'enable_new_match_animation': enableNewMatchAnimation,
      'enable_swipe_gesture_tutorial': enableSwipeGestureTutorial,
      'enable_profile_completeness_reminder': enableProfileCompletenessReminder,
      'profile_completeness_threshold': profileCompletenessThreshold,
      'maintenance_mode': maintenanceMode,
      'maintenance_message': maintenanceMessage,
      'min_app_version': minAppVersion,
      'force_update': forceUpdate,
      'force_update_message': forceUpdateMessage,
      'enable_analytics': enableAnalytics,
      'enable_crash_reporting': enableCrashReporting,
      'debug_logging_enabled': debugLoggingEnabled,
    };
  }

  FeatureFlags copyWith({
    bool? enableSuperLike,
    bool? enableRewind,
    int? dailyLikeLimit,
    int? dailySuperLikeLimit,
    bool? enableBoost,
    int? boostDurationMinutes,
    bool? enableVideoChat,
    bool? enableVoiceMessages,
    bool? enableGifMessages,
    bool? enableReactions,
    bool? enableReadReceipts,
    bool? enableTypingIndicators,
    int? maxMediaPerDay,
    bool? enableProfileVerification,
    bool? enableSpotifyIntegration,
    bool? enableInstagramIntegration,
    int? maxPhotos,
    int? maxVideos,
    bool? enablePrompts,
    int? maxPrompts,
    bool? enablePlusSubscription,
    bool? enableFreeTrial,
    int? freeTrialDays,
    int? showUpsellAfterSwipes,
    bool? enableSafetyCenter,
    bool? enableBlockAndReport,
    bool? enableIncognitoMode,
    bool? enablePhotoVerification,
    bool? enableNewMatchAnimation,
    bool? enableSwipeGestureTutorial,
    bool? enableProfileCompletenessReminder,
    int? profileCompletenessThreshold,
    bool? maintenanceMode,
    String? maintenanceMessage,
    String? minAppVersion,
    bool? forceUpdate,
    String? forceUpdateMessage,
    bool? enableAnalytics,
    bool? enableCrashReporting,
    bool? debugLoggingEnabled,
  }) {
    return FeatureFlags(
      enableSuperLike: enableSuperLike ?? this.enableSuperLike,
      enableRewind: enableRewind ?? this.enableRewind,
      dailyLikeLimit: dailyLikeLimit ?? this.dailyLikeLimit,
      dailySuperLikeLimit: dailySuperLikeLimit ?? this.dailySuperLikeLimit,
      enableBoost: enableBoost ?? this.enableBoost,
      boostDurationMinutes: boostDurationMinutes ?? this.boostDurationMinutes,
      enableVideoChat: enableVideoChat ?? this.enableVideoChat,
      enableVoiceMessages: enableVoiceMessages ?? this.enableVoiceMessages,
      enableGifMessages: enableGifMessages ?? this.enableGifMessages,
      enableReactions: enableReactions ?? this.enableReactions,
      enableReadReceipts: enableReadReceipts ?? this.enableReadReceipts,
      enableTypingIndicators:
          enableTypingIndicators ?? this.enableTypingIndicators,
      maxMediaPerDay: maxMediaPerDay ?? this.maxMediaPerDay,
      enableProfileVerification:
          enableProfileVerification ?? this.enableProfileVerification,
      enableSpotifyIntegration:
          enableSpotifyIntegration ?? this.enableSpotifyIntegration,
      enableInstagramIntegration:
          enableInstagramIntegration ?? this.enableInstagramIntegration,
      maxPhotos: maxPhotos ?? this.maxPhotos,
      maxVideos: maxVideos ?? this.maxVideos,
      enablePrompts: enablePrompts ?? this.enablePrompts,
      maxPrompts: maxPrompts ?? this.maxPrompts,
      enablePlusSubscription:
          enablePlusSubscription ?? this.enablePlusSubscription,
      enableFreeTrial: enableFreeTrial ?? this.enableFreeTrial,
      freeTrialDays: freeTrialDays ?? this.freeTrialDays,
      showUpsellAfterSwipes:
          showUpsellAfterSwipes ?? this.showUpsellAfterSwipes,
      enableSafetyCenter: enableSafetyCenter ?? this.enableSafetyCenter,
      enableBlockAndReport: enableBlockAndReport ?? this.enableBlockAndReport,
      enableIncognitoMode: enableIncognitoMode ?? this.enableIncognitoMode,
      enablePhotoVerification:
          enablePhotoVerification ?? this.enablePhotoVerification,
      enableNewMatchAnimation:
          enableNewMatchAnimation ?? this.enableNewMatchAnimation,
      enableSwipeGestureTutorial:
          enableSwipeGestureTutorial ?? this.enableSwipeGestureTutorial,
      enableProfileCompletenessReminder: enableProfileCompletenessReminder ??
          this.enableProfileCompletenessReminder,
      profileCompletenessThreshold:
          profileCompletenessThreshold ?? this.profileCompletenessThreshold,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      forceUpdateMessage: forceUpdateMessage ?? this.forceUpdateMessage,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      debugLoggingEnabled: debugLoggingEnabled ?? this.debugLoggingEnabled,
    );
  }

  @override
  List<Object?> get props => [
        enableSuperLike,
        enableRewind,
        dailyLikeLimit,
        dailySuperLikeLimit,
        enableBoost,
        boostDurationMinutes,
        enableVideoChat,
        enableVoiceMessages,
        enableGifMessages,
        enableReactions,
        enableReadReceipts,
        enableTypingIndicators,
        maxMediaPerDay,
        enableProfileVerification,
        enableSpotifyIntegration,
        enableInstagramIntegration,
        maxPhotos,
        maxVideos,
        enablePrompts,
        maxPrompts,
        enablePlusSubscription,
        enableFreeTrial,
        freeTrialDays,
        showUpsellAfterSwipes,
        enableSafetyCenter,
        enableBlockAndReport,
        enableIncognitoMode,
        enablePhotoVerification,
        enableNewMatchAnimation,
        enableSwipeGestureTutorial,
        enableProfileCompletenessReminder,
        profileCompletenessThreshold,
        maintenanceMode,
        maintenanceMessage,
        minAppVersion,
        forceUpdate,
        forceUpdateMessage,
        enableAnalytics,
        enableCrashReporting,
        debugLoggingEnabled,
      ];
}
