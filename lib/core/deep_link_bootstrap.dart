import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';

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
  static const _pendingEmailKey = 'pending_email_link_email';
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    _listenInitial();
    if (!_isWeb) {
      _sub = _uriLinkStream.listen(_handleUri, onError: (_) {});
    }
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
