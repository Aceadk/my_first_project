import 'dart:async';

/// Centralized keyed timer lifecycle manager.
///
/// Use stable keys to restart, cancel, and bulk-cancel timers predictably.
class ManagedTimerRegistry {
  final Map<String, Timer> _timers = <String, Timer>{};

  /// Whether a timer with [key] is currently tracked.
  bool contains(String key) => _timers.containsKey(key);

  /// Snapshot of active timer keys.
  Iterable<String> get keys => _timers.keys;

  /// Start or restart a periodic timer under [key].
  Timer startPeriodic(
    String key,
    Duration interval,
    void Function(Timer timer) onTick,
  ) {
    cancel(key);
    final timer = Timer.periodic(interval, onTick);
    _timers[key] = timer;
    return timer;
  }

  /// Start or restart a one-shot timer under [key].
  ///
  /// The key is removed automatically after firing.
  Timer startOneShot(String key, Duration delay, void Function() onFire) {
    cancel(key);

    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(key);
      onFire();
    });
    _timers[key] = timer;
    return timer;
  }

  /// Cancel and remove timer [key] if it exists.
  void cancel(String key) {
    final timer = _timers.remove(key);
    timer?.cancel();
  }

  /// Cancel all timers whose keys match [predicate].
  void cancelWhere(bool Function(String key) predicate) {
    final matchingKeys = _timers.keys.where(predicate).toList(growable: false);
    for (final key in matchingKeys) {
      cancel(key);
    }
  }

  /// Cancel and clear all tracked timers.
  void cancelAll() {
    final allKeys = _timers.keys.toList(growable: false);
    for (final key in allKeys) {
      cancel(key);
    }
  }

  bool get isEmpty => _timers.isEmpty;
}
