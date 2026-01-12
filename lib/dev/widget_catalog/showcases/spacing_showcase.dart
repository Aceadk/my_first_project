import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import '../widget_showcase.dart';

/// Showcase for spacing and radius tokens.
class SpacingShowcase extends StatelessWidget {
  const SpacingShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(
          title: 'DsSpacing',
          subtitle: 'Consistent spacing values throughout the app',
        ),
        WidgetShowcase(
          title: 'Spacing Scale',
          description: 'Visual representation of spacing tokens',
          codeExample: '''
// Usage
SizedBox(height: DsSpacing.md) // 12px
Padding(padding: EdgeInsets.all(DsSpacing.lg)) // 16px

// Available values
DsSpacing.xs   = 4px
DsSpacing.sm   = 8px
DsSpacing.md   = 12px
DsSpacing.lg   = 16px
DsSpacing.xl   = 20px
DsSpacing.xxl  = 24px
DsSpacing.xxxl = 32px
DsSpacing.huge = 40px''',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSpacingRow(context, 'xs', DsSpacing.xs),
              _buildSpacingRow(context, 'sm', DsSpacing.sm),
              _buildSpacingRow(context, 'md', DsSpacing.md),
              _buildSpacingRow(context, 'lg', DsSpacing.lg),
              _buildSpacingRow(context, 'xl', DsSpacing.xl),
              _buildSpacingRow(context, 'xxl', DsSpacing.xxl),
              _buildSpacingRow(context, 'xxxl', DsSpacing.xxxl),
              _buildSpacingRow(context, 'huge', DsSpacing.huge),
            ],
          ),
        ),
        const ShowcaseSection(
          title: 'DsRadius',
          subtitle: 'Border radius tokens for consistent corners',
        ),
        WidgetShowcase(
          title: 'Radius Scale',
          description: 'Visual representation of radius tokens',
          codeExample: '''
// Usage
BorderRadius.circular(DsRadius.md) // 12px

// Available values
DsRadius.sm = 8px
DsRadius.md = 12px
DsRadius.lg = 16px
DsRadius.xl = 24px''',
          child: Wrap(
            spacing: DsSpacing.md,
            runSpacing: DsSpacing.md,
            children: [
              _buildRadiusBox(context, 'sm', DsRadius.sm),
              _buildRadiusBox(context, 'md', DsRadius.md),
              _buildRadiusBox(context, 'lg', DsRadius.lg),
              _buildRadiusBox(context, 'xl', DsRadius.xl),
            ],
          ),
        ),
        const ShowcaseSection(
          title: 'DsColors',
          subtitle: 'Design system color palette',
        ),
        WidgetShowcase(
          title: 'Primary Colors',
          description: 'Brand and accent colors',
          codeExample: '''
// Usage
color: DsColors.primary

// Primary colors
DsColors.primary
DsColors.secondary
DsColors.info''',
          child: Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: [
              _buildColorSwatch(context, 'primary', DsColors.primary),
              _buildColorSwatch(context, 'secondary', DsColors.secondary),
              _buildColorSwatch(context, 'info', DsColors.info),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'Surface Colors',
          description: 'Background and surface colors',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildColorSwatch(context, 'bgLight', DsColors.backgroundLight)),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(child: _buildColorSwatch(context, 'bgDark', DsColors.backgroundDark)),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
              Row(
                children: [
                  Expanded(child: _buildColorSwatch(context, 'surfaceLight', DsColors.surfaceLight)),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(child: _buildColorSwatch(context, 'surfaceDark', DsColors.surfaceDark)),
                ],
              ),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'Text Colors',
          description: 'Colors for text content',
          codeExample: '''
// Usage
Text(
  'Hello',
  style: TextStyle(color: DsColors.textPrimaryLight),
)''',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextColorRow(context, 'textPrimaryLight', DsColors.textPrimaryLight),
              _buildTextColorRow(context, 'textPrimaryDark', DsColors.textPrimaryDark),
              _buildTextColorRow(context, 'textMutedLight', DsColors.textMutedLight),
              _buildTextColorRow(context, 'textMutedDark', DsColors.textMutedDark),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'Border Colors',
          description: 'Colors for borders and dividers',
          child: Row(
            children: [
              Expanded(child: _buildColorSwatch(context, 'borderLight', DsColors.borderLight)),
              const SizedBox(width: DsSpacing.sm),
              Expanded(child: _buildColorSwatch(context, 'borderDark', DsColors.borderDark)),
            ],
          ),
        ),
        const ShowcaseSection(
          title: 'Semantic Colors',
          subtitle: 'Colors for status and feedback',
        ),
        WidgetShowcase(
          title: 'Status Colors',
          description: 'Success, error, warning states',
          codeExample: '''
// Usage for status indicators
Container(
  color: DsColors.success, // Green
)
Container(
  color: DsColors.error, // Red
)''',
          child: Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: [
              _buildColorSwatch(context, 'success', DsColors.success),
              _buildColorSwatch(context, 'warning', DsColors.warning),
              _buildColorSwatch(context, 'error', DsColors.error),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpacingRow(BuildContext context, String name, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          Container(
            width: value,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Text(
            '${value.toInt()}px',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusBox(BuildContext context, String name, double radius) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        const SizedBox(height: DsSpacing.xs),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
        Text(
          '${radius.toInt()}px',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildColorSwatch(BuildContext context, String name, Color color) {
    final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DsRadius.sm),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildTextColorRow(BuildContext context, String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }
}
