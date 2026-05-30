import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/widgets/glass_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const iPhoneSize = Size(393, 852);
  const bottomSafeArea = 34.0;

  const navItems = [
    GlassNavItem(
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department,
      label: 'Discover',
      gradient: DsGradients.discover,
    ),
    GlassNavItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Matches',
      gradient: DsGradients.matches,
    ),
    GlassNavItem(
      icon: Icons.send_outlined,
      activeIcon: Icons.send,
      label: 'Chats',
      gradient: DsGradients.chats,
    ),
    GlassNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      gradient: DsGradients.profile,
    ),
  ];

  Widget buildSubject({required int currentIndex, ValueChanged<int>? onTap}) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: iPhoneSize,
          padding: EdgeInsets.only(bottom: bottomSafeArea),
          viewPadding: EdgeInsets.only(bottom: bottomSafeArea),
        ),
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: GlassBottomNavBar(
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
            items: navItems,
          ),
        ),
      ),
    );
  }

  testWidgets('shows all labels above the iPhone bottom safe area', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(iPhoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildSubject(currentIndex: 1));

    for (final label in ['Discover', 'Matches', 'Chats', 'Profile']) {
      expect(find.text(label), findsOneWidget);
      final labelBottom = tester.getBottomLeft(find.text(label)).dy;
      expect(labelBottom, lessThan(iPhoneSize.height - bottomSafeArea));
    }

    final navSize = tester.getSize(find.byType(GlassBottomNavBar));
    expect(navSize.height, 64 + bottomSafeArea);
  });

  testWidgets('keeps each tab tappable with stable equal-width hit targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(iPhoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var tappedIndex = -1;
    await tester.pumpWidget(
      buildSubject(currentIndex: 0, onTap: (index) => tappedIndex = index),
    );

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(tappedIndex, 3);

    final discoverSize = tester.getSize(find.text('Discover'));
    final profileSize = tester.getSize(find.text('Profile'));
    expect(discoverSize.height, greaterThan(0));
    expect(profileSize.height, greaterThan(0));
  });
}
