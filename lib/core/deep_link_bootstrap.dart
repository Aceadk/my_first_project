import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';
import '../logic/auth/auth_bloc.dart';
import '../logic/auth/auth_event.dart';
import '../logic/subscription/subscription_bloc.dart';
import '../logic/subscription/subscription_event.dart';

class DeepLinkBootstrap extends StatefulWidget {
  const DeepLinkBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<DeepLinkBootstrap> createState() => _DeepLinkBootstrapState();
}

class _DeepLinkBootstrapState extends State<DeepLinkBootstrap> {
  final _appLinks = AppLinks();
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
    } catch (_) {}
  }

  void _handleUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final link = uri.toString();

    // TODO: Implement email link sign-in detection with your backend
    // Check if this is an email sign-in link from your auth system
    if (_isEmailSignInLink(link)) {
      context.read<AuthBloc>().add(AuthEmailLinkSubmitted('', link));
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

  /// Check if the link is an email sign-in link.
  /// TODO: Implement this based on your auth backend's email link format.
  bool _isEmailSignInLink(String link) {
    // Example: Check for specific patterns in your email sign-in links
    // return link.contains('your-domain.com/auth/email-signin');
    return false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
