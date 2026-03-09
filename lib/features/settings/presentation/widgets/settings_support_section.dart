import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'settings_tile.dart';

class SettingsSupportSection extends StatelessWidget {
  const SettingsSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blockedCount = context.select<SafetyCubit, int>(
      (cubit) => cubit.state.blockedUsers.length,
    );
    final safetySubtitle = blockedCount == 0
        ? l10n.settingsManageBlockedUsers
        : l10n.blockedUserCount(blockedCount);

    return Column(
      children: [
        SettingsTile(
          icon: Icons.shield_outlined,
          iconColor: DsColors.accent,
          title: l10n.settingsSafetyBlocking,
          subtitle: safetySubtitle,
          onTap: () => context.push(CrushRoutes.safety),
        ),
        const Divider(height: 1),
        SettingsTile(
          icon: Icons.help_outline,
          iconColor: DsColors.info,
          title: l10n.helpSupport,
          subtitle: l10n.settingsHelpSubtitle,
          onTap: () => context.push(CrushRoutes.support),
        ),
        const Divider(height: 1),
        SettingsTile(
          icon: Icons.logout,
          iconColor: DsColors.ink300,
          title: l10n.authSignOut,
          subtitle: l10n.settingsSignOutSubtitle,
          onTap: () => context.push(CrushRoutes.logout),
        ),
      ],
    );
  }
}
