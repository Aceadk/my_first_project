import 'package:crushhour/core/connectivity/connectivity_cubit.dart';
// Network
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/services/badge_counter_service.dart';
import 'package:crushhour/core/services/push_notification_service.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';
import 'package:crushhour/features/analytics/domain/repositories/profile_insights_repository.dart';
import 'package:crushhour/features/analytics/presentation/bloc/profile_insights_cubit.dart';
// Firebase implementations
import 'package:crushhour/features/auth/data/repositories/impl/firebase_auth_repository.dart';
// HTTP implementations (for REST API backend)
import 'package:crushhour/features/auth/data/repositories/impl/http_auth_repository.dart';
// Stub implementations (for development/demo without backend)
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
// BLoCs
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';
import 'package:crushhour/features/auth/presentation/bloc/session_bloc.dart';
import 'package:crushhour/features/calls/data/repositories/impl/firebase_call_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/http_call_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/stub_call_repository.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_bloc.dart';
import 'package:crushhour/features/chat/data/repositories/impl/firebase_chat_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/http_chat_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:crushhour/features/chat/data/services/voice_recorder_service.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/voice_recorder_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/firebase_boost_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/firebase_discovery_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/http_discovery_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/hybrid_discovery_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_boost_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_discovery_repository.dart';
import 'package:crushhour/features/discovery/data/services/incognito_service.dart';
import 'package:crushhour/features/discovery/data/services/passport_locations_service.dart';
import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';
import 'package:crushhour/features/discovery/data/services/weekly_picks_service.dart';
import 'package:crushhour/features/discovery/domain/repositories/boost_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';
// Social/Analytics concrete service implementations
import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';
import 'package:crushhour/features/discovery/domain/usecases/swipe_right.dart';
import 'package:crushhour/features/discovery/presentation/bloc/boost_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/feature_flags/data/repositories/impl/firebase_feature_flag_repository.dart';
import 'package:crushhour/features/feature_flags/data/repositories/impl/stub_feature_flag_repository.dart';
import 'package:crushhour/features/feature_flags/domain/repositories/feature_flag_repository.dart';
import 'package:crushhour/features/feature_flags/presentation/bloc/feature_flag_cubit.dart';
import 'package:crushhour/features/notifications/data/repositories/impl/firebase_notification_repository.dart';
import 'package:crushhour/features/notifications/domain/repositories/notification_repository.dart';
import 'package:crushhour/features/notifications/presentation/bloc/notification_center_cubit.dart';
import 'package:crushhour/features/profile/data/repositories/impl/firebase_profile_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/http_profile_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/stub_profile_repository.dart';
import 'package:crushhour/features/profile/data/services/profile_media_service.dart';
import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/settings/data/preferences/notification_preference_sync_service.dart';
import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';
import 'package:crushhour/features/social/domain/repositories/compatibility_quiz_repository.dart';
import 'package:crushhour/features/social/domain/repositories/date_idea_repository.dart';
import 'package:crushhour/features/social/presentation/bloc/compatibility_quiz_cubit.dart';
import 'package:crushhour/features/social/presentation/bloc/date_ideas_cubit.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/firebase_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/http_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/stub_subscription_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend configuration for the app.
/// Switch between stub (development/demo), Firebase (production), hybrid, or HTTP (REST API).
enum BackendMode {
  /// Use stub repositories for development and demo without a real backend.
  /// All data is stored locally using SharedPreferences.
  stub,

  /// Use Firebase repositories for production.
  /// Requires proper Firebase configuration.
  firebase,

  /// Use hybrid mode: Firebase for most features, but discovery shows both
  /// real Firebase profiles AND stub/demo profiles mixed together.
  /// Great for testing and demos when Firebase has few real users.
  hybrid,

  /// Use HTTP repositories for REST API backend.
  /// Requires API server configuration.
  http,
}

class CrushDI {
  /// Current backend mode. Change this to switch between implementations.
  /// In production builds, this should be [BackendMode.firebase] or [BackendMode.http].
  /// For development/demo, use [BackendMode.stub] or [BackendMode.hybrid].
  static BackendMode _backendMode = BackendMode.firebase;

  static BackendMode get backendMode => _backendMode;

  static void setBackendModeForTesting(BackendMode mode) {
    _backendMode = mode;
  }

  static void resetBackendModeForTesting() {
    _backendMode = BackendMode.firebase;
  }

  /// Singleton API client for HTTP mode.
  static ApiClient? _apiClient;
  static HttpAuthRepository? _httpAuthRepository;

  /// Get or create the API client.
  static ApiClient get apiClient {
    _apiClient ??= ApiClient(
      config: ApiConfig.production,
      authTokenProvider: () async {
        if (_httpAuthRepository == null) return null;
        return _httpAuthRepository!.getAccessToken();
      },
      tokenRefreshProvider: () async {
        if (_httpAuthRepository == null) return null;
        final success = await _httpAuthRepository!.refreshToken();
        if (success) {
          return _httpAuthRepository!.getAccessToken();
        }
        return null;
      },
      onAuthError: () {
        // Handle auth error - trigger logout
        _httpAuthRepository?.signOut();
      },
      onVersionMismatch: (result) {
        // Handle version mismatch - show update dialog
        if (result.upgradeRequired) {
          // Force update required
        }
      },
    );
    return _apiClient!;
  }

  static List<RepositoryProvider> buildRepositories() {
    // Create repositories based on backend mode
    final AuthRepository authRepo;
    final ProfileRepository profileRepo;
    final SubscriptionRepository subRepo;
    final DiscoveryRepository discoveryRepo;
    final ChatRepository chatRepo;
    final CallRepository callRepo;
    final CallManagerRepository callManagerRepo = CallService.instance;
    final FeatureFlagRepository featureFlagRepo;
    final BoostRepository boostRepo;

    switch (_backendMode) {
      case BackendMode.stub:
        // Stub implementations for development/demo
        authRepo = StubAuthRepository();
        profileRepo = StubProfileRepository();
        subRepo = StubSubscriptionRepository();
        discoveryRepo = StubDiscoveryRepository();
        chatRepo = StubChatRepository();
        callRepo = StubCallRepository();
        featureFlagRepo = StubFeatureFlagRepository();
        boostRepo = StubBoostRepository(subscriptionRepository: subRepo);

      case BackendMode.firebase:
        // Firebase implementations for production
        // Using FirebaseDiscoveryRepository to show only real users
        authRepo = FirebaseAuthRepository();
        profileRepo = FirebaseProfileRepository();
        subRepo = FirebaseSubscriptionRepository();
        discoveryRepo = FirebaseDiscoveryRepository();
        chatRepo = FirebaseChatRepository();
        callRepo = FirebaseCallRepository();
        featureFlagRepo = FirebaseFeatureFlagRepository();
        boostRepo = FirebaseBoostRepository(subscriptionRepository: subRepo);

      case BackendMode.hybrid:
        // Hybrid mode: Firebase for everything except discovery
        // Discovery uses HybridDiscoveryRepository to show both real + stub profiles
        authRepo = FirebaseAuthRepository();
        profileRepo = FirebaseProfileRepository();
        subRepo = FirebaseSubscriptionRepository();
        discoveryRepo =
            HybridDiscoveryRepository(); // Shows both real and fake profiles
        chatRepo = FirebaseChatRepository();
        callRepo = FirebaseCallRepository();
        featureFlagRepo = FirebaseFeatureFlagRepository();
        boostRepo = FirebaseBoostRepository(subscriptionRepository: subRepo);

      case BackendMode.http:
        // HTTP implementations for REST API backend
        final client = apiClient;

        // Create auth repository first (needed for token provider)
        _httpAuthRepository = HttpAuthRepository(apiClient: client);
        authRepo = _httpAuthRepository!;

        // Create other repositories with the same client
        profileRepo = HttpProfileRepository(apiClient: client);
        subRepo = HttpSubscriptionRepository(apiClient: client);
        discoveryRepo = HttpDiscoveryRepository(apiClient: client);
        chatRepo = HttpChatRepository(apiClient: client);
        callRepo = HttpCallRepository(apiClient: client);

        // Use stub for feature flags until HTTP implementation is added
        featureFlagRepo = StubFeatureFlagRepository();
        // Use stub boost repo until HTTP implementation is added
        boostRepo = StubBoostRepository(subscriptionRepository: subRepo);
    }

    return [
      RepositoryProvider<AuthRepository>.value(value: authRepo),
      RepositoryProvider<ProfileRepository>.value(value: profileRepo),
      RepositoryProvider<SubscriptionRepository>.value(value: subRepo),
      RepositoryProvider<DiscoveryRepository>.value(value: discoveryRepo),
      RepositoryProvider<ChatRepository>.value(value: chatRepo),
      RepositoryProvider<CallRepository>.value(value: callRepo),
      RepositoryProvider<CallManagerRepository>.value(value: callManagerRepo),
      RepositoryProvider<FeatureFlagRepository>.value(value: featureFlagRepo),
      RepositoryProvider<BoostRepository>.value(value: boostRepo),
      RepositoryProvider<WeeklyPicksRepository>.value(
        value: WeeklyPicksService.instance,
      ),
      RepositoryProvider<StoryRepository>.value(value: StoryService.instance),
      RepositoryProvider<ProfileValidationRepository>(
        create: (_) => ProfileValidationService(),
      ),
      RepositoryProvider<ProfileMediaRepository>(
        create: (_) => ProfileMediaService(),
      ),
      RepositoryProvider<PassportLocationsRepository>.value(
        value: PassportLocationsService.instance,
      ),
      RepositoryProvider<VoiceRecorderRepository>.value(
        value: VoiceRecorderService(),
      ),
      RepositoryProvider<RealtimeMatchRepository>.value(
        value: RealtimeMatchService.instance,
      ),
      RepositoryProvider<IncognitoRepository>.value(
        value: IncognitoService.instance,
      ),
      RepositoryProvider<CompatibilityQuizRepository>.value(
        value: CompatibilityQuizService.instance,
      ),
      RepositoryProvider<DateIdeaRepository>.value(
        value: DateIdeaService.instance,
      ),
      RepositoryProvider<ProfileInsightsRepository>.value(
        value: ProfileInsightsService.instance,
      ),
      RepositoryProvider<NotificationRepository>(
        create: (_) => FirebaseNotificationRepository(),
      ),
    ];
  }

  static List<BlocProvider> buildBlocs({
    required SharedPreferences preferences,
  }) {
    return [
      BlocProvider<AuthBloc>(
        create: (context) =>
            AuthBloc(authRepository: context.read<AuthRepository>())
              ..add(AuthStarted()),
      ),
      BlocProvider<SessionBloc>(
        create: (context) =>
            SessionBloc(authRepository: context.read<AuthRepository>()),
      ),
      BlocProvider<SubscriptionBloc>(
        create: (context) => SubscriptionBloc(
          subscriptionRepository: context.read<SubscriptionRepository>(),
          authRepository: context.read<AuthRepository>(),
        )..add(SubscriptionWatchStarted()),
      ),
      BlocProvider<ProfileBloc>(
        create: (context) => ProfileBloc(
          profileRepository: context.read<ProfileRepository>(),
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<DiscoveryBloc>(
        create: (context) => DiscoveryBloc(
          discoveryRepository: context.read<DiscoveryRepository>(),
          subscriptionRepository: context.read<SubscriptionRepository>(),
          authRepository: context.read<AuthRepository>(),
          profileRepository: context.read<ProfileRepository>(),
          swipeRightUseCase: SwipeRightUseCase(
            context.read<DiscoveryRepository>(),
            context.read<SubscriptionRepository>(),
          ),
        ),
      ),
      BlocProvider<ChatBloc>(
        create: (context) => ChatBloc(
          chatRepository: context.read<ChatRepository>(),
          subscriptionRepository: context.read<SubscriptionRepository>(),
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<CallBloc>(
        create: (context) =>
            CallBloc(callRepository: context.read<CallRepository>()),
      ),
      BlocProvider<ThemeCubit>(
        create: (context) => ThemeCubit(
          preferences: preferences,
          authRepository: context.read<AuthRepository>(),
          profileRepository: context.read<ProfileRepository>(),
        ),
      ),
      BlocProvider<NotificationSettingsCubit>(
        create: (_) => NotificationSettingsCubit(
          preferences: preferences,
          syncService: NotificationPreferenceSyncService.withPushService(
            preferences: preferences,
            pushService: PushNotificationService.instance,
          ),
        ),
      ),
      BlocProvider<DiscoverySettingsCubit>(
        create: (_) => DiscoverySettingsCubit(preferences: preferences),
      ),
      BlocProvider<SafetyCubit>(
        create: (context) => SafetyCubit(
          preferences: preferences,
          chatRepository: context.read<ChatRepository>(),
          discoveryRepository: context.read<DiscoveryRepository>(),
        ),
      ),
      BlocProvider<LocaleCubit>(
        create: (_) => LocaleCubit(preferences: preferences),
      ),
      BlocProvider<StorageSettingsCubit>(
        create: (_) => StorageSettingsCubit(preferences: preferences),
      ),
      BlocProvider<PrivacySettingsCubit>(
        create: (_) => PrivacySettingsCubit(preferences: preferences),
      ),
      BlocProvider<FeatureFlagCubit>(
        create: (context) =>
            FeatureFlagCubit(repository: context.read<FeatureFlagRepository>()),
      ),
      BlocProvider<BoostCubit>(
        create: (context) => BoostCubit(
          boostRepository: context.read<BoostRepository>(),
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<CompatibilityQuizCubit>(
        create: (context) => CompatibilityQuizCubit(
          authRepository: context.read<AuthRepository>(),
          quizRepository: context.read<CompatibilityQuizRepository>(),
        ),
      ),
      BlocProvider<DateIdeasCubit>(
        create: (context) => DateIdeasCubit(
          authRepository: context.read<AuthRepository>(),
          dateIdeaRepository: context.read<DateIdeaRepository>(),
        ),
      ),
      BlocProvider<ProfileInsightsCubit>(
        create: (context) => ProfileInsightsCubit(
          authRepository: context.read<AuthRepository>(),
          insightsRepository: context.read<ProfileInsightsRepository>(),
        ),
      ),
      BlocProvider<BadgeCounterCubit>(create: (_) => BadgeCounterCubit()),
      BlocProvider<BiometricCubit>(
        create: (_) => BiometricCubit()..checkAvailability(),
      ),
      BlocProvider<ConnectivityCubit>(
        create: (_) => ConnectivityCubit()..startMonitoring(),
      ),
      BlocProvider<NotificationCenterCubit>(
        create: (context) => NotificationCenterCubit(
          repository: context.read<NotificationRepository>(),
        ),
      ),
    ];
  }

  /// Dispose resources when app is closed.
  static void dispose() {
    _apiClient?.dispose();
    _apiClient = null;
    _httpAuthRepository?.dispose();
    _httpAuthRepository = null;
  }
}
