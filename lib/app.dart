import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/di.dart';
import 'core/deep_link_bootstrap.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class CrushApp extends StatelessWidget {
  const CrushApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: CrushDI.buildRepositories(),
      child: MultiBlocProvider(
        providers: CrushDI.buildBlocs(preferences: preferences),
        child: const _RouterHost(),
      ),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost();

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  late final GoRouter _router;
  StreamSubscription? _matchNotificationSub;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _router = createRouter(authBloc);

    // Listen for real-time match notifications
    _matchNotificationSub = RealtimeMatchService.instance.onNewMatch.listen(
      _onNewMatchReceived,
    );
  }

  @override
  void dispose() {
    _matchNotificationSub?.cancel();
    RealtimeMatchService.instance.stopListening();
    super.dispose();
  }

  void _onNewMatchReceived(RealtimeMatchNotification notification) {
    // Show a snackbar when a match comes in from RTDB
    // This handles matches that happen while the user is elsewhere in the app
    if (!mounted) return;

    final currentPath = _router.routerDelegate.currentConfiguration.uri.path;
    // Don't show notification if already on chat or deck (deck shows its own celebration)
    if (currentPath.startsWith('/chat') || currentPath == '/deck') return;

    final navContext = _router.routerDelegate.navigatorKey.currentContext;
    if (navContext == null) return;

    ScaffoldMessenger.of(navContext).showSnackBar(
      SnackBar(
        content: Text('You matched with ${notification.otherUserName}! 🎉'),
        action: SnackBarAction(
          label: 'Chat',
          onPressed: () {
            _router.push('/chat/${notification.matchId}');
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleAuthStateChange(AuthState state) {
    final userId = state.user?.id;

    if (userId != null && userId != _currentUserId) {
      // User logged in - start listening for matches
      _currentUserId = userId;
      RealtimeMatchService.instance.startListening(userId);
    } else if (userId == null && _currentUserId != null) {
      // User logged out - stop listening
      _currentUserId = null;
      RealtimeMatchService.instance.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthStateChange(state),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return DeepLinkBootstrap(
                child: MaterialApp.router(
                  title: 'Crush',
                  theme: CrushTheme.light(),
                  darkTheme: CrushTheme.dark(),
                  themeMode: themeMode,
                  routerConfig: _router,
                  debugShowCheckedModeBanner: false,
                  // Localization
                  locale: Locale(localeState.languageCode),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
