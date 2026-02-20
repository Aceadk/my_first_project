import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import '../widget_showcase.dart';

/// Showcase for card widgets.
class CardsShowcase extends StatelessWidget {
  const CardsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(
          title: 'Material Card',
          subtitle: 'Standard Flutter Card widget variations',
        ),
        WidgetShowcase(
          title: 'Basic Card',
          description: 'Simple card with content',
          codeExample: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Card Title'),
        Text('Card content'),
      ],
    ),
  ),
)''',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(DsSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  Text(
                    'This is a basic card with some content inside.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Elevated Card',
          description: 'Card with more elevation',
          codeExample: '''
Card(
  elevation: 8,
  child: Padding(...),
)''',
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(DsSpacing.lg),
              child: Text(
                'Elevated Card',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Outlined Card',
          description: 'Card with border, no shadow',
          codeExample: '''
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Colors.grey),
  ),
  child: ...,
)''',
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DsRadius.md),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DsSpacing.lg),
              child: Text(
                'Outlined Card',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'Interactive Cards',
          subtitle: 'Cards with tap actions',
        ),
        WidgetShowcase(
          title: 'Tappable Card',
          description: 'Card that responds to taps',
          codeExample: '''
Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: () => handleTap(),
    child: Padding(...),
  ),
)''',
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(DsSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app),
                    const SizedBox(width: DsSpacing.md),
                    Text(
                      'Tap me!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'Card Layouts',
          subtitle: 'Common card content patterns',
        ),
        WidgetShowcase(
          title: 'Profile Card',
          description: 'Card with avatar and user info',
          codeExample: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        CircleAvatar(...),
        Expanded(child: Column(...)),
        IconButton(...),
      ],
    ),
  ),
)''',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(DsSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Text(
                      'JD',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jane Doe',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '25 years old',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Stats Card',
          description: 'Card showing statistics',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(DsSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(context, '128', 'Matches'),
                  _buildDivider(context),
                  _buildStat(context, '42', 'Likes'),
                  _buildDivider(context),
                  _buildStat(context, '15', 'Chats'),
                ],
              ),
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Action Card',
          description: 'Card with action buttons',
          codeExample: '''
Card(
  child: Column(
    children: [
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(...),
      ),
      Divider(height: 1),
      Row(
        children: [
          TextButton(...),
          FilledButton(...),
        ],
      ),
    ],
  ),
)''',
          child: Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade to Plus',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: DsSpacing.sm),
                      Text(
                        'Unlock unlimited likes, see who likes you, and more!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(DsSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Later')),
                      const SizedBox(width: DsSpacing.sm),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).dividerColor,
    );
  }
}
