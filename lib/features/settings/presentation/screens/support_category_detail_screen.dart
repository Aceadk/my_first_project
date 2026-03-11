import 'package:flutter/material.dart';

import '../../../../config/support_config.dart';
import '../../../../design_system/design_system.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

/// Dedicated category help page with full guidance + related answers.
class SupportCategoryDetailScreen extends StatefulWidget {
  final SupportCategory category;

  const SupportCategoryDetailScreen({required this.category, super.key});

  @override
  State<SupportCategoryDetailScreen> createState() =>
      _SupportCategoryDetailScreenState();
}

class _SupportCategoryDetailScreenState
    extends State<SupportCategoryDetailScreen> {
  String? _expandedFaqId;

  IconData get _iconData {
    switch (widget.category.icon) {
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
    final article = SupportConfig.articleForCategory(widget.category.id);
    final relatedFaqs = SupportConfig.faqsForCategory(widget.category.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open Help Center',
            onPressed: () => SupportConfig.openHelpCenter(widget.category.id),
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
                Material(
                  color: isDark
                      ? DsColors.surfaceElevatedDark
                      : DsColors.surfaceElevatedLight,
                  borderRadius: BorderRadius.circular(DsRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(DsSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _iconData,
                              color:
                                  widget.category.priority ==
                                      SupportPriority.high
                                  ? Colors.orange
                                  : DsColors.primary,
                            ),
                            const SizedBox(width: DsSpacing.sm),
                            Expanded(
                              child: Text(
                                '${widget.category.title} Help Guide',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          article.overview,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DsSpacing.lg),
                Text(
                  'Recommended steps',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                ...List.generate(article.quickSteps.length, (index) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: DsSpacing.sm,
                    ),
                    child: _ArticleStepCard(
                      stepNumber: index + 1,
                      text: article.quickSteps[index],
                    ),
                  );
                }),
                const SizedBox(height: DsSpacing.md),
                Text(
                  'Escalate to support when',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                ...article.escalationHints.map(
                  (hint) => Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: DsSpacing.sm,
                    ),
                    child: _EscalationHintCard(text: hint),
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                Text(
                  'Related questions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                if (relatedFaqs.isEmpty)
                  Material(
                    color: isDark
                        ? DsColors.surfaceElevatedDark
                        : DsColors.surfaceElevatedLight,
                    borderRadius: BorderRadius.circular(DsRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(DsSpacing.md),
                      child: Text(
                        'No in-app FAQ is available for this category yet. Use Help Center for full docs.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...relatedFaqs.map((faq) {
                    final faqId = '${widget.category.id}:${faq.question}';
                    final isExpanded = _expandedFaqId == faqId;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: DsSpacing.sm,
                      ),
                      child: _ArticleFaqCard(
                        faq: faq,
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            _expandedFaqId = isExpanded ? null : faqId;
                          });
                        },
                      ),
                    );
                  }),
                const SizedBox(height: DsSpacing.md),
                Text(
                  'Need more help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Wrap(
                  spacing: DsSpacing.sm,
                  runSpacing: DsSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        final body = SupportConfig.generateSupportBody(
                          category: widget.category.title,
                          description:
                              'Please describe your issue here with steps to reproduce.',
                        );
                        SupportConfig.openSupportEmail(
                          subject: 'Crush Support: ${widget.category.title}',
                          body: body,
                          category: widget.category.id,
                        );
                      },
                      icon: const Icon(Icons.email_outlined),
                      label: Text(AppLocalizations.of(context).openEmail),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          SupportConfig.openHelpCenter(widget.category.id),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(AppLocalizations.of(context).helpCenter),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleStepCard extends StatelessWidget {
  final int stepNumber;
  final String text;

  const _ArticleStepCard({required this.stepNumber, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? DsColors.surfaceElevatedDark
          : DsColors.surfaceElevatedLight,
      borderRadius: BorderRadius.circular(DsRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: DsColors.primary.withValues(alpha: 0.12),
              child: Text(
                '$stepNumber',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: DsColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _EscalationHintCard extends StatelessWidget {
  final String text;

  const _EscalationHintCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? DsColors.surfaceElevatedDark
          : DsColors.surfaceElevatedLight,
      borderRadius: BorderRadius.circular(DsRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.orange),
            const SizedBox(width: DsSpacing.sm),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _ArticleFaqCard extends StatelessWidget {
  final FaqItem faq;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ArticleFaqCard({
    required this.faq,
    required this.isExpanded,
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
                const SizedBox(height: DsSpacing.xs),
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
    );
  }
}
