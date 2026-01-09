import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/discovery_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/call_repository.dart';

// Stub implementations (replace with your actual backend implementations)
import '../data/repositories/stub/stub_auth_repository.dart';
import '../data/repositories/stub/stub_profile_repository.dart';
import '../data/repositories/stub/stub_discovery_repository.dart';
import '../data/repositories/stub/stub_chat_repository.dart';
import '../data/repositories/stub/stub_subscription_repository.dart';
import '../data/repositories/stub/stub_call_repository.dart';

// BLoCs
import '../logic/auth/auth_bloc.dart';
import '../logic/auth/auth_event.dart';
import '../logic/auth/session_bloc.dart';
import '../logic/auth/phone_auth_bloc.dart';
import '../logic/auth/email_auth_bloc.dart';
import '../logic/profile/profile_bloc.dart';
import '../logic/discovery/discovery_bloc.dart';
import '../logic/chat/chat_bloc.dart';
import '../logic/subscription/subscription_bloc.dart';
import '../logic/subscription/subscription_event.dart';
import '../logic/call/call_bloc.dart';
import '../logic/theme/theme_cubit.dart';
import '../logic/notification/notification_settings_cubit.dart';
import '../logic/discovery/discovery_settings_cubit.dart';
import '../logic/safety/safety_cubit.dart';
import '../logic/locale/locale_cubit.dart';
import '../logic/storage/storage_settings_cubit.dart';
import '../logic/privacy/privacy_settings_cubit.dart';

class CrushDI {
  static List<RepositoryProvider> buildRepositories() {
    // Create stub repositories
    // TODO: Replace these with your actual backend implementations
    final authRepo = StubAuthRepository();
    final profileRepo = StubProfileRepository();
    final subRepo = StubSubscriptionRepository();
    final discoveryRepo = StubDiscoveryRepository();
    final chatRepo = StubChatRepository();
    final callRepo = StubCallRepository();

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
