import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/router_refresh_stream.dart';

void main() {
  test('GoRouterRefreshStream notifies listeners for stream events', () async {
    final controller = StreamController<int>();
    final notifier = GoRouterRefreshStream(controller.stream);

    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    controller.add(1);
    controller.add(2);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(notifications, equals(2));

    notifier.dispose();
    await controller.close();
  });
}
