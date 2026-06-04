import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// App-wide scroll behavior that makes scrolling feel native across every input
/// surface — phones, tablets, and web/desktop with a mouse or trackpad.
///
/// Flutter's default [MaterialScrollBehavior] omits [PointerDeviceKind.mouse]
/// from [dragDevices], so on web and desktop a click-and-drag gesture does not
/// scroll lists or grids (only the wheel or a trackpad does). That feels broken
/// to pointer users. Restoring mouse/stylus drag gives tablet and web users the
/// same direct-manipulation scrolling as touch users (RESP-003).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}
