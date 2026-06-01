import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/core/utils/result.dart';
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
import 'package:crushhour/features/settings/data/commands/default_account_action_commands.dart';
import 'package:crushhour/features/settings/domain/commands/account_action_commands.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const Key accountActionsConstraintKey = ValueKey<String>(
  'account_actions_constraint',
);

class AccountActionsSettingsScreen extends StatefulWidget {
  const AccountActionsSettingsScreen({super.key});

  @override
  State<AccountActionsSettingsScreen> createState() =>
      _AccountActionsSettingsScreenState();
}

class _AccountActionsSettingsScreenState
    extends State<AccountActionsSettingsScreen> {
  static const _exportCooldownDays = 7;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.select<AuthBloc, dynamic>((bloc) => bloc.state.user);
    final phoneVerified = user?.isPhoneVerified ?? false;
    final hasPhone = user?.phoneNumber != null && user.phoneNumber.isNotEmpty;
    final isSnoozed = context.select<DiscoverySettingsCubit, bool>(
      (cubit) => !cubit.state.visible,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountActions)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            key: accountActionsConstraintKey,
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: ListView(
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
                                      l10n.accountActionsHeaderTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    DsGap.xs,
                                    Text(
                                      l10n.accountActionsHeaderSubtitle,
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
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.accountActionsSectionSecurity,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
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
                              ? l10n.accountActionsPhoneVerifiedTitle
                              : (hasPhone
                                    ? l10n.accountActionsPhoneVerifyTitle
                                    : l10n.accountActionsPhoneAddTitle),
                          subtitle: phoneVerified
                              ? l10n.accountActionsPhoneVerifiedSubtitle
                              : l10n.accountActionsPhoneVerifySubtitle,
                          trailing: phoneVerified
                              ? const Icon(
                                  Icons.lock_outline,
                                  color: DsColors.success,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(CrushRoutes.phoneProtection),
                        ),
                        const Divider(indent: 72),

                        // Change password
                        _ActionTile(
                          icon: Icons.lock_reset_outlined,
                          iconColor: DsColors.secondary,
                          title: l10n.changePassword,
                          subtitle: l10n.accountActionsChangePasswordSubtitle,
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                        const Divider(indent: 72),

                        // Account security settings
                        _ActionTile(
                          icon: Icons.shield_outlined,
                          iconColor: DsColors.accent,
                          title: l10n.accountSecurity,
                          subtitle: l10n.settingsAccountSecuritySubtitle,
                          onTap: () =>
                              context.push(CrushRoutes.securitySettings),
                        ),

                        DsGap.xxl,

                        // Account status section
                        Padding(
                          padding: DsEdgeInsets.horizontalLg,
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.accountActionsSectionAccountStatus,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
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
                          title: Text(l10n.accountActionsSnoozeProfileTitle),
                          subtitle: Text(
                            l10n.accountActionsSnoozeProfileSubtitle,
                          ),
                          value: isSnoozed,
                          onChanged: (value) async {
                            final cubit = context
                                .read<DiscoverySettingsCubit>();
                            await cubit.setVisible(!value);

                            if (!context.mounted) return;

                            // Update profile backend to sync hideFromDiscovery
                            final authUser = context
                                .read<AuthBloc>()
                                .state
                                .user;
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
                          title: l10n.settingsDeactivateAccount,
                          subtitle: l10n.accountActionsDeactivateSubtitle,
                          onTap: () => _showDeactivateFlow(context),
                        ),

                        DsGap.xxl,

                        // Data & Privacy section
                        Padding(
                          padding: DsEdgeInsets.horizontalLg,
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.accountActionsSectionDataPrivacy,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DsGap.md,

                        // Export your data (GDPR)
                        _ActionTile(
                          icon: Icons.download_outlined,
                          iconColor: DsColors.info,
                          title: l10n.accountActionsExportDataTitle,
                          subtitle: l10n.accountActionsExportDataSubtitle,
                          onTap: () => _showExportDataDialog(context),
                        ),

                        DsGap.xxl,

                        // Danger zone
                        Padding(
                          padding: DsEdgeInsets.horizontalLg,
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.accountActionsSectionDangerZone,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: DsColors.error,
                                  ),
                            ),
                          ),
                        ),
                        DsGap.md,
                        Padding(
                          padding: DsEdgeInsets.horizontalLg,
                          child: Material(
                            color: DsColors.error.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: DsColors.error.withValues(alpha: 0.2),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                MergeSemantics(
                                  child: Semantics(
                                    button: true,
                                    label:
                                        '${l10n.settingsDeleteAccount}. ${AppLocalizations.of(context).permanentlyRemoveYourAccount}',
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: DsColors.error.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_forever_outlined,
                                          color: DsColors.error,
                                          size: 22,
                                        ),
                                      ),
                                      title: Text(
                                        l10n.settingsDeleteAccount,
                                        style: const TextStyle(
                                          color: DsColors.error,
                                        ),
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
                                  ),
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
                            title: l10n.accountActionsAboutDeactivationTitle,
                            description:
                                l10n.accountActionsAboutDeactivationBody,
                            isDark: isDark,
                          ),
                        ),
                        DsGap.md,
                        Padding(
                          padding: DsEdgeInsets.horizontalLg,
                          child: _InfoBox(
                            icon: Icons.delete_forever_outlined,
                            iconColor: DsColors.error,
                            title: l10n.accountActionsAboutDeletionTitle,
                            description: l10n.accountActionsAboutDeletionBody,
                            isDark: isDark,
                          ),
                        ),
                        DsGap.xl,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExportDataDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.id.isEmpty) {
      showErrorSnackBar(this.context, l10n.accountActionsExportSignInRequired);
      return;
    }

    final email = user.email ?? l10n.accountActionsExportFallbackEmail;
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
              Text(l10n.yourExportIncludesProfilePhotos),
              DsGap.md,
              _BulletPoint(
                text: l10n.accountActionsExportItemProfileMedia,
                icon: Icons.person_outline,
              ),
              _BulletPoint(
                text: l10n.accountActionsExportItemLikesMatches,
                icon: Icons.favorite_outline,
              ),
              _BulletPoint(
                text: l10n.accountActionsExportItemMessagesMetadata,
                icon: Icons.chat_bubble_outline,
              ),
              _BulletPoint(
                text: l10n.accountActionsExportItemPreferences,
                icon: Icons.settings_outlined,
              ),
              DsGap.md,
              Text(
                l10n.accountActionsExportRateLimitNotice(_exportCooldownDays),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              DsGap.sm,
              Text(
                l10n.accountActionsExportPrimaryContact(email),
                style: Theme.of(
                  dialogContext,
                ).textTheme.bodySmall?.copyWith(color: DsColors.info),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.requestExport),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Capture repositories before async gap.
    final commands = DefaultAccountActionCommands(
      authRepository: this.context.read<AuthRepository>(),
      profileRepository: this.context.read<ProfileRepository>(),
      discoveryRepository: this.context.read<DiscoveryRepository>(),
      chatRepository: this.context.read<ChatRepository>(),
    );

    ValueNotifier<_ExportProgress>? progress;
    Future<void>? progressDialog;

    void onProgress(String status, double value) {
      if (!mounted) return;
      final nextProgress = _ExportProgress(status: status, progress: value);
      if (progress == null) {
        progress = ValueNotifier<_ExportProgress>(nextProgress);
        progressDialog = AdaptiveDialog.show<void>(
          context: this.context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return ValueListenableBuilder<_ExportProgress>(
              valueListenable: progress!,
              builder: (context, progressValue, _) {
                final pct = (progressValue.progress * 100)
                    .clamp(0, 100)
                    .round();
                return AlertDialog(
                  title: Text(l10n.preparingYourExport),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: progressValue.progress),
                      DsGap.sm,
                      Text(progressValue.status),
                      DsGap.xs,
                      Text(
                        l10n.accountActionsExportProgressPercentComplete(pct),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      } else {
        progress!.value = nextProgress;
      }
    }

    setState(() => _isLoading = true);
    final result = await commands.requestDataExport(
      user: user,
      onProgress: onProgress,
    );

    if (!mounted) {
      progress?.dispose();
      return;
    }

    setState(() => _isLoading = false);

    if (progressDialog != null &&
        Navigator.of(this.context, rootNavigator: true).canPop()) {
      Navigator.of(this.context, rootNavigator: true).pop();
    }
    if (progressDialog != null) {
      await progressDialog;
    }
    progress?.dispose();

    if (!mounted) return;

    if (result.isFailure || result.data == null) {
      showErrorSnackBar(
        this.context,
        _exportFailureMessage(l10n: l10n, failure: result.failure),
      );
      return;
    }

    final outcome = result.data!;
    if (outcome.mode == AccountDataExportMode.remoteRequestQueued) {
      showSuccessSnackBar(
        this.context,
        l10n.accountActionsExportRequestedSuccess,
      );
      return;
    }

    if (outcome.usedFallback) {
      showSuccessSnackBar(
        this.context,
        l10n.accountActionsExportCloudUnavailable,
      );
    }

    final filePath = outcome.filePath;
    if (filePath == null || filePath.trim().isEmpty) {
      showErrorSnackBar(this.context, l10n.accountActionsExportGenerateFailed);
      return;
    }

    final shareNow = await AdaptiveDialog.show<bool>(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: DsColors.success),
          title: Text(l10n.exportReady),
          content: Text(l10n.yourDataExportHasBeen),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.later),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.shareExport),
            ),
          ],
        );
      },
    );
    if (!mounted) return;

    showSuccessSnackBar(
      this.context,
      l10n.accountActionsExportCompletedNextRequest(_exportCooldownDays),
    );

    if (shareNow == true) {
      final shareResult = await commands.shareDataExport(filePath: filePath);
      if (shareResult.isFailure && mounted) {
        showErrorSnackBar(
          this.context,
          shareResult.failure?.message ??
              l10n.accountActionsExportGenerateFailed,
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
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
              title: Text(l10n.changePassword),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.accountActionsChangePasswordPrompt,
                        textAlign: TextAlign.center,
                      ),
                      DsGap.lg,
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: l10n.accountActionsCurrentPasswordLabel,
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
                            return l10n.accountActionsCurrentPasswordRequired;
                          }
                          return null;
                        },
                      ),
                      DsGap.md,
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: l10n.accountActionsNewPasswordLabel,
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
                            return l10n.accountActionsNewPasswordRequired;
                          }
                          if (value.length < 8) {
                            return l10n.accountActionsNewPasswordMinLength;
                          }
                          if (value == currentPasswordController.text) {
                            return l10n.accountActionsNewPasswordMustDiffer;
                          }
                          return null;
                        },
                      ),
                      DsGap.md,
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: l10n.accountActionsConfirmNewPasswordLabel,
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
                            return l10n
                                .accountActionsConfirmNewPasswordRequired;
                          }
                          if (value != newPasswordController.text) {
                            return l10n.accountActionsPasswordsDoNotMatch;
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
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: Text(l10n.changePassword),
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
          fallbackError: l10n.accountActionsPasswordChangeFallbackError,
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
            l10n.accountActionsPasswordChangedSuccess,
          );
          // Navigate to deck after successful password change
          if (mounted) {
            this.context.go(CrushRoutes.home);
          }
        } else {
          showErrorSnackBar(
            this.context,
            result.errorMessage ?? l10n.accountActionsPasswordChangeFailed,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          showErrorSnackBar(
            this.context,
            l10n.accountActionsGenericErrorTryAgain,
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeactivateFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    // Capture dependencies before async gaps
    final authBloc = context.read<AuthBloc>();
    final accountCommands = DefaultAccountActionCommands(
      authRepository: context.read<AuthRepository>(),
    );

    // Step 1: Ask reason
    final reason = await _showReasonDialog(
      context: context,
      title: l10n.accountActionsDeactivateReasonTitle,
      icon: Icons.pause_circle_outline,
      iconColor: DsColors.warning,
      reasons: [
        l10n.accountActionsReasonTakingBreakFromDating,
        l10n.accountActionsReasonFoundSomeoneSpecial,
        l10n.accountActionsReasonTooManyNotifications,
        l10n.accountActionsReasonNotFindingGoodMatches,
        l10n.accountActionsReasonPrivacyConcerns,
        l10n.accountActionsReasonOther,
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
          title: Text(l10n.deactivateAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.whenYouDeactivateYourAccount),
              DsGap.md,
              _BulletPoint(
                text: l10n.accountActionsDeactivateBulletHiddenFromDiscovery,
                icon: Icons.visibility_off_outlined,
              ),
              _BulletPoint(
                text: l10n.accountActionsDeactivateBulletNoNewMatches,
                icon: Icons.favorite_outline,
              ),
              _BulletPoint(
                text: l10n.accountActionsDeactivateBulletKeepMatchesMessages,
                icon: Icons.chat_bubble_outline,
              ),
              _BulletPoint(
                text: l10n.accountActionsDeactivateBulletReactivateAnytime,
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: DsColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.accountActionsDeactivateAutoDeleteWarning,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DsColors.error,
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
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: DsColors.warning),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deactivate),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      final result = await accountCommands.deactivateAccount(reason: reason);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        showSuccessSnackBar(this.context, l10n.accountActionsDeactivateSuccess);
        authBloc.add(AuthSignedOut());
        this.context.go(CrushRoutes.authGateway);
      } else {
        showErrorSnackBar(
          this.context,
          _deactivateFailureMessage(l10n: l10n, failure: result.failure),
        );
      }
    }
  }

  Future<void> _showDeleteFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    // Capture dependencies before async gaps
    final authBloc = context.read<AuthBloc>();
    final accountCommands = DefaultAccountActionCommands(
      authRepository: context.read<AuthRepository>(),
    );
    final user = authBloc.state.user;
    if (user == null) {
      showErrorSnackBar(this.context, l10n.accountActionsDeleteSignInRequired);
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
              _DeleteWarningItem(text: l10n.accountActionsDeleteWarningMatches),
              _DeleteWarningItem(
                text: l10n.accountActionsDeleteWarningMessages,
              ),
              _DeleteWarningItem(text: l10n.accountActionsDeleteWarningProfile),
              _DeleteWarningItem(
                text: l10n.accountActionsDeleteWarningSubscription,
              ),
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
                        l10n.accountActionsDeleteScheduledOn(
                          _formatDate(graceDate),
                        ),
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
      title: l10n.accountActionsDeleteReasonTitle,
      icon: Icons.insights_outlined,
      iconColor: DsColors.warning,
      reasons: [
        l10n.accountActionsReasonFoundRelationship,
        l10n.accountActionsReasonNotHappyWithApp,
        l10n.accountActionsReasonPrivacyConcerns,
        l10n.accountActionsReasonTooExpensive,
        l10n.accountActionsReasonCreatingNewAccount,
        l10n.accountActionsReasonOther,
      ],
      requiredSelection: false,
    );
    if (reason == null || !mounted) return;
    final analyticsReason = reason.trim().isEmpty
        ? l10n.accountActionsDeleteNoReasonProvided
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
                    l10n.accountActionsDeleteTypeToConfirm(confirmationValue),
                  ),
                  DsGap.sm,
                  TextField(
                    controller: usernameController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.accountActionsDeleteTypeUsernameLabel,
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                  ),
                  DsGap.md,
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.accountActionsDeletePasswordLabel,
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
                    l10n.accountActionsDeleteScheduledOn(
                      _formatDate(graceDate),
                    ),
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

      final result = await accountCommands.deleteAccount(
        password: passwordController.text,
        reason: analyticsReason,
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
          l10n.accountActionsDeleteScheduledSuccess(_formatDate(graceDate)),
        );
        authBloc.add(AuthSignedOut());
        this.context.go(CrushRoutes.authGateway);
      } else {
        showErrorSnackBar(
          this.context,
          _deleteFailureMessage(l10n: l10n, failure: result.failure),
        );
      }
    }

    usernameController.dispose();
    passwordController.dispose();
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateTimeFormatter.formatDate(date, locale: locale);
  }

  String _exportFailureMessage({
    required AppLocalizations l10n,
    required AccountActionFailure? failure,
  }) {
    if (failure == null) return l10n.accountActionsExportRequestFailed;
    switch (failure.type) {
      case AccountActionFailureType.sessionMissing:
        return l10n.accountActionsExportSignInRequired;
      case AccountActionFailureType.cooldownActive:
      case AccountActionFailureType.rateLimited:
        final nextAllowedAt = failure.nextAllowedAt;
        if (nextAllowedAt != null) {
          return l10n.accountActionsExportNextAvailableOn(
            _formatDate(nextAllowedAt),
          );
        }
        return l10n.accountActionsExportRequestFailed;
      case AccountActionFailureType.network:
        return l10n.accountActionsExportRequestFailed;
      case AccountActionFailureType.invalidCredentials:
      case AccountActionFailureType.unsupported:
      case AccountActionFailureType.unknown:
        return failure.message.trim().isNotEmpty
            ? failure.message
            : l10n.accountActionsExportRequestFailed;
    }
  }

  String _deactivateFailureMessage({
    required AppLocalizations l10n,
    required AccountActionFailure? failure,
  }) {
    if (failure == null) return l10n.accountActionsDeactivationFailed;
    switch (failure.type) {
      case AccountActionFailureType.rateLimited:
      case AccountActionFailureType.network:
      case AccountActionFailureType.cooldownActive:
        return l10n.accountActionsDeactivateFailedTryAgain;
      case AccountActionFailureType.sessionMissing:
      case AccountActionFailureType.invalidCredentials:
      case AccountActionFailureType.unsupported:
      case AccountActionFailureType.unknown:
        return failure.message.trim().isNotEmpty
            ? failure.message
            : l10n.accountActionsDeactivationFailed;
    }
  }

  String _deleteFailureMessage({
    required AppLocalizations l10n,
    required AccountActionFailure? failure,
  }) {
    if (failure == null) return l10n.accountActionsDeletionFailed;
    switch (failure.type) {
      case AccountActionFailureType.invalidCredentials:
        return l10n.accountActionsDeleteFailedCheckPassword;
      case AccountActionFailureType.sessionMissing:
        return l10n.accountActionsDeleteSignInRequired;
      case AccountActionFailureType.rateLimited:
      case AccountActionFailureType.network:
      case AccountActionFailureType.cooldownActive:
        return l10n.accountActionsDeletionFailed;
      case AccountActionFailureType.unsupported:
      case AccountActionFailureType.unknown:
        return failure.message.trim().isNotEmpty
            ? failure.message
            : l10n.accountActionsDeletionFailed;
    }
  }

  Future<String?> _showReasonDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> reasons,
    bool requiredSelection = true,
  }) async {
    final l10n = AppLocalizations.of(context);
    String? selectedReason;
    final otherController = TextEditingController();
    final otherReasonLabel = l10n.accountActionsReasonOther;

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
                        final isOther = reason == otherReasonLabel;
                        return Column(
                          children: [
                            RadioListTile<String>(
                              title: Text(reason),
                              value: reason,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            if (isOther && selectedReason == otherReasonLabel)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 16,
                                  bottom: 8,
                                ),
                                child: TextField(
                                  controller: otherController,
                                  decoration: InputDecoration(
                                    hintText:
                                        l10n.accountActionsReasonOtherHint,
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
                  child: Text(l10n.cancel),
                ),
                if (!requiredSelection)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(''),
                    child: Text(l10n.skip),
                  ),
                FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          final finalReason = selectedReason == otherReasonLabel
                              ? '${l10n.accountActionsReasonOtherPrefix}${otherController.text}'
                              : selectedReason;
                          Navigator.of(dialogContext).pop(finalReason);
                        },
                  child: Text(l10n.continueLabel),
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
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: ListTile(
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
        ),
      ),
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
          Expanded(child: Text(text)),
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
