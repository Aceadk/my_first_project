import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class AccountSecuritySettingsScreen extends StatelessWidget {
  const AccountSecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentEmail =
        context.select<AuthBloc, String?>((bloc) => bloc.state.user?.email);
    final emailVerified = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.user?.isEmailVerified ?? false,
    );
    final hasEmail = currentEmail != null && currentEmail.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Security'),
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: DsEdgeInsets.allLg,
            margin: DsEdgeInsets.allLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.teal.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: DsEdgeInsets.allMd,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                DsGap.lgH,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protect Your Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DsGap.xs,
                      Text(
                        'Add extra layers of security to keep your account safe.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Email status card
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Container(
              padding: DsEdgeInsets.allMd,
              decoration: BoxDecoration(
                color: hasEmail
                    ? (emailVerified
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1))
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasEmail
                      ? (emailVerified
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3))
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasEmail
                        ? (emailVerified
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_outlined)
                        : Icons.error_outline,
                    color: hasEmail
                        ? (emailVerified ? Colors.green : Colors.orange)
                        : Colors.red,
                  ),
                  DsGap.mdH,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasEmail
                              ? (emailVerified
                                  ? 'Email verified'
                                  : 'Email not verified')
                              : 'No email added',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasEmail
                                ? (emailVerified ? Colors.green : Colors.orange)
                                : Colors.red,
                          ),
                        ),
                        if (hasEmail) ...[
                          DsGap.xs,
                          Text(
                            currentEmail,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DsGap.lg,
          // Security options
          _SecurityTile(
            icon: Icons.email_outlined,
            iconColor: Colors.blue,
            title: 'Email protection',
            subtitle: hasEmail
                ? (emailVerified ? 'Verified and active' : 'Verify your email')
                : 'Add an email for recovery and OTP',
            onTap: () => context.push(CrushRoutes.emailProtection),
          ),
          const Divider(indent: 72),
          _SecurityTile(
            icon: Icons.swap_horiz,
            iconColor: Colors.purple,
            title: 'Change email',
            subtitle: hasEmail ? 'Use a different email address' : 'Add an email first',
            enabled: hasEmail,
            onTap: hasEmail ? () => context.push(CrushRoutes.changeEmail) : null,
          ),
          const Divider(indent: 72),
          _SecurityTile(
            icon: Icons.devices_outlined,
            iconColor: Colors.teal,
            title: 'New device verification',
            subtitle: 'Verify new devices with email OTP',
            onTap: () => context.push(CrushRoutes.newDevice),
          ),
          DsGap.xxl,
          // Security tips
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Container(
              padding: DsEdgeInsets.allLg,
              decoration: BoxDecoration(
                color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? DsColors.borderDark : DsColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.amber,
                      ),
                      DsGap.mdH,
                      Text(
                        'Security tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  DsGap.md,
                  _TipItem(
                    text: 'Use a unique password for this app',
                    isDark: isDark,
                  ),
                  DsGap.sm,
                  _TipItem(
                    text: 'Enable email verification for account recovery',
                    isDark: isDark,
                  ),
                  DsGap.sm,
                  _TipItem(
                    text: 'Never share your verification codes',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          DsGap.xl,
        ],
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled ? null : Theme.of(context).disabledColor,
      ),
      enabled: enabled,
      onTap: onTap,
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green.withValues(alpha: 0.7),
        ),
        DsGap.smH,
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ),
      ],
    );
  }
}
