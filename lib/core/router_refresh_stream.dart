import 'dart:async';
import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      if (_isDisposed) return;
      notifyListeners();
    });
  }

  StreamSubscription<dynamic>? _subscription;
  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
