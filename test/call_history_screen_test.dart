import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/presentation/screens/call_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Call buildCall({
    required String id,
    required DateTime createdAt,
    CallStatus status = CallStatus.ended,
    CallType type = CallType.audio,
    CallEndReason? endReason,
    int? duration,
  }) {
    return Call(
      id: id,
      callerId: 'u1',
      receiverId: 'u2',
      type: type,
      status: status,
      createdAt: createdAt,
      endedAt: createdAt.add(const Duration(minutes: 3)),
      endReason: endReason,
      duration: duration,
      receiverName: 'Alex',
    );
  }

  Widget wrap(Widget child, {Size size = const Size(390, 640)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('renders grouped sections and highlights missed calls', (
    tester,
  ) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Anchored to startOfToday (not `now - 1h`) so the fixture stays inside
    // "Today" even when the test runs shortly after midnight.
    final todayCall = startOfToday.add(const Duration(minutes: 30));
    final yesterdayCall = startOfToday.subtract(const Duration(hours: 12));
    final thisWeekCall = startOfToday.subtract(const Duration(days: 3, hours: 12));
    final earlierCall = startOfToday.subtract(
      const Duration(days: 14, hours: 12),
    );
    final calls = <Call>[
      buildCall(
        id: 'today',
        createdAt: todayCall,
        type: CallType.video,
        duration: 120,
      ),
      buildCall(
        id: 'yesterday',
        createdAt: yesterdayCall,
      ),
      buildCall(
        id: 'week',
        createdAt: thisWeekCall,
        status: CallStatus.missed,
        endReason: CallEndReason.missed,
      ),
      buildCall(
        id: 'earlier',
        createdAt: earlierCall,
      ),
    ];

    Future<List<Call>> loader(
      String userId, {
      int limit = 20,
      DateTime? before,
    }) async {
      final filtered = calls.where((call) {
        if (before == null) return true;
        return call.createdAt.isBefore(before);
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered.take(limit).toList();
    }

    await tester.pumpWidget(
      wrap(CallHistoryScreen(userIdOverride: 'u1', callHistoryLoader: loader)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.byKey(const Key('call_history_status_week')), findsOneWidget);
    expect(find.textContaining('Missed call'), findsOneWidget);
  });

  testWidgets('loads next page on scroll and supports pull-to-refresh', (
    tester,
  ) async {
    final now = DateTime.now();
    var loadCount = 0;
    var source = <Call>[
      buildCall(id: 'c1', createdAt: now.subtract(const Duration(minutes: 1))),
      buildCall(id: 'c2', createdAt: now.subtract(const Duration(minutes: 2))),
      buildCall(id: 'c3', createdAt: now.subtract(const Duration(minutes: 3))),
      buildCall(id: 'c4', createdAt: now.subtract(const Duration(minutes: 4))),
    ];

    Future<List<Call>> loader(
      String userId, {
      int limit = 20,
      DateTime? before,
    }) async {
      loadCount++;
      final sorted = [...source]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final filtered = sorted.where((call) {
        if (before == null) return true;
        return call.createdAt.isBefore(before);
      }).toList();
      return filtered.take(limit).toList();
    }

    await tester.pumpWidget(
      wrap(
        CallHistoryScreen(
          userIdOverride: 'u1',
          pageSize: 2,
          callHistoryLoader: loader,
        ),
        size: const Size(390, 760),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('call_history_tile_c1')), findsOneWidget);
    expect(find.byKey(const Key('call_history_tile_c2')), findsOneWidget);
    expect(find.byKey(const Key('call_history_tile_c3')), findsOneWidget);

    source = [buildCall(id: 'fresh', createdAt: now), ...source];

    await tester.drag(
      find.byKey(const Key('call_history_list')),
      const Offset(0, 360),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('call_history_tile_fresh')), findsOneWidget);
    expect(loadCount, greaterThanOrEqualTo(3));
  });
}
