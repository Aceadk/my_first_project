import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import '../widget_showcase.dart';

/// Showcase for layout widgets and patterns.
class LayoutShowcase extends StatelessWidget {
  const LayoutShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(
          title: 'Flex Layouts',
          subtitle: 'Row and Column arrangements',
        ),
        WidgetShowcase(
          title: 'Row with MainAxisAlignment',
          description: 'Horizontal arrangement options',
          codeExample: '''
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [...],
)''',
          child: Column(
            children: [
              _buildRowExample(context, MainAxisAlignment.start, 'start'),
              const SizedBox(height: DsSpacing.sm),
              _buildRowExample(context, MainAxisAlignment.center, 'center'),
              const SizedBox(height: DsSpacing.sm),
              _buildRowExample(context, MainAxisAlignment.end, 'end'),
              const SizedBox(height: DsSpacing.sm),
              _buildRowExample(
                context,
                MainAxisAlignment.spaceBetween,
                'spaceBetween',
              ),
              const SizedBox(height: DsSpacing.sm),
              _buildRowExample(
                context,
                MainAxisAlignment.spaceEvenly,
                'spaceEvenly',
              ),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'CrossAxisAlignment',
          description: 'Vertical alignment in rows',
          codeExample: '''
Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [...],
)''',
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildFlexChild(context, 'stretch', flex: 1)],
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'Flexible & Expanded',
          subtitle: 'Flex factor distribution',
        ),
        WidgetShowcase(
          title: 'Expanded Widgets',
          description: 'Fills available space proportionally',
          codeExample: '''
Row(
  children: [
    Expanded(flex: 1, child: ...),
    Expanded(flex: 2, child: ...),
    Expanded(flex: 1, child: ...),
  ],
)''',
          child: Row(
            children: [
              Expanded(flex: 1, child: _buildFlexChild(context, 'flex: 1')),
              const SizedBox(width: DsSpacing.sm),
              Expanded(flex: 2, child: _buildFlexChild(context, 'flex: 2')),
              const SizedBox(width: DsSpacing.sm),
              Expanded(flex: 1, child: _buildFlexChild(context, 'flex: 1')),
            ],
          ),
        ),
        const ShowcaseSection(
          title: 'Stack Layout',
          subtitle: 'Overlapping widgets',
        ),
        WidgetShowcase(
          title: 'Positioned Stack',
          description: 'Absolute positioning within a container',
          codeExample: '''
Stack(
  children: [
    PositionedDirectional(
      top: 8,
      start: 8,
      child: ...,
    ),
    Center(child: ...),
  ],
)''',
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: _buildPositionedBox(context, 'Top Left', Colors.red),
                ),
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: _buildPositionedBox(context, 'Top Right', Colors.blue),
                ),
                PositionedDirectional(
                  bottom: 8,
                  start: 8,
                  child: _buildPositionedBox(
                    context,
                    'Bottom Left',
                    Colors.green,
                  ),
                ),
                PositionedDirectional(
                  bottom: 8,
                  end: 8,
                  child: _buildPositionedBox(
                    context,
                    'Bottom Right',
                    Colors.orange,
                  ),
                ),
                const Center(child: Text('Center')),
              ],
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'Wrap Layout',
          subtitle: 'Flow layout for wrapping content',
        ),
        WidgetShowcase(
          title: 'Wrap',
          description: 'Items flow to next line when full',
          codeExample: '''
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    ...
  ],
)''',
          child: Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: [
              for (final tag in [
                'Dating',
                'Movies',
                'Music',
                'Travel',
                'Food',
                'Gym',
                'Art',
                'Books',
              ])
                Chip(label: Text(tag)),
            ],
          ),
        ),
        const ShowcaseSection(
          title: 'GridView',
          subtitle: 'Grid-based layouts',
        ),
        WidgetShowcase(
          title: 'Grid Layout',
          description: 'Fixed column count grid',
          codeExample: '''
GridView.count(
  crossAxisCount: 3,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  children: [...],
)''',
          child: SizedBox(
            height: 180,
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: DsSpacing.sm,
              mainAxisSpacing: DsSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 1; i <= 6; i++)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('$i')),
                  ),
              ],
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'Constraints',
          subtitle: 'Size constraints on widgets',
        ),
        WidgetVariants(
          title: 'Size Constraints',
          description: 'Different constraint widgets',
          horizontal: false,
          variants: [
            WidgetVariant(
              label: 'SizedBox',
              child: SizedBox(
                width: 100,
                height: 50,
                child: Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: const Center(
                    child: Text(
                      '100x50',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            WidgetVariant(
              label: 'ConstrainedBox',
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 80,
                  maxWidth: 150,
                  minHeight: 40,
                ),
                child: Container(
                  color: Theme.of(context).colorScheme.secondary,
                  child: const Center(
                    child: Text(
                      'Constrained',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            WidgetVariant(
              label: 'AspectRatio',
              child: SizedBox(
                width: 100,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Theme.of(context).colorScheme.tertiary,
                    child: const Center(
                      child: Text(
                        '16:9',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRowExample(
    BuildContext context,
    MainAxisAlignment alignment,
    String label,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          _buildSmallBox(context),
          _buildSmallBox(context),
          _buildSmallBox(context),
        ],
      ),
    );
  }

  Widget _buildSmallBox(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildFlexChild(BuildContext context, String label, {int flex = 1}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: Text(label)),
    );
  }

  Widget _buildPositionedBox(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
