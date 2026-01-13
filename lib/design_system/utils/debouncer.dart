import 'dart:async';

/// Debouncer utility for delaying rapid function calls.
///
/// Useful for search inputs to avoid excessive API calls while typing.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Run a callback after the delay, canceling any pending callbacks.
  void run(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel any pending callback.
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Throttler utility for rate-limiting function calls.
///
/// Ensures a function is called at most once per duration.
class Throttler {
  final Duration duration;
  DateTime? _lastCall;
  Timer? _timer;

  Throttler({this.duration = const Duration(milliseconds: 300)});

  /// Run a callback if enough time has passed since the last call.
  void run(void Function() callback) {
    final now = DateTime.now();

    if (_lastCall == null ||
        now.difference(_lastCall!) >= duration) {
      _lastCall = now;
      callback();
    } else {
      // Schedule for the remaining time
      _timer?.cancel();
      final remaining = duration - now.difference(_lastCall!);
      _timer = Timer(remaining, () {
        _lastCall = DateTime.now();
        callback();
      });
    }
  }

  /// Cancel any pending callback.
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the throttler.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Search debouncer with built-in empty query handling.
class SearchDebouncer {
  final Duration delay;
  final void Function(String query)? onSearch;
  final void Function()? onEmpty;

  Timer? _timer;
  String _lastQuery = '';

  SearchDebouncer({
    this.delay = const Duration(milliseconds: 400),
    this.onSearch,
    this.onEmpty,
  });

  /// Handle search input changes.
  void search(String query) {
    _timer?.cancel();

    final trimmedQuery = query.trim();

    // Immediately clear if empty
    if (trimmedQuery.isEmpty) {
      if (_lastQuery.isNotEmpty) {
        _lastQuery = '';
        onEmpty?.call();
      }
      return;
    }

    // Debounce non-empty queries
    _timer = Timer(delay, () {
      if (trimmedQuery != _lastQuery) {
        _lastQuery = trimmedQuery;
        onSearch?.call(trimmedQuery);
      }
    });
  }

  /// Force execute search immediately.
  void searchNow(String query) {
    _timer?.cancel();
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _lastQuery = '';
      onEmpty?.call();
    } else {
      _lastQuery = trimmedQuery;
      onSearch?.call(trimmedQuery);
    }
  }

  /// Cancel pending search.
  void cancel() {
    _timer?.cancel();
  }

  /// Reset the debouncer state.
  void reset() {
    _timer?.cancel();
    _lastQuery = '';
  }

  /// Dispose the debouncer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
