import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:flutter/material.dart';

class SettingsLinkItem {
  const SettingsLinkItem({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
}

class SettingsLinksSection extends StatelessWidget {
  const SettingsLinksSection({
    super.key,
    required this.heading,
    required this.links,
  });

  final String heading;
  final List<SettingsLinkItem> links;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: DsEdgeInsets.horizontalLg,
          child: Text(
            heading,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ),
        DsGap.sm,
        ...links.map((link) {
          return ListTile(
            leading: Icon(link.icon),
            title: Text(link.title),
            trailing: link.value != null
                ? Text(
                    link.value!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  )
                : const Icon(Icons.chevron_right),
            onTap: link.onTap,
          );
        }),
      ],
    );
  }
}
