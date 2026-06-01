import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crushhour/core/security/device_integrity.dart';
import 'package:crushhour/core/services/push_notification_service.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/core/widgets/error_boundary.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';
import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:crushhour/features/calls/domain/repositories/callkit_repository.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/network_constants.dart';
import 'core/deep_link_bootstrap.dart';
import 'core/di.dart';
import 'core/router.dart';
import 'core/routing/notification_routes.dart';
import 'core/services/app_state_preserver.dart';
import 'core/services/location_service.dart';
import 'core/theme.dart';
import 'design_system/tokens/typography.dart';
import 'design_system/utils/accessibility.dart' show DsTextScaleCap;

class CrushApp extends StatefulWidget {
  const CrushApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<CrushApp> createState() => _CrushAppState();
}

class _CrushAppState extends State<CrushApp> {
  @override
  void initState() {
    super.initState();
    // Initialize AppStatePreserver with FlutterSecureStorage
    AppStatePreserver.instance.initialize(const FlutterSecureStorage());
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: CrushDI.buildRepositories(),
      child: MultiBlocProvider(
        providers: CrushDI.buildBlocs(preferences: widget.preferences),
        child: _RouterHost(preferences: widget.preferences),
      ),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost({required this.preferences});

  final SharedPreferences preferences;

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> with WidgetsBindingObserver {
  late final GoRouter _router;
  StreamSubscription? _matchNotificationSub;
  StreamSubscription<Call>? _missedCallSub;
  StreamSubscription<CallKitEvent>? _callKitSub;
  String? _currentUserId;

  /// Debounce guard: minimum interval between foreground refresh cycles.
  static const _refreshDebounce = Duration(seconds: 30);
  DateTime? _lastResumeRefresh;

  bool get _isIOSRuntime =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authBloc = context.read<AuthBloc>();

    // Initial route is null natively, we handle preserved route async
    final isAuthenticated = authBloc.state.status == AuthStatus.authenticated;

    _router = createRouter(authBloc, initialRoute: null);

    AppStatePreserver.instance.getPreservedRoute().then((preservedRoute) {
      if (isAuthenticated && preservedRoute != null && mounted) {
        _router.go(preservedRoute);
      }
    });

    // Listen for real-time match notifications
    _matchNotificationSub = context
        .read<RealtimeMatchRepository>()
        .onNewMatch
        .listen(_onNewMatchReceived);
    _missedCallSub = context
        .read<CallManagerRepository>()
        .missedCallStream
        .listen(_onMissedCallRecorded);

    // Wire up push notification deep linking
    PushNotificationService.instance.onNotificationTapped =
        _handleNotificationDeepLink;
    PushNotificationService.instance.onNotificationAction =
        _handleNotificationAction;
    PushNotificationService.instance.onForegroundMessage =
        _handleForegroundPushMessage;

    _configureCallKitBridge();

    // Non-blocking device integrity check on cold start
    DeviceIntegrityService.checkIntegrity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _matchNotificationSub?.cancel();
    _missedCallSub?.cancel();
    _callKitSub?.cancel();
    context.read<RealtimeMatchRepository>().stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - save current route
      final currentPath = _router.routerDelegate.currentConfiguration.uri.path;
      AppStatePreserver.instance.saveCurrentRoute(currentPath);
    } else if (state == AppLifecycleState.resumed) {
      // App coming back to foreground - clear the preserved route
      // (we've already restored, no need to keep it)
      AppStatePreserver.instance.clearPreservedRoute();

      // Trigger biometric re-authentication if enabled
      if (mounted && _currentUserId != null) {
        context.read<BiometricCubit>().checkAvailability();
      }

      // Refresh stale BLoC state (debounced to avoid rapid cycles)
      _refreshOnResume();

      // Update user location for better discovery
      _updateUserLocationOnResume();
    }
  }

  /// Refresh key BLoC states when app returns to foreground.
  /// Debounced to avoid hammering backend on rapid background/foreground cycles.
  void _refreshOnResume() {
    if (_currentUserId == null || !mounted) return;

    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < _refreshDebounce) {
      return;
    }
    _lastResumeRefresh = now;

    // Refresh subscription (may have changed via web or external purchase)
    context.read<SubscriptionBloc>().add(SubscriptionRestoreRequested());

    // Refresh profile (server-side changes, verification status)
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  /// Update user's location when app comes to foreground.
  /// This ensures discovery always uses the current location.
  Future<void> _updateUserLocationOnResume() async {
    // Only update if user is authenticated
    if (_currentUserId == null) return;

    try {
      final locationService = LocationService.instance;

      // Check if we have location permission
      final hasPermission = await locationService.isLocationAvailable();
      if (!hasPermission) {
        developer.log('App: Location not available, skipping update');
        return;
      }

      // Get current location (non-blocking, with short timeout)
      final location = await locationService.getCurrentLocation(
        includeGeocoding: true,
        timeout: NetworkConstants.locationTimeout,
      );

      if (location == null) {
        developer.log('App: Could not get location');
        return;
      }

      developer.log(
        'App: Updating location to ${location.latitude}, ${location.longitude}',
      );

      // Update profile with new location
      if (mounted) {
        context.read<ProfileBloc>().add(
          ProfileLocationUpdateRequested(
            latitude: location.latitude,
            longitude: location.longitude,
            city: location.city,
            country: location.country,
          ),
        );
      }
    } catch (e) {
      developer.log('App: Error updating location on resume: $e');
    }
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

  void _onMissedCallRecorded(Call call) {
    if (!mounted || _currentUserId == null) return;
    if (call.receiverId != _currentUserId) return;
    unawaited(_showMissedCallNotification(call));
  }

  Future<void> _showMissedCallNotification(Call call) async {
    final callerName = (call.callerName == null || call.callerName!.isEmpty)
        ? 'someone'
        : call.callerName!;
    final callType = call.type == CallType.video ? 'video' : 'audio';
    final id = call.id.hashCode;
    final payload = jsonEncode({
      'type': 'missed_call',
      'targetRoute': CrushRoutes.callHistory,
      'targetId': call.id,
      'callerId': call.callerId,
      'receiverId': call.receiverId,
      'callType': call.type.name,
      'status': call.status.name,
    });

    try {
      await PushNotificationService.instance.showNotification(
        id: id,
        title: 'Missed $callType call',
        body: 'You missed a call from $callerName',
        payload: payload,
      );
    } catch (e) {
      developer.log('Failed to show missed call notification: $e');
    }
  }

  void _configureCallKitBridge() {
    if (!_isIOSRuntime) return;
    _callKitSub = context.read<CallKitRepository>().events.listen(
      _handleCallKitEvent,
    );
  }

  void _handleForegroundPushMessage(RemoteMessage message) {
    if (!_isIOSRuntime) return;
    final data = Map<String, dynamic>.from(message.data);
    final type = (data['type'] as String?)?.toLowerCase();
    if (type != 'incoming_call' && type != 'call') return;
    unawaited(_presentCallKitIncoming(data));
  }

  Future<void> _presentCallKitIncoming(Map<String, dynamic> data) async {
    final incomingCall = _buildIncomingCallFromPayload(data);
    if (incomingCall == null) return;

    await context.read<CallKitRepository>().showIncomingCall(
      callId: incomingCall.id,
      callerId: incomingCall.callerId,
      callerName: incomingCall.callerName,
      callerPhotoUrl: incomingCall.callerPhotoUrl,
      receiverId: incomingCall.receiverId,
      isVideoCall: incomingCall.type == CallType.video,
    );
  }

  Future<void> _handleCallKitEvent(CallKitEvent event) async {
    final eventType = event.type;
    if (eventType == CallKitEventType.incomingReported ||
        eventType == CallKitEventType.incomingReportFailed ||
        eventType == CallKitEventType.audioActivated ||
        eventType == CallKitEventType.audioDeactivated ||
        eventType == CallKitEventType.unknown) {
      return;
    }

    final payload = <String, dynamic>{
      ...event.payload,
      if (event.callId != null) 'callId': event.callId,
    };
    final incomingCall = _buildIncomingCallFromPayload(payload);

    switch (eventType) {
      case CallKitEventType.answered:
        if (incomingCall == null) return;
        _ensureActiveIncomingCall(incomingCall);
        await context.read<CallManagerRepository>().acceptCall(
          asType: incomingCall.type,
        );
        if (!mounted) return;
        _router.go(
          CrushRoutes.call,
          extra: CallScreenArgs(
            matchId: incomingCall.callerId,
            isVideoCall: incomingCall.type == CallType.video,
            matchName: incomingCall.callerName,
            matchPhotoUrl: incomingCall.callerPhotoUrl,
            isIncoming: true,
          ),
        );
        return;
      case CallKitEventType.declined:
        if (incomingCall != null) {
          _ensureActiveIncomingCall(incomingCall);
        }
        await context.read<CallManagerRepository>().declineCall();
        return;
      case CallKitEventType.ended:
        await context.read<CallManagerRepository>().endCall();
        return;
      case CallKitEventType.mutedChanged:
        final desiredMuted = event.isMuted;
        if (desiredMuted == null ||
            !context.read<CallManagerRepository>().hasActiveCall) {
          return;
        }
        if (context.read<CallManagerRepository>().isMuted != desiredMuted) {
          context.read<CallManagerRepository>().toggleMute();
        }
        return;
      case CallKitEventType.incomingReported ||
          CallKitEventType.incomingReportFailed ||
          CallKitEventType.audioActivated ||
          CallKitEventType.audioDeactivated ||
          CallKitEventType.unknown:
        return;
    }
  }

  void _ensureActiveIncomingCall(Call incomingCall) {
    final active = context.read<CallManagerRepository>().activeCall;
    if (active == null || active.id != incomingCall.id) {
      context.read<CallManagerRepository>().handleIncomingCall(incomingCall);
    }
  }

  Call? _buildIncomingCallFromPayload(Map<String, dynamic> payload) {
    final callerId =
        payload['callerId'] as String? ?? payload['caller_id'] as String?;
    final receiverId =
        _currentUserId ??
        payload['receiverId'] as String? ??
        payload['receiver_id'] as String?;
    if (callerId == null || receiverId == null) return null;

    final isVideoRaw = payload['isVideoCall'] ?? payload['is_video_call'];
    final callTypeRaw = payload['callType'] as String?;
    final isVideo =
        isVideoRaw == true || isVideoRaw == 'true' || callTypeRaw == 'video';
    final callId =
        payload['callId'] as String? ??
        payload['call_id'] as String? ??
        'incoming_${DateTime.now().millisecondsSinceEpoch}';

    return Call(
      id: callId,
      callerId: callerId,
      receiverId: receiverId,
      type: isVideo ? CallType.video : CallType.audio,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      callerName: payload['callerName'] as String?,
      callerPhotoUrl: payload['callerPhotoUrl'] as String?,
    );
  }

  /// Handle notification tap → navigate to the correct screen.
  /// Works on both iPhone (push) and iPad (detail panel via go).
  void _handleNotificationDeepLink(String? payload) {
    if (!mounted || payload == null || payload.isEmpty) return;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      final type = data['type'] as String?;

      // Incoming call notification payload.
      if (type == 'incoming_call' || type == 'call') {
        final incomingCall = _buildIncomingCallFromPayload(data);
        if (incomingCall != null) {
          context.read<CallManagerRepository>().handleIncomingCall(
            incomingCall,
          );
          _router.go(
            CrushRoutes.incomingCall,
            extra: IncomingCallScreenArgs(incomingCall: incomingCall),
          );
          return;
        }
      }

      final resolution = NotificationRouteResolver.resolve(data);
      final route = resolution.route == CrushRoutes.incomingCall
          ? CrushRoutes.notificationCenter
          : resolution.route;

      // Navigate — go() replaces the current location which works correctly
      // for both iPhone (full-screen push) and iPad (detail panel update).
      _router.go(route);
    } catch (_) {
      // Malformed payload — fall back to the notification center.
      _router.go(CrushRoutes.notificationCenter);
    }
  }

  /// Handle notification action buttons (Reply, Like Back).
  void _handleNotificationAction(String actionId, String? payload) {
    if (!mounted) return;

    Map<String, dynamic> data = {};
    if (payload != null && payload.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      } catch (_) {}
    }

    switch (actionId) {
      case PushNotificationService.actionReply:
        final route = NotificationRouteResolver.resolve({
          ...data,
          'type': 'message',
        }).route;
        _router.go(route);
      case PushNotificationService.actionLikeBack:
        _router.go(CrushRoutes.likesYou);
    }
  }

  void _handleAuthStateChange(AuthState state) {
    final userId = state.user?.id;

    if (userId != null && userId != _currentUserId) {
      // User logged in - start listening for matches
      _currentUserId = userId;
      context.read<RealtimeMatchRepository>().startListening(userId);
    } else if (userId == null && _currentUserId != null) {
      // User logged out - stop listening
      _currentUserId = null;
      context.read<RealtimeMatchRepository>().stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthStateChange(state),
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, themeMode) {
          final materialMode = switch (themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.darkLuxury => ThemeMode.dark,
            AppThemeMode.darkLuxuryModern => ThemeMode.dark,
          };
          final darkTheme = switch (themeMode) {
            AppThemeMode.darkLuxury => CrushTheme.darkLuxuryClassic(),
            AppThemeMode.darkLuxuryModern => CrushTheme.darkLuxuryModern(),
            _ => CrushTheme.dark(),
          };
          final themeAnimationDuration = Duration(
            milliseconds: (240 * (themeMode.isLuxury ? 1.2 : 1.0)).round(),
          );
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              final langCode = localeState.languageCode;
              final lightTheme = CrushTheme.light().copyWith(
                textTheme: DsTypography.cjkAdjusted(
                  CrushTheme.light().textTheme,
                  langCode,
                ),
              );
              final cjkDarkTheme = darkTheme.copyWith(
                textTheme: DsTypography.cjkAdjusted(
                  darkTheme.textTheme,
                  langCode,
                ),
              );
              return ErrorBoundary(
                screenName: 'App',
                showHomeButton: false,
                child: DeepLinkBootstrap(
                  onNavigate: (route, {extra}) {
                    _router.go(route, extra: extra);
                  },
                  child: MaterialApp.router(
                    title: 'Crush',
                    theme: lightTheme,
                    darkTheme: cjkDarkTheme,
                    themeMode: materialMode,
                    themeAnimationDuration: themeAnimationDuration,
                    themeAnimationCurve: Curves.easeInOutCubic,
                    routerConfig: _router,
                    builder: (context, child) {
                      // Bound dynamic-type scaling so very large system text
                      // sizes cannot break the card-based layouts (A11Y-002).
                      return DsTextScaleCap(
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
