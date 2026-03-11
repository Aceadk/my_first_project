import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/routing/deep_links.dart';

class DeepLinkBootstrap extends StatefulWidget {
  const DeepLinkBootstrap({
    super.key,
    required this.child,
    this.appLinks,
    this.firebaseAuth,
    this.secureStorage,
    this.getInitialLink,
    this.uriLinkStream,
    this.isEmailSignInLink,
    this.secureStorageRead,
    this.onAuthEvent,
    this.onSubscriptionEvent,
    this.onNavigate,
    this.isAuthenticated,
    this.authStatusStream,
    this.isWebOverride,
  });

  final Widget child;
  final AppLinks? appLinks;
  final FirebaseAuth? firebaseAuth;
  final FlutterSecureStorage? secureStorage;
  final Future<Uri?> Function()? getInitialLink;
  final Stream<Uri?>? uriLinkStream;
  final bool Function(String link)? isEmailSignInLink;
  final Future<String?> Function(String key)? secureStorageRead;
  final void Function(AuthEvent event)? onAuthEvent;
  final void Function(SubscriptionEvent event)? onSubscriptionEvent;
  final void Function(String route, {Object? extra})? onNavigate;
  final bool Function()? isAuthenticated;
  final Stream<bool>? authStatusStream;
  final bool? isWebOverride;

  @override
  State<DeepLinkBootstrap> createState() => _DeepLinkBootstrapState();
}

class _DeepLinkBootstrapState extends State<DeepLinkBootstrap> {
  late final AppLinks _appLinks = widget.appLinks ?? AppLinks();
  late final FirebaseAuth _firebaseAuth =
      widget.firebaseAuth ?? FirebaseAuth.instance;
  late final FlutterSecureStorage _secureStorage =
      widget.secureStorage ?? const FlutterSecureStorage();
  late final Future<Uri?> Function() _getInitialLink =
      widget.getInitialLink ?? _appLinks.getInitialLink;
  late final Stream<Uri?> _uriLinkStream =
      widget.uriLinkStream ?? _appLinks.uriLinkStream.map((uri) => uri);
  late final bool Function(String) _isEmailSignInLinkFn =
      widget.isEmailSignInLink ?? _firebaseAuth.isSignInWithEmailLink;
  late final Future<String?> Function(String key) _secureStorageRead =
      widget.secureStorageRead ?? ((key) => _secureStorage.read(key: key));
  late final bool _isWeb = widget.isWebOverride ?? kIsWeb;
  late final DeepLinkHandler _deepLinkHandler = DeepLinkHandler(
    onNavigate: _navigateTo,
    onAuthRequired: _onAuthRequired,
  );
  static const _pendingEmailKey = 'pending_email_link_email';
  bool _didBindAuthStatusStream = false;
  StreamSubscription<Uri?>? _sub;
  StreamSubscription<bool>? _authSub;

  @override
  void initState() {
    super.initState();
    _listenInitial();
    if (!_isWeb) {
      _sub = _uriLinkStream.listen(_handleUri, onError: (_) {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindAuthStatusStream) return;
    _didBindAuthStatusStream = true;
    _authSub = _resolveAuthStatusStream()?.listen((isAuthenticated) {
      if (isAuthenticated) {
        _deepLinkHandler.processPendingLink();
      }
    });
  }

  Future<void> _listenInitial() async {
    try {
      final initial = await _getInitialLink();
      if (!mounted) return;
      _handleUri(initial);
    } catch (e) {
      AppLogger.error('DeepLinkBootstrap: Failed to get initial link: $e');
    }
  }

  void _handleUri(Uri? uri) async {
    if (uri == null || !mounted) return;
    final link = uri.toString();

    // Check if this is an email verification link (magic link from sign up)
    if (_isEmailVerificationLink(uri)) {
      final email = uri.queryParameters['email'];
      if (email != null && mounted) {
        // Use the email link authentication
        _dispatchAuthEvent(AuthEmailLinkSubmitted(email, link));
      } else {
        // Try to get pending email from secure storage
        final pendingEmail = await _secureStorageRead(_pendingEmailKey);
        if (pendingEmail != null && mounted) {
          _dispatchAuthEvent(AuthEmailLinkSubmitted(pendingEmail, link));
        }
      }
      return;
    }

    // Check if this is a Firebase email sign-in link
    if (_isEmailSignInLink(link)) {
      // Get the pending email from secure storage
      final pendingEmail = await _secureStorageRead(_pendingEmailKey);
      if (pendingEmail != null && mounted) {
        _dispatchAuthEvent(AuthEmailLinkSubmitted(pendingEmail, link));
      }
      return;
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final isBillingCallback =
        host.contains('checkout') || path.contains('checkout');
    final status =
        uri.queryParameters['status'] ??
        uri.queryParameters['checkout_status'] ??
        uri.queryParameters['success'];
    if (isBillingCallback || status != null) {
      _dispatchSubscriptionEvent(SubscriptionRestoreRequested());
    }

    _deepLinkHandler.handleDeepLink(
      uri,
      isAuthenticated: _isCurrentlyAuthenticated(),
    );
  }

  /// Check if the link is an email verification magic link.
  bool _isEmailVerificationLink(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.contains('verify-email') || path.contains('verify_email');
  }

  /// Check if the link is a Firebase email sign-in link.
  bool _isEmailSignInLink(String link) {
    return _isEmailSignInLinkFn(link);
  }

  void _dispatchAuthEvent(AuthEvent event) {
    final callback = widget.onAuthEvent;
    if (callback != null) {
      callback(event);
      return;
    }
    context.read<AuthBloc>().add(event);
  }

  void _dispatchSubscriptionEvent(SubscriptionEvent event) {
    final callback = widget.onSubscriptionEvent;
    if (callback != null) {
      callback(event);
      return;
    }
    context.read<SubscriptionBloc>().add(event);
  }

  Stream<bool>? _resolveAuthStatusStream() {
    final override = widget.authStatusStream;
    if (override != null) return override;
    final authBloc = _maybeAuthBloc();
    return authBloc?.stream
        .map((state) => state.status == AuthStatus.authenticated)
        .distinct();
  }

  bool _isCurrentlyAuthenticated() {
    final override = widget.isAuthenticated;
    if (override != null) {
      return override();
    }
    final authBloc = _maybeAuthBloc();
    // In test/preview contexts where AuthBloc is not mounted, default to true
    // so deep-link route behavior remains deterministic.
    if (authBloc == null) return true;
    return authBloc.state.status == AuthStatus.authenticated;
  }

  AuthBloc? _maybeAuthBloc() {
    try {
      return BlocProvider.of<AuthBloc>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _onAuthRequired(DeepLinkResult _) {
    _navigateTo(CrushRoutes.authGateway);
  }

  void _navigateTo(String route, {Object? extra}) {
    final callback = widget.onNavigate;
    if (callback != null) {
      callback(route, extra: extra);
      return;
    }

    final router = GoRouter.maybeOf(context);
    router?.go(route, extra: extra);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
