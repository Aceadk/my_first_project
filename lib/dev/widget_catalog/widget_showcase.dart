import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A showcase wrapper for displaying widgets in the catalog.
///
/// Displays a widget with its title, description, usage example,
/// and optionally multiple variants.
class WidgetShowcase extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final String? codeExample;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const WidgetShowcase({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.codeExample,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Widget preview
          Container(
            width: double.infinity,
            color: backgroundColor ?? theme.colorScheme.surfaceContainerLowest,
            padding: padding,
            child: Center(child: child),
          ),

          // Code example
          if (codeExample != null) ...[
            const Divider(height: 1),
            _CodeBlock(code: codeExample!),
          ],
        ],
      ),
    );
  }
}

/// Displays multiple variants of a widget side by side or stacked.
class WidgetVariants extends StatelessWidget {
  final String title;
  final String? description;
  final List<WidgetVariant> variants;
  final bool horizontal;

  const WidgetVariants({
    super.key,
    required this.title,
    this.description,
    required this.variants,
    this.horizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerLowest,
            padding: const EdgeInsets.all(16),
            child: horizontal
                ? Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: variants.map((v) => _VariantItem(variant: v)).toList(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: variants
                        .map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _VariantItem(variant: v),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class WidgetVariant {
  final String label;
  final Widget child;

  const WidgetVariant({
    required this.label,
    required this.child,
  });
}

class _VariantItem extends StatelessWidget {
  final WidgetVariant variant;

  const _VariantItem({required this.variant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        variant.child,
        const SizedBox(height: 8),
        Text(
          variant.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CodeBlock extends StatefulWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.code_off : Icons.code,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _expanded ? 'Hide code' : 'Show code',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1),
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Section header for grouping related showcases.
class ShowcaseSection extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ShowcaseSection({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
