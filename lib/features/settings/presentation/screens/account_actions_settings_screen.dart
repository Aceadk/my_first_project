import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class AccountActionsSettingsScreen extends StatefulWidget {
  const AccountActionsSettingsScreen({super.key});

  @override
  State<AccountActionsSettingsScreen> createState() =>
      _AccountActionsSettingsScreenState();
}

class _AccountActionsSettingsScreenState
    extends State<AccountActionsSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.select<AuthBloc, dynamic>((bloc) => bloc.state.user);
    final phoneVerified = user?.isPhoneVerified ?? false;
    final hasPhone =
        user?.phoneNumber != null && user.phoneNumber.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Actions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            DsGap.xs,
                            Text(
                              'Manage security, password, and account status.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Security section
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Text(
                    'Security',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DsGap.md,

                // Phone verification
                _ActionTile(
                  icon: phoneVerified
                      ? Icons.verified_outlined
                      : Icons.phone_android,
                  iconColor: phoneVerified ? Colors.green : Colors.blue,
                  title: phoneVerified
                      ? 'Phone verified'
                      : (hasPhone ? 'Verify phone number' : 'Add phone number'),
                  subtitle: phoneVerified
                      ? 'Your phone is verified and secured'
                      : 'Verify your phone for account security',
                  trailing: phoneVerified
                      ? const Icon(Icons.lock_outline, color: Colors.green)
                      : const Icon(Icons.chevron_right),
                  onTap: () => context.push(CrushRoutes.phoneProtection),
                ),
                const Divider(indent: 72),

                // Change password
                _ActionTile(
                  icon: Icons.lock_reset_outlined,
                  iconColor: Colors.indigo,
                  title: 'Change password',
                  subtitle: 'Update your account password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(indent: 72),

                // Account security settings
                _ActionTile(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.teal,
                  title: 'Account security',
                  subtitle: 'Email and phone verification settings',
                  onTap: () => context.push(CrushRoutes.securitySettings),
                ),

                DsGap.xxl,

                // Account status section
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Text(
                    'Account Status',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DsGap.md,

                // Deactivate account
                _ActionTile(
                  icon: Icons.pause_circle_outline,
                  iconColor: Colors.orange,
                  title: 'Deactivate account',
                  subtitle: 'Hide your profile temporarily',
                  onTap: () => _showDeactivateFlow(context),
                ),

                DsGap.xxl,

                // Data & Privacy section
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Text(
                    'Data & Privacy',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DsGap.md,

                // Export your data (GDPR)
                _ActionTile(
                  icon: Icons.download_outlined,
                  iconColor: Colors.blue,
                  title: 'Export your data',
                  subtitle: 'Download a copy of your personal data',
                  onTap: () => _showExportDataDialog(context),
                ),
                const Divider(indent: 72),

                // Privacy Policy
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.purple,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => context.push(CrushRoutes.privacyPolicy),
                ),
                const Divider(indent: 72),

                // Terms of Service
                _ActionTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.teal,
                  title: 'Terms of Service',
                  subtitle: 'Our terms and conditions',
                  onTap: () => context.push(CrushRoutes.termsOfService),
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
                          subtitle:
                              const Text('Permanently remove your account'),
                          trailing:
                              const Icon(Icons.chevron_right, color: Colors.red),
                          onTap: () => _showDeleteFlow(context),
                        ),
                      ],
                    ),
                  ),
                ),
                DsGap.xxl,

                // Info boxes
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: _InfoBox(
                    icon: Icons.pause_circle_outline,
                    iconColor: Colors.orange,
                    title: 'About Deactivation',
                    description:
                        'When you deactivate your account, your profile will be hidden. '
                        'You can reactivate anytime by signing back in. '
                        'If you don\'t sign in for 6 months, your account will be permanently deleted.',
                    isDark: isDark,
                  ),
                ),
                DsGap.md,
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: _InfoBox(
                    icon: Icons.delete_forever_outlined,
                    iconColor: Colors.red,
                    title: 'About Deletion',
                    description:
                        'When you delete your account, you have 14 days to change your mind. '
                        'Simply sign in within 14 days to recover your account. '
                        'After 14 days, all your data will be permanently deleted.',
                    isDark: isDark,
                  ),
                ),
                DsGap.xl,
              ],
            ),
    );
  }

  Future<void> _showExportDataDialog(BuildContext context) async {
    final user = context.read<AuthBloc>().state.user;
    final email = user?.email ?? 'your email';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.download_outlined, color: Colors.blue, size: 48),
          title: const Text('Export Your Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can request a copy of all your personal data. This includes:',
              ),
              DsGap.md,
              const _BulletPoint(
                text: 'Your profile information',
                icon: Icons.person_outline,
              ),
              const _BulletPoint(
                text: 'Your photos and media',
                icon: Icons.photo_library_outlined,
              ),
              const _BulletPoint(
                text: 'Your matches and connections',
                icon: Icons.favorite_outline,
              ),
              const _BulletPoint(
                text: 'Your messages',
                icon: Icons.chat_bubble_outline,
              ),
              const _BulletPoint(
                text: 'Your preferences and settings',
                icon: Icons.settings_outlined,
              ),
              DsGap.lg,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your data will be prepared and sent to $email within 48 hours.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Request Export'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      // Simulate API call to request data export
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() => _isLoading = false);

      showSuccessSnackBar(
        this.context,
        'Data export requested! You will receive an email at $email within 48 hours.',
      );
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    // Capture repository before async gap
    final authRepository = context.read<AuthRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.lock_reset_outlined,
                  color: Colors.indigo, size: 48),
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter your current password and choose a new one.',
                        textAlign: TextAlign.center,
                      ),
                      DsGap.lg,
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setDialogState(
                                () => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your current password';
                          }
                          return null;
                        },
                      ),
                      DsGap.md,
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (value == currentPasswordController.text) {
                            return 'New password must be different from current password';
                          }
                          return null;
                        },
                      ),
                      DsGap.md,
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setDialogState(
                                () => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your new password';
                          }
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final result = await Result.guard(
          () => authRepository.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              ),
          logLabel: 'AuthRepository.changePassword',
          fallbackError: 'Could not change password. Please try again.',
        );

        if (!mounted) {
          currentPasswordController.dispose();
          newPasswordController.dispose();
          confirmPasswordController.dispose();
          return;
        }
        setState(() => _isLoading = false);

        if (result.isSuccess) {
          showSuccessSnackBar(
            this.context,
            'Password changed successfully!',
          );
          // Navigate to deck after successful password change
          if (mounted) {
            this.context.go(CrushRoutes.home);
          }
        } else {
          showErrorSnackBar(
              this.context, result.errorMessage ?? 'Password change failed.');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          showErrorSnackBar(this.context, 'An error occurred. Please try again.');
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeactivateFlow(BuildContext context) async {
    // Capture dependencies before async gaps
    final authRepository = context.read<AuthRepository>();
    final authBloc = context.read<AuthBloc>();

    // Step 1: Ask reason
    final reason = await _showReasonDialog(
      context: context,
      title: 'Why are you leaving?',
      icon: Icons.pause_circle_outline,
      iconColor: Colors.orange,
      reasons: const [
        'Taking a break from dating',
        'Found someone special',
        'Too many notifications',
        'Not finding good matches',
        'Privacy concerns',
        'Other reason',
      ],
    );

    if (reason == null || !mounted) return;

    // Step 2: Confirm with warning about 6-month deletion
    final confirmed = await showDialog<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.pause_circle_outline,
            color: Colors.orange.shade700,
            size: 48,
          ),
          title: const Text('Deactivate Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When you deactivate your account:',
              ),
              DsGap.md,
              const _BulletPoint(
                text: 'Your profile will be hidden from discovery',
                icon: Icons.visibility_off_outlined,
              ),
              const _BulletPoint(
                text: 'You won\'t receive new matches',
                icon: Icons.favorite_outline,
              ),
              const _BulletPoint(
                text: 'Your existing matches and messages are preserved',
                icon: Icons.chat_bubble_outline,
              ),
              const _BulletPoint(
                text: 'You can reactivate anytime by signing in',
                icon: Icons.login_outlined,
              ),
              DsGap.md,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If you don\'t sign in for 6 months, your account will be permanently deleted.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      final result = await Result.guard(
        () => authRepository.deactivateAccount(reason: reason),
        logLabel: 'AuthRepository.deactivateAccount',
        fallbackError: 'Could not deactivate account. Please try again.',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        showSuccessSnackBar(
          this.context,
          'Your account has been deactivated. Sign in anytime to reactivate.',
        );
        authBloc.add(AuthSignedOut());
        this.context.go(CrushRoutes.authGateway);
      } else {
        showErrorSnackBar(
            this.context, result.errorMessage ?? 'Deactivation failed.');
      }
    }
  }

  Future<void> _showDeleteFlow(BuildContext context) async {
    // Capture dependencies before async gaps
    final authRepository = context.read<AuthRepository>();
    final authBloc = context.read<AuthBloc>();

    // Step 1: Ask reason
    final reason = await _showReasonDialog(
      context: context,
      title: 'Why are you deleting your account?',
      icon: Icons.delete_forever_outlined,
      iconColor: Colors.red,
      reasons: const [
        'Found a relationship',
        'Not happy with the app',
        'Privacy concerns',
        'Too expensive',
        'Creating a new account',
        'Other reason',
      ],
    );

    if (reason == null || !mounted) return;

    // Step 2: Show what they'll lose
    final firstConfirm = await showDialog<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_forever_outlined,
              color: Colors.red, size: 48),
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You will lose:'),
              DsGap.md,
              const _DeleteWarningItem(text: 'All your matches'),
              const _DeleteWarningItem(text: 'All your messages'),
              const _DeleteWarningItem(text: 'Your profile and photos'),
              const _DeleteWarningItem(text: 'Your subscription (if any)'),
              DsGap.md,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have 14 days to change your mind. Simply sign in within 14 days to recover your account.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true || !mounted) return;

    // Step 3: Password confirmation
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    final passwordConfirmed = await showDialog<bool>(
      context: this.context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.lock_outline, color: Colors.red, size: 48),
              title: const Text('Confirm Your Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'To delete your account, please enter your password.',
                    textAlign: TextAlign.center,
                  ),
                  DsGap.lg,
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                ],
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
                  onPressed: () {
                    if (passwordController.text.isNotEmpty) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );

    if (passwordConfirmed == true && mounted) {
      setState(() => _isLoading = true);

      final result = await Result.guard(
        () => authRepository.deleteAccount(
              password: passwordController.text,
              reason: reason,
            ),
        logLabel: 'AuthRepository.deleteAccount',
        fallbackError: 'Could not delete account. Please check your password.',
      );

      if (!mounted) {
        passwordController.dispose();
        return;
      }
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        showSuccessSnackBar(
          this.context,
          'Your account is scheduled for deletion. Sign in within 14 days to recover it.',
        );
        authBloc.add(AuthSignedOut());
        this.context.go(CrushRoutes.authGateway);
      } else {
        showErrorSnackBar(this.context, result.errorMessage ?? 'Deletion failed.');
      }
    }

    passwordController.dispose();
  }

  Future<String?> _showReasonDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> reasons,
  }) async {
    String? selectedReason;
    final otherController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: Icon(icon, color: iconColor, size: 48),
              title: Text(title),
              content: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() => selectedReason = value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...reasons.map((reason) {
                        final isOther = reason == 'Other reason';
                        return Column(
                          children: [
                            RadioListTile<String>(
                              title: Text(reason),
                              value: reason,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            if (isOther && selectedReason == 'Other reason')
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, bottom: 8),
                                child: TextField(
                                  controller: otherController,
                                  decoration: const InputDecoration(
                                    hintText: 'Please tell us more...',
                                    isDense: true,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          final finalReason = selectedReason == 'Other reason'
                              ? 'Other: ${otherController.text}'
                              : selectedReason;
                          Navigator.of(dialogContext).pop(finalReason);
                        },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    otherController.dispose();
    return result;
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

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
      trailing: trailing ?? const Icon(Icons.chevron_right),
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

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DsEdgeInsets.allMd,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          DsGap.mdH,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                ),
                DsGap.xs,
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
