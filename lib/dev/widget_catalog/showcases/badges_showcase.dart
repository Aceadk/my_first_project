import 'package:flutter/material.dart';
import 'package:crushhour/design_system/widgets/crush_badge.dart';
import '../widget_showcase.dart';

/// Showcase for badge widgets.
class BadgesShowcase extends StatelessWidget {
  const BadgesShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(
          title: 'CrushBadge',
          subtitle: 'Notification badges and indicators',
        ),
        WidgetShowcase(
          title: 'Count Badge',
          description: 'Shows notification count (max 99+)',
          codeExample: '''
CrushBadge.count(
  count: 42,
  child: IconButton(
    icon: Icon(Icons.notifications),
    onPressed: () {},
  ),
)''',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrushBadge.count(count: 3, child: _buildIconButton()),
              const SizedBox(width: 24),
              CrushBadge.count(count: 42, child: _buildIconButton()),
              const SizedBox(width: 24),
              CrushBadge.count(count: 150, child: _buildIconButton()),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'Dot Badge',
          description: 'Simple dot indicator for new content',
          codeExample: '''
CrushBadge.dot(
  child: IconButton(
    icon: Icon(Icons.mail),
    onPressed: () {},
  ),
)''',
          child: CrushBadge.dot(child: _buildIconButton()),
        ),
        WidgetShowcase(
          title: 'New Badge',
          description: 'Label badge for new features',
          codeExample: '''
CrushNewBadge(
  child: ListTile(
    title: Text('New Feature'),
  ),
)''',
          child: CrushNewBadge(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Premium Feature'),
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Pulsing Badge',
          description: 'Animated attention-grabbing indicator',
          codeExample: '''
CrushPulsingBadge(
  child: IconButton(
    icon: Icon(Icons.chat),
    onPressed: () {},
  ),
)''',
          child: CrushPulsingBadge(child: _buildIconButton()),
        ),
        WidgetVariants(
          title: 'Badge Types',
          description: 'All badge variants at a glance',
          variants: [
            WidgetVariant(
              label: 'Count',
              child: CrushBadge.count(count: 5, child: _buildIconButton()),
            ),
            WidgetVariant(
              label: 'Dot',
              child: CrushBadge.dot(child: _buildIconButton()),
            ),
            WidgetVariant(
              label: 'New',
              child: CrushNewBadge(child: _buildChip()),
            ),
            WidgetVariant(
              label: 'Pulsing',
              child: CrushPulsingBadge(child: _buildIconButton()),
            ),
          ],
        ),
        const ShowcaseSection(
          title: 'Badge Positioning',
          subtitle: 'Badges on different widget types',
        ),
        WidgetShowcase(
          title: 'On List Item',
          description: 'Badge positioned on a list tile',
          child: Card(
            child: CrushBadge.count(
              count: 2,
              child: ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Messages'),
                subtitle: const Text('2 unread'),
                onTap: () {},
              ),
            ),
          ),
        ),
        WidgetShowcase(
          title: 'On Navigation',
          description: 'Badge on bottom navigation icon',
          child: NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Icon(Icons.favorite),
                label: 'Matches',
              ),
              NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton() {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {},
    );
  }

  Widget _buildChip() {
    return const Chip(label: Text('Feature'));
  }
}
