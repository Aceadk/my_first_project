import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/dev/widget_catalog/widget_catalog_screen.dart';
import 'router_refresh_stream.dart';
import 'performance/performance_observer.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/core/widgets/not_found_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/presentation/screens/home_screen.dart';
import 'package:crushhour/presentation/screens/test/test_video_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/message_requests_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/call_history_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_view_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/discovery/presentation/screens/likes_you_screen.dart';
import 'package:crushhour/features/discovery/presentation/screens/weekly_picks_screen.dart';
import 'package:crushhour/features/discovery/presentation/screens/story_viewer_screen.dart';
import 'package:crushhour/features/social/presentation/screens/date_ideas_screen.dart';
import 'package:crushhour/features/social/presentation/screens/compatibility_quiz_screen.dart';
import 'package:crushhour/features/analytics/presentation/screens/profile_insights_screen.dart';
import 'package:crushhour/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/match.dart';

// Modular route files
export 'routing/crush_routes.dart';
export 'routing/route_redirect.dart';
import 'routing/crush_routes.dart';
import 'routing/route_redirect.dart';
import 'routing/auth_routes.dart';
import 'routing/settings_routes.dart';
import 'routing/public_routes.dart';
import 'routing/page_builder.dart';

GoRouter createRouter(AuthBloc authBloc, {String? initialRoute}) {
  // Use preserved route if provided (app resuming from background with authenticated user),
  // otherwise start at splash screen for fresh launch
  final startLocation = initialRoute ?? CrushRoutes.splash;

  return GoRouter(
    initialLocation: startLocation,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    observers: [
      PerformanceNavigatorObserver(
        nameExtractor: (route) => route?.settings.name ?? 'unknown',
      ),
    ],
    redirect: (context, state) =>
        resolveRouteRedirect(authState: authBloc.state, path: state.uri.path),
    errorPageBuilder: (context, state) {
      return buildPage(state, const NotFoundScreen());
    },
    routes: [
      // Auth, onboarding & verification routes
      ...authRoutes(),

      // Main app routes (home, chat, profile, discovery)
      ..._mainAppRoutes(authBloc),

      // Settings routes
      ...settingsRoutes(),

      // Legal / public routes
      ...publicRoutes(),

      // Widget catalog - debug builds only
      if (kDebugMode)
        GoRoute(
          path: CrushRoutes.widgetCatalog,
          pageBuilder: (context, state) =>
              buildPage(state, const WidgetCatalogScreen()),
        ),
    ],
  );
}

/// Core app routes that need the [authBloc] for deep-link loading and
/// user-specific parameters.
List<RouteBase> _mainAppRoutes(AuthBloc authBloc) => [
  GoRoute(
    path: CrushRoutes.home,
    pageBuilder: (context, state) => buildPage(state, const HomeScreen()),
  ),
  GoRoute(
    path: '${CrushRoutes.chat}/:matchId',
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is ChatScreenArgs) {
        return buildPage(state, ChatScreen(args: args));
      }
      final matchId = state.pathParameters['matchId'] ?? '';
      final currentUserId = authBloc.state.user?.id ?? '';
      if (matchId.isEmpty || currentUserId.isEmpty) {
        return buildPage(state, const HomeScreen());
      }
      return buildPage(
        state,
        _ChatDeepLinkLoader(matchId: matchId, currentUserId: currentUserId),
      );
    },
  ),
  GoRoute(
    path: CrushRoutes.messageRequests,
    pageBuilder: (context, state) =>
        buildPage(state, const MessageRequestsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.call,
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is CallScreenArgs) {
        return buildPage(
          state,
          CallScreen(
            matchId: args.matchId,
            isVideoCall: args.isVideoCall,
            matchName: args.matchName,
            matchPhotoUrl: args.matchPhotoUrl,
            isIncoming: args.isIncoming,
          ),
        );
      }
      return buildPage(state, const HomeScreen());
    },
  ),
  GoRoute(
    path: CrushRoutes.callHistory,
    pageBuilder: (context, state) =>
        buildPage(state, const CallHistoryScreen()),
  ),
  GoRoute(
    path: CrushRoutes.incomingCall,
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is IncomingCallScreenArgs) {
        return buildPage(
          state,
          IncomingCallScreen(incomingCall: args.incomingCall),
        );
      }
      return buildPage(state, const HomeScreen());
    },
  ),
  GoRoute(
    path: CrushRoutes.videoCall,
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is VideoCallArgs) {
        return buildPage(
          state,
          VideoCallScreen(
            currentUserId: args.currentUserId,
            otherUserId: args.otherUserId,
            otherName: args.otherName,
          ),
        );
      }
      return buildPage(state, const HomeScreen());
    },
  ),
  GoRoute(
    path: CrushRoutes.notificationCenter,
    pageBuilder: (context, state) =>
        buildPage(state, const NotificationCenterScreen()),
  ),
  GoRoute(
    path: CrushRoutes.likesYou,
    pageBuilder: (context, state) => buildPage(state, const LikesYouScreen()),
  ),
  GoRoute(
    path: CrushRoutes.weeklyPicks,
    pageBuilder: (context, state) {
      final userId = authBloc.state.user?.id ?? '';
      return buildPage(state, WeeklyPicksScreen(userId: userId));
    },
  ),
  GoRoute(
    path: CrushRoutes.dateIdeas,
    pageBuilder: (context, state) => buildPage(state, const DateIdeasScreen()),
  ),
  GoRoute(
    path: CrushRoutes.compatibilityQuiz,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, String>?;
      final matchId = args?['matchId'] ?? '';
      final userId = authBloc.state.user?.id ?? '';
      return buildPage(
        state,
        CompatibilityQuizScreen(matchId: matchId, userId: userId),
      );
    },
  ),
  GoRoute(
    path: CrushRoutes.profileInsights,
    pageBuilder: (context, state) {
      final userId = authBloc.state.user?.id ?? '';
      return buildPage(state, ProfileInsightsScreen(userId: userId));
    },
  ),
  // Agora test harness — debug builds only, never registered in release.
  if (kDebugMode)
    GoRoute(
      path: CrushRoutes.testAgora,
      pageBuilder: (context, state) =>
          buildPage(state, const TestVideoScreen()),
    ),
  GoRoute(
    path: CrushRoutes.profile,
    pageBuilder: (context, state) =>
        buildPage(state, const ProfileViewScreen()),
  ),
  GoRoute(
    path: CrushRoutes.profileEdit,
    pageBuilder: (context, state) =>
        buildPage(state, const ProfileEditScreen()),
  ),
  GoRoute(
    path: CrushRoutes.profileMedia,
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is ProfileMediaArgs) {
        return buildPage(state, ProfileMediaScreen(profile: args.profile));
      }
      return buildPage(state, const HomeScreen());
    },
  ),
  GoRoute(
    path: CrushRoutes.userProfile,
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is OtherUserProfileArgs) {
        return buildPage(state, OtherUserProfileScreen(args: args));
      }
      return buildPage(state, const HomeScreen());
    },
  ),
  GoRoute(
    path: '${CrushRoutes.userProfile}/:userId',
    pageBuilder: (context, state) {
      final userId =
          state.pathParameters['userId'] ??
          state.uri.queryParameters['userId'] ??
          '';
      if (userId.isEmpty) {
        return buildPage(state, const HomeScreen());
      }
      final currentUserId = authBloc.state.user?.id;
      if (currentUserId != null && currentUserId == userId) {
        return buildPage(state, const ProfileViewScreen());
      }
      return buildPage(state, _UserProfileDeepLinkLoader(userId: userId));
    },
  ),
  GoRoute(
    path: CrushRoutes.storyViewer,
    pageBuilder: (context, state) {
      final args = state.extra;
      if (args is StoryViewerArgs && args.stories.isNotEmpty) {
        return buildPage(
          state,
          StoryViewerScreen(
            stories: args.stories,
            profile: args.profile,
            initialIndex: args.initialIndex,
          ),
        );
      }
      return buildPage(state, const HomeScreen());
    },
  ),
];

// ---------------------------------------------------------------------------
// Deep-link loader widgets
// ---------------------------------------------------------------------------

class _ChatDeepLinkLoader extends StatefulWidget {
  const _ChatDeepLinkLoader({
    required this.matchId,
    required this.currentUserId,
  });

  final String matchId;
  final String currentUserId;

  @override
  State<_ChatDeepLinkLoader> createState() => _ChatDeepLinkLoaderState();
}

class _ChatDeepLinkLoaderState extends State<_ChatDeepLinkLoader> {
  static const _deepLinkLoadTimeout = Duration(seconds: 12);
  late final Future<List<CrushMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = context
        .read<DiscoveryRepository>()
        .fetchMatches(widget.currentUserId)
        .timeout(_deepLinkLoadTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CrushMatch>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _DeepLinkLoadingScaffold(
            message: AppLocalizations.of(context).openingChat,
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _DeepLinkErrorScaffold(
            message: AppLocalizations.of(context).chatLoadFailed,
          );
        }
        CrushMatch? match;
        try {
          match = snapshot.data!.firstWhere((m) => m.id == widget.matchId);
        } catch (_) {
          match = null;
        }
        if (match == null) {
          return _DeepLinkErrorScaffold(
            message: AppLocalizations.of(context).chatNotFound,
          );
        }
        final args = ChatScreenArgs(
          matchId: match.id,
          currentUserId: widget.currentUserId,
          otherUserId: match.otherUserId,
          otherName: match.otherUserName ?? 'Someone',
          otherPhotoUrl: match.otherUserPhotoUrl,
        );
        return ChatScreen(args: args);
      },
    );
  }
}

class _UserProfileDeepLinkLoader extends StatefulWidget {
  const _UserProfileDeepLinkLoader({required this.userId});

  final String userId;

  @override
  State<_UserProfileDeepLinkLoader> createState() =>
      _UserProfileDeepLinkLoaderState();
}

class _UserProfileDeepLinkLoaderState
    extends State<_UserProfileDeepLinkLoader> {
  static const _deepLinkLoadTimeout = Duration(seconds: 12);
  late final Future<Profile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context
        .read<DiscoveryRepository>()
        .fetchProfileById(widget.userId)
        .timeout(_deepLinkLoadTimeout, onTimeout: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _DeepLinkLoadingScaffold(
            message: AppLocalizations.of(context).loadingProfile,
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _DeepLinkErrorScaffold(
            message: AppLocalizations.of(context).profileNotFound,
          );
        }
        return OtherUserProfileScreen(
          args: OtherUserProfileArgs(profile: snapshot.data!),
        );
      },
    );
  }
}

class _DeepLinkLoadingScaffold extends StatelessWidget {
  const _DeepLinkLoadingScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _DeepLinkErrorScaffold extends StatelessWidget {
  const _DeepLinkErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(CrushRoutes.home),
                child: Text(AppLocalizations.of(context).goToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
