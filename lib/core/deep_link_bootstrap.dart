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
  const DeepLinkBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<DeepLinkBootstrap> createState() => _DeepLinkBootstrapState();
}

class _DeepLinkBootstrapState extends State<DeepLinkBootstrap> {
  final _appLinks = AppLinks();
  final _firebaseAuth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();
  static const _pendingEmailKey = 'pending_email_link_email';
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    _listenInitial();
    if (!kIsWeb) {
      _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
    }
  }

  Future<void> _listenInitial() async {
    try {
      final initial = await _appLinks.getInitialLink();
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
        context.read<AuthBloc>().add(AuthEmailLinkSubmitted(email, link));
      } else {
        // Try to get pending email from secure storage
        final pendingEmail = await _secureStorage.read(key: _pendingEmailKey);
        if (pendingEmail != null && mounted) {
          context
              .read<AuthBloc>()
              .add(AuthEmailLinkSubmitted(pendingEmail, link));
        }
      }
      return;
    }

    // Check if this is a Firebase email sign-in link
    if (_isEmailSignInLink(link)) {
      // Get the pending email from secure storage
      final pendingEmail = await _secureStorage.read(key: _pendingEmailKey);
      if (pendingEmail != null && mounted) {
        context
            .read<AuthBloc>()
            .add(AuthEmailLinkSubmitted(pendingEmail, link));
      }
      return;
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final isBillingCallback =
        host.contains('checkout') || path.contains('checkout');
    final status = uri.queryParameters['status'] ??
        uri.queryParameters['checkout_status'] ??
        uri.queryParameters['success'];
    if (isBillingCallback || status != null) {
      context.read<SubscriptionBloc>().add(SubscriptionRestoreRequested());
    }
  }

  /// Check if the link is an email verification magic link.
  bool _isEmailVerificationLink(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.contains('verify-email') || path.contains('verify_email');
  }

  /// Check if the link is a Firebase email sign-in link.
  bool _isEmailSignInLink(String link) {
    return _firebaseAuth.isSignInWithEmailLink(link);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
