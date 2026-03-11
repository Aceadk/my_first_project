import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/support_config.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/widgets/adaptive_dialog.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import '../../../../core/routing/crush_routes.dart';

/// Customer support screen with help categories, FAQ, and contact options.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _appVersion = '';
  String? _expandedFaqId;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).helpSupport),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open Help Center',
            onPressed: () => SupportConfig.openHelpCenter(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: ListView(
              padding: const EdgeInsets.all(DsSpacing.lg),
              children: [
                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: DsSpacing.xl),

                // Help Categories
                Text(
                  'How can we help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                _buildCategoryGrid(context),
                const SizedBox(height: DsSpacing.xl),

                // FAQ Section
                Text(
                  'Frequently Asked Questions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                _buildFaqList(context),
                const SizedBox(height: DsSpacing.xl),

                // Contact Options
                Text(
                  'Still need help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                _buildContactOptions(context),
                const SizedBox(height: DsSpacing.xl),

                // App Info
                Center(
                  child: Text(
                    'Crush v$_appVersion',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ),
                const SizedBox(height: DsSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.shield,
            label: 'Safety',
            color: Colors.orange,
            onTap: () => SupportConfig.openSafetyCenter(),
          ),
        ),
        const SizedBox(width: DsSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.email,
            label: 'Email Us',
            color: DsColors.primary,
            onTap: () => _showContactSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.4).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 640
            ? 3
            : 2;
        final mainAxisExtent = 138.0 + ((textScale - 1.0) * 36.0);

        return GridView.builder(
          itemCount: SupportConfig.categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: DsSpacing.md,
            crossAxisSpacing: DsSpacing.md,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final category = SupportConfig.categories[index];
            return _CategoryCard(
              category: category,
              onTap: () {
                context.push(CrushRoutes.supportCategoryPath(category.id));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFaqList(BuildContext context) {
    return Column(
      children: SupportConfig.frequentlyAsked.map((faq) {
        final isExpanded = _expandedFaqId == faq.question;
        return _FaqCard(
          faq: faq,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedFaqId = isExpanded ? null : faq.question;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildContactOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: Text(AppLocalizations.of(context).emailSupport),
          subtitle: const Text(SupportConfig.supportEmail),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showContactSheet(context),
          tileColor: isDark
              ? DsColors.surfaceElevatedDark
              : DsColors.surfaceElevatedLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.md),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: Text(AppLocalizations.of(context).helpCenter),
          subtitle: Text(AppLocalizations.of(context).browseArticlesAndGuides),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SupportConfig.openHelpCenter(),
          tileColor: isDark
              ? DsColors.surfaceElevatedDark
              : DsColors.surfaceElevatedLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.md),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(AppLocalizations.of(context).communityGuidelines),
          subtitle: Text(AppLocalizations.of(context).ourRulesAndStandards),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SupportConfig.openHelpCenter('guidelines'),
          tileColor: isDark
              ? DsColors.surfaceElevatedDark
              : DsColors.surfaceElevatedLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.md),
          ),
        ),
      ],
    );
  }

  void _showContactSheet(BuildContext context) {
    AdaptiveBottomSheet.show<void>(
      context: context,
      builder: (context) => const _ContactSupportSheet(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? DsColors.surfaceElevatedDark
          : DsColors.surfaceElevatedLight,
      borderRadius: BorderRadius.circular(DsRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: DsSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SupportCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  IconData get _iconData {
    switch (category.icon) {
      case 'account_circle':
        return Icons.account_circle_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'chat':
        return Icons.chat_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'privacy_tip':
        return Icons.privacy_tip_outlined;
      case 'build':
        return Icons.build_outlined;
      case 'help':
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? DsColors.surfaceElevatedDark
          : DsColors.surfaceElevatedLight,
      borderRadius: BorderRadius.circular(DsRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconData,
                color: category.priority == SupportPriority.high
                    ? Colors.orange
                    : DsColors.primary,
              ),
              const SizedBox(height: DsSpacing.sm),
              Text(
                category.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final FaqItem faq;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqCard({
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: DsSpacing.sm),
      child: Material(
        color: isDark
            ? DsColors.surfaceElevatedDark
            : DsColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DsRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: DsSpacing.md),
                  Text(
                    faq.answer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactSupportSheet extends StatefulWidget {
  const _ContactSupportSheet();

  @override
  State<_ContactSupportSheet> createState() => _ContactSupportSheetState();
}

class _ContactSupportSheetState extends State<_ContactSupportSheet> {
  String _selectedCategory = 'other';
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: DsSpacing.lg,
        end: DsSpacing.lg,
        top: DsSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + DsSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Support',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DsSpacing.lg),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: SupportConfig.categories.map((cat) {
                return DropdownMenuItem(value: cat.id, child: Text(cat.title));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: DsSpacing.md),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe your issue',
                hintText: 'Please provide as much detail as possible...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DsSpacing.lg),

            // Send button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sendSupportEmail,
                icon: const Icon(Icons.email),
                label: Text(AppLocalizations.of(context).openEmail),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, DsSizes.tapTargetPreferred),
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),

            // Note
            Text(
              'This will open your email app with the support details.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _sendSupportEmail() {
    final category = SupportConfig.categoryById(_selectedCategory);

    final body = SupportConfig.generateSupportBody(
      category: category.title,
      description: _descriptionController.text,
    );

    SupportConfig.openSupportEmail(
      subject: 'Crush Support: ${category.title}',
      body: body,
      category: _selectedCategory,
    );

    Navigator.pop(context);
  }
}
