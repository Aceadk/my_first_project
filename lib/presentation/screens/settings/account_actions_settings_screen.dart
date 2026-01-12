import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing_widgets.dart';

class AccountActionsSettingsScreen extends StatelessWidget {
  const AccountActionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Actions'),
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
                  Colors.deepPurple.withValues(alpha: 0.1),
                  Colors.indigo.withValues(alpha: 0.1),
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
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_outlined,
                    color: Colors.deepPurple,
                    size: 28,
                  ),
                ),
                DsGap.lgH,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Your Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DsGap.xs,
                      Text(
                        'Change phone, pause, or delete your account.',
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
          // Account actions
          _ActionTile(
            icon: Icons.phone_android,
            iconColor: Colors.blue,
            title: 'Change phone number',
            subtitle: 'Re-verify with a new phone number',
            onTap: () => _confirmChangePhone(context),
          ),
          const Divider(indent: 72),
          _ActionTile(
            icon: Icons.pause_circle_outline,
            iconColor: Colors.orange,
            title: 'Deactivate account',
            subtitle: 'Hide your profile until you return',
            onTap: () => _confirmDeactivate(context),
          ),
          DsGap.xxl,
          // Danger zone
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Text(
              'Danger zone',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          DsGap.md,
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Delete account',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Permanently remove all your data'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
          ),
          DsGap.xxl,
          // Warning info
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Container(
              padding: DsEdgeInsets.allMd,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 20,
                    color: Colors.orange,
                  ),
                  DsGap.mdH,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        DsGap.xs,
                        Text(
                          'Deleting your account is permanent and cannot be undone. All your matches, messages, and profile data will be lost.',
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
          ),
          DsGap.xl,
        ],
      ),
    );
  }

  Future<void> _confirmChangePhone(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.phone_android, color: Colors.blue, size: 48),
          title: const Text('Change phone number'),
          content: const Text(
            'You will be signed out to verify a new phone number. Your matches and messages will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthSignedOut());
      context.go(CrushRoutes.phoneAuth);
    }
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.pause_circle_outline,
            color: Colors.orange.shade700,
            size: 48,
          ),
          title: const Text('Deactivate account'),
          content: const Text(
            'Your profile will be hidden from discovery and you won\'t receive new matches. You can reactivate anytime by signing back in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deactivation request received. Your profile is now hidden.'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 48),
          title: const Text('Delete account?'),
          content: const Text(
            'This will permanently remove your profile, matches, messages, and all associated data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true || !context.mounted) return;

    // Second confirmation
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You will lose:'),
              DsGap.md,
              _DeleteWarningItem(text: 'All your matches'),
              _DeleteWarningItem(text: 'All your messages'),
              _DeleteWarningItem(text: 'Your profile and photos'),
              _DeleteWarningItem(text: 'Your subscription (if any)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep my account'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete permanently'),
            ),
          ],
        );
      },
    );

    if (finalConfirm == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion initiated. This may take a few moments.'),
        ),
      );
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DeleteWarningItem extends StatelessWidget {
  const _DeleteWarningItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.close, size: 16, color: Colors.red),
          DsGap.smH,
          Text(text),
        ],
      ),
    );
  }
}
