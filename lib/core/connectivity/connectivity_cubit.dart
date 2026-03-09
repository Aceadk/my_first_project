import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/utils/managed_timer_registry.dart';

/// Connectivity status.
enum ConnectivityStatus {
  /// Online — network is reachable.
  online,

  /// Offline — no network connectivity detected.
  offline,

  /// Unknown — initial state before first check.
  unknown,
}

/// Signature for the DNS lookup function used by [ConnectivityCubit].
typedef DnsLookup = Future<List<InternetAddress>> Function(String host);

/// Cubit that monitors network connectivity and exposes the current status.
///
/// Uses periodic DNS lookups (no additional package dependency) to detect
/// online/offline transitions. Emits [ConnectivityStatus] changes.
///
/// Usage:
/// ```dart
/// BlocProvider<ConnectivityCubit>(
///   create: (_) => ConnectivityCubit()..startMonitoring(),
/// )
/// ```
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit({
    this.checkInterval = const Duration(seconds: 15),
    this.checkHost = 'dns.google',
    DnsLookup? dnsLookup,
  }) : _dnsLookup = dnsLookup ?? InternetAddress.lookup,
       super(ConnectivityStatus.unknown);

  /// How often to poll connectivity.
  final Duration checkInterval;

  /// Host to use for DNS lookup checks.
  final String checkHost;

  final DnsLookup _dnsLookup;

  static const _monitoringTimerKey = 'connectivity_monitoring';
  final ManagedTimerRegistry _timers = ManagedTimerRegistry();
  bool _isChecking = false;

  /// Start periodic connectivity monitoring.
  void startMonitoring() {
    // Run an immediate check, then start periodic polling
    _check();
    _timers.startPeriodic(_monitoringTimerKey, checkInterval, (_) => _check());
  }

  /// Stop monitoring.
  void stopMonitoring() {
    _timers.cancel(_monitoringTimerKey);
  }

  /// Perform a single connectivity check.
  Future<void> checkNow() => _check();

  Future<void> _check() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final result = await _dnsLookup(
        checkHost,
      ).timeout(const Duration(seconds: 5));

      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      final newStatus = isOnline
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;

      if (!isClosed && state != newStatus) {
        AppLogger.debug('ConnectivityCubit: $state -> $newStatus');
        emit(newStatus);
      }
    } on SocketException {
      if (!isClosed && state != ConnectivityStatus.offline) {
        AppLogger.debug(
          'ConnectivityCubit: $state -> offline (SocketException)',
        );
        emit(ConnectivityStatus.offline);
      }
    } on TimeoutException {
      if (!isClosed && state != ConnectivityStatus.offline) {
        AppLogger.debug('ConnectivityCubit: $state -> offline (timeout)');
        emit(ConnectivityStatus.offline);
      }
    } catch (e) {
      // Unexpected error — treat as offline
      if (!isClosed && state != ConnectivityStatus.offline) {
        AppLogger.debug('ConnectivityCubit: $state -> offline ($e)');
        emit(ConnectivityStatus.offline);
      }
    } finally {
      _isChecking = false;
    }
  }

  @override
  Future<void> close() {
    _timers.cancelAll();
    return super.close();
  }
}
