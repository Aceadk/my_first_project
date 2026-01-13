import 'package:flutter/material.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/gradients.dart';
import '../../design_system/widgets/glass_bottom_nav_bar.dart';
import 'package:crushhour/features/discovery/presentation/screens/deck_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/matches_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _goToDeck() => setState(() => _index = 0);

  // Navigation items with glass styling
  static const _navItems = [
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
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      const DeckScreen(),
      MatchesScreen(onBackToDeck: _goToDeck),
      const ChatListScreen(),
      const ProfileViewScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Gradient mesh background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
              ),
              child: const Stack(
                children: [
                  // Top-right radial gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DsGradients.meshRadial,
                      ),
                    ),
                  ),
                  // Bottom-left radial gradient
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
          ),
          // Screen content
          Positioned.fill(
            child: screens[_index],
          ),
        ],
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: _navItems,
      ),
    );
  }
}
