import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/services/data_export_request_service.dart';
import 'package:crushhour/core/services/data_export_service.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/adaptive_dialog.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountActionsSettingsScreen extends StatefulWidget {
  const AccountActionsSettingsScreen({super.key});

  @override
  State<AccountActionsSettingsScreen> createState() =>
      _AccountActionsSettingsScreenState();
}

class _AccountActionsSettingsScreenState
    extends State<AccountActionsSettingsScreen> {
  static const _lastExportRequestedAtKey = 'settings_last_export_request_at';
  static const _exportCooldownDays = 7;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.select<AuthBloc, dynamic>((bloc) => bloc.state.user);
    final phoneVerified = user?.isPhoneVerified ?? false;
    final hasPhone = user?.phoneNumber != null && user.phoneNumber.isNotEmpty;
    final isSnoozed = context.select<DiscoverySettingsCubit, bool>(
      (cubit) => !cubit.state.visible,
    );

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).accountActions)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: _isLoading
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
                              DsColors.secondary.withValues(alpha: 0.1),
                              DsColors.secondary.withValues(alpha: 0.1),
                            ],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: DsEdgeInsets.allMd,
                              decoration: BoxDecoration(
                                color: DsColors.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.manage_accounts_outlined,
                                color: DsColors.secondary,
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  DsGap.xs,
                                  Text(
                                    'Manage security, password, and account status.',
                                    style: Theme.of(context).textTheme.bodySmall
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DsGap.md,

                      // Phone verification
                      _ActionTile(
                        icon: phoneVerified
                            ? Icons.verified_outlined
                            : Icons.phone_android,
                        iconColor: phoneVerified
                            ? DsColors.success
                            : DsColors.info,
                        title: phoneVerified
                            ? 'Phone verified'
                            : (hasPhone
                                  ? 'Verify phone number'
                                  : 'Add phone number'),
                        subtitle: phoneVerified
                            ? 'Your phone is verified and secured'
                            : 'Verify your phone for account security',
                        trailing: phoneVerified
                            ? const Icon(
                                Icons.lock_outline,
                                color: DsColors.success,
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => context.push(CrushRoutes.phoneProtection),
                      ),
                      const Divider(indent: 72),

                      // Change password
                      _ActionTile(
                        icon: Icons.lock_reset_outlined,
                        iconColor: DsColors.secondary,
                        title: 'Change password',
                        subtitle: 'Update your account password',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const Divider(indent: 72),

                      // Account security settings
                      _ActionTile(
                        icon: Icons.shield_outlined,
                        iconColor: DsColors.accent,
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DsGap.md,

                      // Snooze profile (Pause from discovery)
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DsColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bedtime_outlined,
                            color: DsColors.primary,
                            size: 22,
                          ),
                        ),
                        title: const Text('Snooze profile'),
                        subtitle: const Text(
                          'Hide profile but keep messaging active matches',
                        ),
                        value: isSnoozed,
                        onChanged: (value) async {
                          final cubit = context.read<DiscoverySettingsCubit>();
                          await cubit.setVisible(!value);

                          if (!context.mounted) return;

                          // Update profile backend to sync hideFromDiscovery
                          final authUser = context.read<AuthBloc>().state.user;
                          if (authUser != null && authUser.profile != null) {
                            final prefs = authUser.profile!.preferences
                                .copyWith(hideFromDiscovery: value);
                            final updatedProfile = authUser.profile!.copyWith(
                              preferences: prefs,
                            );
                            context.read<ProfileBloc>().add(
                              ProfileSaveRequested(profile: updatedProfile),
                            );
                          }
                        },
                      ),
                      const Divider(indent: 72),

                      // Deactivate account
                      _ActionTile(
                        icon: Icons.pause_circle_outline,
                        iconColor: DsColors.warning,
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DsGap.md,

                      // Export your data (GDPR)
                      _ActionTile(
                        icon: Icons.download_outlined,
                        iconColor: DsColors.info,
                        title: 'Export your data',
                        subtitle: 'Download a copy of your personal data',
                        onTap: () => _showExportDataDialog(context),
                      ),

                      DsGap.xxl,

                      // Danger zone
                      Padding(
                        padding: DsEdgeInsets.horizontalLg,
                        child: Text(
                          'Danger zone',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DsColors.error,
                              ),
                        ),
                      ),
                      DsGap.md,
                      Padding(
                        padding: DsEdgeInsets.horizontalLg,
                        child: Container(
                          decoration: BoxDecoration(
                            color: DsColors.error.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DsColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: DsColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.delete_forever_outlined,
                                    color: DsColors.error,
                                    size: 22,
                                  ),
                                ),
                                title: const Text(
                                  'Delete account',
                                  style: TextStyle(color: DsColors.error),
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).permanentlyRemoveYourAccount,
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: DsColors.error,
                                ),
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
                          iconColor: DsColors.warning,
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
                          iconColor: DsColors.error,
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
          ),
        ),
      ),
    );
  }

  Future<void> _showExportDataDialog(BuildContext context) async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.id.isEmpty) {
      showErrorSnackBar(this.context, 'Please sign in again to export data.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final now = DateTime.now();
    final lastRequestMs = prefs.getInt(_lastExportRequestedAtKey);
    if (lastRequestMs != null) {
      final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestMs);
      final nextAllowed = lastRequest.add(
        const Duration(days: _exportCooldownDays),
      );
      if (now.isBefore(nextAllowed)) {
        showErrorSnackBar(
          this.context,
          'You can request your next export on ${_formatDate(nextAllowed)}.',
        );
        return;
      }
    }

    final email = user.email ?? 'your email';
    final confirmed = await AdaptiveDialog.show<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.download_outlined,
            color: DsColors.info,
            size: 48,
          ),
          title: Text(AppLocalizations.of(context).requestDataExport),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).yourExportIncludesProfilePhotos,
              ),
              DsGap.md,
              const _BulletPoint(
                text: 'Profile, photos, and media',
                icon: Icons.person_outline,
              ),
              const _BulletPoint(
                text: 'Likes and matches',
                icon: Icons.favorite_outline,
              ),
              const _BulletPoint(
                text: 'Messages and chat metadata',
                icon: Icons.chat_bubble_outline,
              ),
              const _BulletPoint(
                text: 'Preferences and account settings',
                icon: Icons.settings_outlined,
              ),
              DsGap.md,
              Text(
                'This request is rate-limited to once every $_exportCooldownDays days. We will notify you when export generation completes.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              DsGap.sm,
              Text(
                'Primary contact: $email',
                style: Theme.of(
                  dialogContext,
                ).textTheme.bodySmall?.copyWith(color: DsColors.info),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context).requestExport),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final exportRequestService = DataExportRequestService();
    final requestResult = await exportRequestService.requestExport();
    if (!mounted) return;

    if (requestResult.isSuccess) {
      await prefs.setInt(_lastExportRequestedAtKey, now.millisecondsSinceEpoch);
      if (!mounted) return;
      showSuccessSnackBar(
        this.context,
        'Data export requested. We will send a push notification when it is ready.',
      );
      return;
    }

    final shouldFallbackToLocal = switch (requestResult.code) {
      'not-found' => true,
      'unimplemented' => true,
      'unavailable' => true,
      _ => false,
    };

    if (!shouldFallbackToLocal) {
      final maybeDate = DateTime.tryParse(requestResult.nextAllowedAtIso ?? '');
      if (maybeDate != null) {
        showErrorSnackBar(
          this.context,
          'You can request your next export on ${_formatDate(maybeDate)}.',
        );
        return;
      }
      showErrorSnackBar(
        this.context,
        requestResult.message ?? 'Could not request data export.',
      );
      return;
    }

    showSuccessSnackBar(
      this.context,
      'Cloud export is not available in this environment. Generating local export now.',
    );

    final profileRepository = this.context.read<ProfileRepository>();
    final discoveryRepository = this.context.read<DiscoveryRepository>();
    final chatRepository = this.context.read<ChatRepository>();
    final fallbackProfile = user.profile;

    final progress = ValueNotifier<_ExportProgress>(
      const _ExportProgress(status: 'Starting export...', progress: 0),
    );

    final progressDialog = AdaptiveDialog.show<void>(
      context: this.context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ValueListenableBuilder<_ExportProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            final pct = (value.progress * 100).clamp(0, 100).round();
            return AlertDialog(
              title: Text(AppLocalizations.of(context).preparingYourExport),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: value.progress),
                  DsGap.sm,
                  Text(value.status),
                  DsGap.xs,
                  Text(
                    '$pct% complete',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    setState(() => _isLoading = true);

    final exportService = DataExportService(
      currentUserId: user.id,
      getUserData: () async => user,
      getProfileData: () async {
        final refreshedUser = await profileRepository.getCurrentUser();
        return refreshedUser?.profile ?? fallbackProfile;
      },
      getMatchesData: () => discoveryRepository.fetchMatches(user.id),
      getLikesData: () => discoveryRepository.fetchLikesYou(user.id),
      getMessagesData: () =>
          _collectAllMessages(chatRepository: chatRepository, userId: user.id),
      getPreferencesData: () async {
        final refreshedUser = await profileRepository.getCurrentUser();
        final profile = refreshedUser?.profile ?? fallbackProfile;
        return profile?.preferences;
      },
    );

    final result = await exportService.exportData(
      onProgress: (status, value) {
        progress.value = _ExportProgress(status: status, progress: value);
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (Navigator.of(this.context, rootNavigator: true).canPop()) {
        Navigator.of(this.context, rootNavigator: true).pop();
      }
    }
    await progressDialog;

    if (!mounted) return;

    if (!result.isSuccess || result.filePath == null) {
      showErrorSnackBar(
        this.context,
        result.error ?? 'Could not generate data export. Please try again.',
      );
      return;
    }

    await prefs.setInt(_lastExportRequestedAtKey, now.millisecondsSinceEpoch);
    if (!mounted) return;

    final shareNow = await AdaptiveDialog.show<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: DsColors.success),
          title: Text(AppLocalizations.of(context).exportReady),
          content: Text(AppLocalizations.of(context).yourDataExportHasBeen),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).later),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context).shareExport),
            ),
          ],
        );
      },
    );
    if (!mounted) return;

    showSuccessSnackBar(
      this.context,
      'Data export request completed. Next request available in $_exportCooldownDays days.',
    );

    if (shareNow == true) {
      await exportService.shareExport(result.filePath!);
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

    final confirmed = await AdaptiveDialog.show<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(
                Icons.lock_reset_outlined,
                color: DsColors.secondary,
                size: 48,
              ),
              title: Text(AppLocalizations.of(context).changePassword),
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
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent,
                            ),
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
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
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
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
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
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: Text(AppLocalizations.of(context).changePassword),
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
          showSuccessSnackBar(this.context, 'Password changed successfully!');
          // Navigate to deck after successful password change
          if (mounted) {
            this.context.go(CrushRoutes.home);
          }
        } else {
          showErrorSnackBar(
            this.context,
            result.errorMessage ?? 'Password change failed.',
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          showErrorSnackBar(
            this.context,
            'An error occurred. Please try again.',
          );
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
      iconColor: DsColors.warning,
      reasons: [
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
    final confirmed = await AdaptiveDialog.show<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.pause_circle_outline,
            color: DsColors.warning,
            size: 48,
          ),
          title: Text(AppLocalizations.of(context).deactivateAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).whenYouDeactivateYourAccount),
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
                  color: DsColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DsColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: DsColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If you don\'t sign in for 6 months, your account will be permanently deleted.',
                        style: TextStyle(fontSize: 12, color: DsColors.error),
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: DsColors.warning),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context).deactivate),
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
          this.context,
          result.errorMessage ?? 'Deactivation failed.',
        );
      }
    }
  }

  Future<void> _showDeleteFlow(BuildContext context) async {
    // Capture dependencies before async gaps
    final authRepository = context.read<AuthRepository>();
    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state.user;
    if (user == null) {
      showErrorSnackBar(this.context, 'Please sign in again to continue.');
      return;
    }
    final confirmationValue = (user.username?.trim().isNotEmpty ?? false)
        ? user.username!.trim()
        : (user.email?.split('@').first ?? user.id);
    final graceDate = DateTime.now().add(const Duration(days: 14));

    // Step 1: Explain what will be deleted.
    final firstConfirm = await AdaptiveDialog.show<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_forever_outlined,
            color: DsColors.error,
            size: 48,
          ),
          title: Text(AppLocalizations.of(context).deleteAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).youWillLose),
              DsGap.md,
              const _DeleteWarningItem(text: 'All your matches'),
              const _DeleteWarningItem(text: 'All your messages'),
              const _DeleteWarningItem(text: 'Your profile and photos'),
              const _DeleteWarningItem(text: 'Your subscription (if any)'),
              DsGap.md,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DsColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DsColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: DsColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deleted on ${_formatDate(graceDate)}. Sign back in within 14 days to cancel.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DsColors.success,
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: DsColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context).continueLabel),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true || !mounted) return;

    // Step 2: Offer data export before deletion.
    final downloadChoice = await AdaptiveDialog.show<_DeleteDownloadChoice>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.download_outlined, color: DsColors.info),
          title: Text(AppLocalizations.of(context).downloadYourDataFirst),
          content: Text(
            AppLocalizations.of(context).beforeDeletionYouCanRequest,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_DeleteDownloadChoice.cancel),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_DeleteDownloadChoice.continueDelete),
              child: Text(AppLocalizations.of(context).skip),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_DeleteDownloadChoice.requestExport),
              child: Text(AppLocalizations.of(context).requestExport),
            ),
          ],
        );
      },
    );
    if (downloadChoice == null ||
        downloadChoice == _DeleteDownloadChoice.cancel ||
        !mounted) {
      return;
    }
    if (downloadChoice == _DeleteDownloadChoice.requestExport) {
      await _showExportDataDialog(this.context);
      if (!mounted) return;
    }

    // Step 3: Optional reason selector for analytics.
    final reason = await _showReasonDialog(
      context: this.context,
      title: 'Optional: Why are you deleting your account?',
      icon: Icons.insights_outlined,
      iconColor: DsColors.warning,
      reasons: [
        'Found a relationship',
        'Not happy with the app',
        'Privacy concerns',
        'Too expensive',
        'Creating a new account',
        'Other reason',
      ],
      requiredSelection: false,
    );
    if (reason == null || !mounted) return;
    final analyticsReason = reason.trim().isEmpty
        ? 'No reason provided'
        : reason.trim();

    // Step 4: Type-to-confirm + password.
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    final confirmed = await AdaptiveDialog.show<bool>(
      context: this.context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final typedCorrectly =
                usernameController.text.trim() == confirmationValue;
            final hasPassword = passwordController.text.trim().isNotEmpty;
            return AlertDialog(
              icon: const Icon(
                Icons.warning_amber_outlined,
                color: DsColors.error,
                size: 42,
              ),
              title: Text(AppLocalizations.of(context).finalConfirmation),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type "$confirmationValue" to confirm account deletion.',
                  ),
                  DsGap.sm,
                  TextField(
                    controller: usernameController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Type username',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  DsGap.md,
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  DsGap.md,
                  Text(
                    'Deleted on ${_formatDate(graceDate)}. Sign back in within 14 days to cancel.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DsColors.warning),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DsColors.error,
                  ),
                  onPressed: typedCorrectly && hasPassword
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(AppLocalizations.of(context).deleteAccount),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      final result = await Result.guard(
        () => authRepository.deleteAccount(
          password: passwordController.text,
          reason: analyticsReason,
        ),
        logLabel: 'AuthRepository.deleteAccount',
        fallbackError: 'Could not delete account. Please check your password.',
      );

      if (!mounted) {
        usernameController.dispose();
        passwordController.dispose();
        return;
      }
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        showSuccessSnackBar(
          this.context,
          'Your account is scheduled for deletion on ${_formatDate(graceDate)}. Sign in within 14 days to recover it.',
        );
        authBloc.add(AuthSignedOut());
        this.context.go(CrushRoutes.authGateway);
      } else {
        showErrorSnackBar(
          this.context,
          result.errorMessage ?? 'Deletion failed.',
        );
      }
    }

    usernameController.dispose();
    passwordController.dispose();
  }

  Future<List<Message>> _collectAllMessages({
    required ChatRepository chatRepository,
    required String userId,
  }) async {
    final allMessages = <Message>[];
    final matches = await chatRepository.fetchUserMatches(userId);

    for (final match in matches) {
      DateTime? cursor;
      bool hasMore = true;

      while (hasMore) {
        final page = await chatRepository.fetchMessagesPaginated(
          match.id,
          limit: 100,
          beforeTimestamp: cursor,
        );

        if (page.items.isEmpty) break;
        allMessages.addAll(page.items);

        final nextCursor = page.items.last.sentAt;
        if (!page.hasMore || (cursor != null && !nextCursor.isBefore(cursor))) {
          hasMore = false;
        } else {
          cursor = nextCursor;
        }
      }
    }

    return allMessages;
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateTimeFormatter.formatDate(date, locale: locale);
  }

  Future<String?> _showReasonDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> reasons,
    bool requiredSelection = true,
  }) async {
    String? selectedReason;
    final otherController = TextEditingController();

    final result = await AdaptiveDialog.show<String>(
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
                                padding: const EdgeInsetsDirectional.only(
                                  start: 16,
                                  bottom: 8,
                                ),
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
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                if (!requiredSelection)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(''),
                    child: Text(AppLocalizations.of(context).skip),
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
                  child: Text(AppLocalizations.of(context).continueLabel),
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

enum _DeleteDownloadChoice { cancel, continueDelete, requestExport }

class _ExportProgress {
  const _ExportProgress({required this.status, required this.progress});

  final String status;
  final double progress;
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
          const Icon(Icons.close, size: 16, color: DsColors.error),
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
          Icon(icon, size: 16, color: DsColors.warning),
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
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
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
