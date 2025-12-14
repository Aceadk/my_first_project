import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/di.dart';
import 'core/push/push_notifications.dart';
import 'logic/theme/theme_cubit.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_state.dart';
import 'logic/notification/notification_settings_cubit.dart';

class CrushApp extends StatelessWidget {
  const CrushApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: CrushDI.buildRepositories(),
      child: MultiBlocProvider(
        providers: CrushDI.buildBlocs(preferences: preferences),
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return PushBootstrap(
              child: MaterialApp(
                title: 'CrushHour',
                theme: CrushTheme.light(),
                darkTheme: CrushTheme.dark(),
                themeMode: themeMode,
                onGenerateRoute: CrushRoutes.onGenerateRoute,
                initialRoute: CrushRoutes.splash,
                debugShowCheckedModeBanner: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

class PushBootstrap extends StatefulWidget {
  const PushBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends State<PushBootstrap> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<PushNotifications>().initializeHandlers();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.user?.id != current.user?.id,
      listener: (context, state) async {
        final push = context.read<PushNotifications>();
        final settings = context.read<NotificationSettingsCubit>().state;
        if (!settings.push) return;

        if (state.status == AuthStatus.authenticated &&
            state.user?.id != null) {
          try {
            await push.registerDeviceToken(state.user!.id);
          } catch (e) {
            // We intentionally swallow errors here; UI toggles handle messaging.
          }
        } else if (state.status == AuthStatus.unauthenticated &&
            state.user?.id != null) {
          await push.unregisterDeviceToken(state.user!.id);
        }
      },
      child: widget.child,
    );
  }
}
