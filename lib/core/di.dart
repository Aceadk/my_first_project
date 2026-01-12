import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/features/calls/data/repositories/call_repository.dart';

// Firebase implementations
import 'package:crushhour/features/auth/data/repositories/impl/firebase_auth_repository.dart';

// Stub implementations (for development/demo without backend)
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/stub_profile_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_discovery_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/stub_subscription_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/stub_call_repository.dart';

// BLoCs
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/session_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/email_auth_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';

/// Backend configuration for the app.
/// Switch between stub (development/demo) and Firebase (production) implementations.
enum BackendMode {
  /// Use stub repositories for development and demo without a real backend.
  /// All data is stored locally using SharedPreferences.
  stub,

  /// Use Firebase repositories for production.
  /// Requires proper Firebase configuration.
  firebase,
}

class CrushDI {
  /// Current backend mode. Change this to switch between implementations.
  /// In production builds, this should be [BackendMode.firebase].
  /// For development/demo, use [BackendMode.stub].
  static const BackendMode backendMode = kDebugMode
      ? BackendMode.stub
      : BackendMode.firebase;

  static List<RepositoryProvider> buildRepositories() {
    // Create repositories based on backend mode
    final AuthRepository authRepo;
    final ProfileRepository profileRepo;
    final SubscriptionRepository subRepo;
    final DiscoveryRepository discoveryRepo;
    final ChatRepository chatRepo;
    final CallRepository callRepo;

    switch (backendMode) {
      case BackendMode.stub:
        // Stub implementations for development/demo
        authRepo = StubAuthRepository();
        profileRepo = StubProfileRepository();
        subRepo = StubSubscriptionRepository();
        discoveryRepo = StubDiscoveryRepository();
        chatRepo = StubChatRepository();
        callRepo = StubCallRepository();
        break;

      case BackendMode.firebase:
        // Firebase implementations for production
        authRepo = FirebaseAuthRepository();
        // Note: Add Firebase implementations for these when available
        profileRepo = StubProfileRepository(); // TODO: Replace with FirebaseProfileRepository
        subRepo = StubSubscriptionRepository(); // TODO: Replace with FirebaseSubscriptionRepository
        discoveryRepo = StubDiscoveryRepository(); // TODO: Replace with FirebaseDiscoveryRepository
        chatRepo = StubChatRepository(); // TODO: Replace with FirebaseChatRepository
        callRepo = StubCallRepository(); // TODO: Replace with FirebaseCallRepository
        break;
    }

    return [
      RepositoryProvider<AuthRepository>.value(value: authRepo),
      RepositoryProvider<ProfileRepository>.value(value: profileRepo),
      RepositoryProvider<SubscriptionRepository>.value(value: subRepo),
      RepositoryProvider<DiscoveryRepository>.value(value: discoveryRepo),
      RepositoryProvider<ChatRepository>.value(value: chatRepo),
      RepositoryProvider<CallRepository>.value(value: callRepo),
    ];
  }

  static List<BlocProvider> buildBlocs({
    required SharedPreferences preferences,
  }) {
    return [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        )..add(AuthStarted()),
      ),
      BlocProvider<SessionBloc>(
        create: (context) => SessionBloc(
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<PhoneAuthBloc>(
        create: (context) => PhoneAuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<EmailAuthBloc>(
        create: (context) => EmailAuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<SubscriptionBloc>(
        create: (context) => SubscriptionBloc(
          subscriptionRepository: context.read<SubscriptionRepository>(),
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
        ),
      ),
      BlocProvider<ChatBloc>(
        create: (context) => ChatBloc(
          chatRepository: context.read<ChatRepository>(),
          subscriptionRepository: context.read<SubscriptionRepository>(),
        ),
      ),
      BlocProvider<CallBloc>(
        create: (context) => CallBloc(
          callRepository: context.read<CallRepository>(),
        ),
      ),
      BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(preferences: preferences),
      ),
      BlocProvider<NotificationSettingsCubit>(
        create: (_) => NotificationSettingsCubit(preferences: preferences),
      ),
      BlocProvider<DiscoverySettingsCubit>(
        create: (_) => DiscoverySettingsCubit(preferences: preferences),
      ),
      BlocProvider<SafetyCubit>(
        create: (context) => SafetyCubit(
          preferences: preferences,
          chatRepository: context.read<ChatRepository>(),
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
    ];
  }
}
