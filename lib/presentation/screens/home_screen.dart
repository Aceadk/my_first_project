import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../design_system/tokens/breakpoints.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/gradients.dart';
import '../../design_system/widgets/glass_bottom_nav_bar.dart';
import 'package:crushhour/features/discovery/presentation/screens/deck_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/matches_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_view_screen.dart';
import 'package:crushhour/core/services/badge_counter_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _goToDeck() => setState(() => _index = 0);

  /// Build navigation items with badge counts from state.
  List<GlassNavItem> _buildNavItems(BadgeCountState badgeState) {
    return [
      const GlassNavItem(
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
        badgeCount: badgeState.newMatches,
      ),
      GlassNavItem(
        icon: Icons.send_outlined,
        activeIcon: Icons.send,
        label: 'Chats',
        gradient: DsGradients.chats,
        badgeCount: badgeState.unreadChats,
        showDotOnly: true,
      ),
      const GlassNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        gradient: DsGradients.profile,
      ),
    ];
  }

  List<NavigationRailDestination> _railDestinations(List<GlassNavItem> items) {
    return items.map((item) {
      Widget icon = Icon(item.icon);
      if (item.badgeCount > 0) {
        icon = Badge(
          label: item.showDotOnly ? null : Text('${item.badgeCount}'),
          isLabelVisible: true,
          child: icon,
        );
      }
      return NavigationRailDestination(
        icon: icon,
        selectedIcon: Icon(item.activeIcon),
        label: Text(item.label),
      );
    }).toList();
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
        ),
        child: const Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: DsGradients.meshRadial),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: DsGradients.meshRadialSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      const DeckScreen(),
      MatchesScreen(onBackToDeck: _goToDeck),
      const ChatListScreen(),
      const ProfileViewScreen(),
    ];

    return BlocBuilder<BadgeCounterCubit, BadgeCountState>(
      builder: (context, badgeState) {
        final navItems = _buildNavItems(badgeState);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = DsBreakpoints.isMobile(constraints.maxWidth);
            final isDesktop = DsBreakpoints.isDesktop(constraints.maxWidth);

            // Mobile: bottom navigation bar
            if (isMobile) {
              return Scaffold(
                extendBody: true,
                body: Stack(
                  children: [
                    _buildBackground(isDark),
                    Positioned.fill(child: screens[_index]),
                  ],
                ),
                bottomNavigationBar: GlassBottomNavBar(
                  currentIndex: _index,
                  onTap: (index) => setState(() => _index = index),
                  items: navItems,
                ),
              );
            }

            // Tablet/Desktop: NavigationRail on the left
            return Scaffold(
              body: Stack(
                children: [
                  _buildBackground(isDark),
                  Positioned.fill(
                    child: Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _index,
                          onDestinationSelected: (index) =>
                              setState(() => _index = index),
                          extended: isDesktop,
                          minWidth: 72,
                          minExtendedWidth: 200,
                          backgroundColor: Colors.transparent,
                          destinations: _railDestinations(navItems),
                          labelType: isDesktop
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.selected,
                        ),
                        const VerticalDivider(width: 1, thickness: 0.5),
                        Expanded(child: screens[_index]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
