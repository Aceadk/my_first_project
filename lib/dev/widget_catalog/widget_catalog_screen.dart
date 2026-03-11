import 'package:flutter/material.dart';
import 'showcases/buttons_showcase.dart';
import 'showcases/inputs_showcase.dart';
import 'showcases/avatars_showcase.dart';
import 'showcases/cards_showcase.dart';
import 'showcases/states_showcase.dart';
import 'showcases/layout_showcase.dart';
import 'showcases/badges_showcase.dart';
import 'showcases/spacing_showcase.dart';

/// Widget Catalog - Storybook-style documentation for all UI components.
///
/// Access this screen in debug builds to explore and test widgets.
class WidgetCatalogScreen extends StatelessWidget {
  const WidgetCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () {
              // Toggle theme for testing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use app settings to change theme'),
                ),
              );
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          ..._categories.map((cat) => _CategoryTile(category: cat)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crush Design System',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Browse and test all UI components in one place. '
          'Each showcase includes usage examples and code snippets.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(label: '${_categories.length} Categories'),
            const _StatChip(label: '29+ Widgets'),
            const _StatChip(label: 'Live Preview'),
          ],
        ),
      ],
    );
  }

  static final List<_CatalogCategory> _categories = [
    _CatalogCategory(
      title: 'Buttons',
      description: 'Primary buttons, loading states, and actions',
      icon: Icons.smart_button,
      color: Colors.blue,
      builder: (_) => const ButtonsShowcase(),
    ),
    _CatalogCategory(
      title: 'Text Inputs',
      description: 'Text fields, OTP inputs, and form elements',
      icon: Icons.text_fields,
      color: Colors.green,
      builder: (_) => const InputsShowcase(),
    ),
    _CatalogCategory(
      title: 'Avatars',
      description: 'User avatars, avatar stacks, and indicators',
      icon: Icons.account_circle,
      color: Colors.purple,
      builder: (_) => const AvatarsShowcase(),
    ),
    _CatalogCategory(
      title: 'Badges',
      description: 'Notification badges, dots, and labels',
      icon: Icons.new_releases,
      color: Colors.red,
      builder: (_) => const BadgesShowcase(),
    ),
    _CatalogCategory(
      title: 'Cards',
      description: 'Profile cards, info cards, and containers',
      icon: Icons.credit_card,
      color: Colors.orange,
      builder: (_) => const CardsShowcase(),
    ),
    _CatalogCategory(
      title: 'States',
      description: 'Loading, error, empty states, and overlays',
      icon: Icons.hourglass_empty,
      color: Colors.teal,
      builder: (_) => const StatesShowcase(),
    ),
    _CatalogCategory(
      title: 'Layout',
      description: 'Scaffolds, responsive containers, and structure',
      icon: Icons.dashboard,
      color: Colors.indigo,
      builder: (_) => const LayoutShowcase(),
    ),
    _CatalogCategory(
      title: 'Spacing',
      description: 'Gaps, padding, and spacing tokens',
      icon: Icons.space_bar,
      color: Colors.brown,
      builder: (_) => const SpacingShowcase(),
    ),
  ];
}

class _CatalogCategory {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) builder;

  const _CatalogCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

class _CategoryTile extends StatelessWidget {
  final _CatalogCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(
          category.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(category.description, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _CategoryDetailScreen(category: category),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryDetailScreen extends StatelessWidget {
  final _CatalogCategory category;

  const _CategoryDetailScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: category.builder(context),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
