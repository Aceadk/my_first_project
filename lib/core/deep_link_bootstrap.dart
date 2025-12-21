import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:uni_links/uni_links.dart';
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
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    _listenInitial();
    _sub = uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  Future<void> _listenInitial() async {
    try {
      final initial = await getInitialUri();
      if (!mounted) return;
      _handleUri(initial);
    } catch (_) {}
  }

  void _handleUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final link = uri.toString();
    if (fb.FirebaseAuth.instance.isSignInWithEmailLink(link)) {
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
