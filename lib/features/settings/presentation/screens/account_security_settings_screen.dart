import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/linked_accounts_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class AccountSecuritySettingsScreen extends StatefulWidget {
  const AccountSecuritySettingsScreen({super.key});

  @override
  State<AccountSecuritySettingsScreen> createState() =>
      _AccountSecuritySettingsScreenState();
}

class _AccountSecuritySettingsScreenState
    extends State<AccountSecuritySettingsScreen> {
  Set<String> _linkedProviderIds = const <String>{};
  bool _isLoadingLinkedProviders = true;
  String? _busyProviderId;

  LinkedAccountsRepository? _linkedRepo() {
    final authRepository = context.read<AuthRepository>();
    if (authRepository is LinkedAccountsRepository) {
      return authRepository as LinkedAccountsRepository;
    }
    return null;
  }

  bool _isLinked(LinkedAuthProvider provider) {
    return _linkedProviderIds.contains(provider.providerId);
  }

  @override
  void initState() {
    super.initState();
    _refreshLinkedProviders();
  }

  Future<void> _refreshLinkedProviders() async {
    final repo = _linkedRepo();
    if (repo == null) {
      if (!mounted) return;
      setState(() {
        _linkedProviderIds = const <String>{};
        _isLoadingLinkedProviders = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingLinkedProviders = true);

    try {
      final linked = await repo.getLinkedProviderIds();
      if (!mounted) return;
      setState(() {
        _linkedProviderIds = linked;
        _isLoadingLinkedProviders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLinkedProviders = false);
    }
  }

  Future<void> _handleLinkProvider(LinkedAuthProvider provider) async {
    final repo = _linkedRepo();
    if (repo == null) {
      _showSnack('${provider.displayName} linking is not available.');
      return;
    }

    if (_busyProviderId != null) return;
    setState(() => _busyProviderId = provider.providerId);

    try {
      await repo.linkProvider(provider);
      await _refreshLinkedProviders();
      if (!mounted) return;
      _showSnack('${provider.displayName} linked successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_friendlyLinkingError(error.toString(), provider.displayName));
    } finally {
      if (mounted) {
        setState(() => _busyProviderId = null);
      }
    }
  }

  Future<void> _handleUnlinkProvider(
    LinkedAuthProvider provider, {
    required int linkedRecoveryCount,
  }) async {
    if (linkedRecoveryCount <= 1) {
      _showSnack(
        'Cannot unlink the last recovery method. Add another provider first.',
      );
      return;
    }

    final repo = _linkedRepo();
    if (repo == null) {
      _showSnack('${provider.displayName} unlink is not available.');
      return;
    }

    if (_busyProviderId != null) return;
    setState(() => _busyProviderId = provider.providerId);

    try {
      await repo.unlinkProvider(provider);
      await _refreshLinkedProviders();
      if (!mounted) return;
      _showSnack('${provider.displayName} unlinked successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_friendlyLinkingError(error.toString(), provider.displayName));
    } finally {
      if (mounted) {
        setState(() => _busyProviderId = null);
      }
    }
  }

  String _friendlyLinkingError(String raw, String providerName) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('already linked')) {
      return '$providerName is already linked.';
    }
    if (normalized.contains('credential-already-in-use')) {
      return '$providerName is already linked to another account.';
    }
    if (normalized.contains('operation-not-allowed')) {
      return '$providerName is not enabled for this environment.';
    }
    if (normalized.contains('cancel')) {
      return '$providerName linking was canceled.';
    }
    final message = raw.replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Could not update linked account.' : message;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentEmail = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.email,
    );
    final emailVerified = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.user?.isEmailVerified ?? false,
    );
    final hasEmail = currentEmail != null && currentEmail.isNotEmpty;

    final currentPhone = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.phoneNumber,
    );
    final phoneVerified = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.user?.isPhoneVerified ?? false,
    );
    final hasPhone = currentPhone != null && currentPhone.isNotEmpty;
    final googleLinked = _isLinked(LinkedAuthProvider.google);
    final appleLinked = _isLinked(LinkedAuthProvider.apple);
    final linkedRecoveryCount = [
      hasEmail,
      hasPhone,
      googleLinked,
      appleLinked,
    ].where((v) => v).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Security')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: ListView(
              children: [
                // Header
                Container(
                  padding: DsEdgeInsets.allLg,
                  margin: DsEdgeInsets.allLg,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DsColors.success.withValues(alpha: 0.1),
                        DsColors.accent.withValues(alpha: 0.1),
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
                          color: DsColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: DsColors.success,
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            DsGap.xs,
                            Text(
                              'Add extra layers of security to keep your account safe.',
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
                // Email status card
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Container(
                    padding: DsEdgeInsets.allMd,
                    decoration: BoxDecoration(
                      color: hasEmail
                          ? (emailVerified
                                ? DsColors.success.withValues(alpha: 0.1)
                                : DsColors.warning.withValues(alpha: 0.1))
                          : DsColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasEmail
                            ? (emailVerified
                                  ? DsColors.success.withValues(alpha: 0.3)
                                  : DsColors.warning.withValues(alpha: 0.3))
                            : DsColors.error.withValues(alpha: 0.3),
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
                              ? (emailVerified
                                    ? DsColors.success
                                    : DsColors.warning)
                              : DsColors.error,
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: hasEmail
                                          ? (emailVerified
                                                ? DsColors.success
                                                : DsColors.warning)
                                          : DsColors.error,
                                    ),
                              ),
                              if (hasEmail) ...[
                                DsGap.xs,
                                Text(
                                  currentEmail,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? DsColors.textMutedDark
                                            : DsColors.textMutedLight,
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
                DsGap.md,
                // Phone status card
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Container(
                    padding: DsEdgeInsets.allMd,
                    decoration: BoxDecoration(
                      color: hasPhone
                          ? (phoneVerified
                                ? DsColors.success.withValues(alpha: 0.1)
                                : DsColors.warning.withValues(alpha: 0.1))
                          : DsColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasPhone
                            ? (phoneVerified
                                  ? DsColors.success.withValues(alpha: 0.3)
                                  : DsColors.warning.withValues(alpha: 0.3))
                            : DsColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasPhone
                              ? (phoneVerified
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_outlined)
                              : Icons.error_outline,
                          color: hasPhone
                              ? (phoneVerified
                                    ? DsColors.success
                                    : DsColors.warning)
                              : DsColors.error,
                        ),
                        DsGap.mdH,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasPhone
                                    ? (phoneVerified
                                          ? 'Phone verified'
                                          : 'Phone not verified')
                                    : 'No phone added',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: hasPhone
                                          ? (phoneVerified
                                                ? DsColors.success
                                                : DsColors.warning)
                                          : DsColors.error,
                                    ),
                              ),
                              if (hasPhone) ...[
                                DsGap.xs,
                                Text(
                                  _maskPhoneNumber(currentPhone),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? DsColors.textMutedDark
                                            : DsColors.textMutedLight,
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
                  icon: emailVerified
                      ? Icons.verified_outlined
                      : Icons.email_outlined,
                  iconColor: emailVerified ? DsColors.success : DsColors.info,
                  title: emailVerified
                      ? 'Email protection (Locked)'
                      : 'Email protection',
                  subtitle: hasEmail
                      ? (emailVerified
                            ? 'Verified and locked'
                            : 'Verify your email')
                      : 'Add an email for recovery and OTP',
                  locked: emailVerified,
                  onTap: () => context.push(CrushRoutes.emailProtection),
                ),
                _SecurityTile(
                  icon: phoneVerified
                      ? Icons.verified_outlined
                      : Icons.phone_outlined,
                  iconColor: phoneVerified ? DsColors.success : DsColors.info,
                  title: phoneVerified
                      ? 'Phone protection (Locked)'
                      : 'Phone protection',
                  subtitle: hasPhone
                      ? (phoneVerified
                            ? 'Verified and locked'
                            : 'Verify your phone')
                      : 'Add a phone number for security',
                  locked: phoneVerified,
                  onTap: () => context.push(CrushRoutes.phoneProtection),
                ),
                // Biometric authentication toggle
                BlocConsumer<BiometricCubit, BiometricState>(
                  listenWhen: (previous, current) =>
                      previous.errorMessage != current.errorMessage &&
                      current.errorMessage != null &&
                      current.errorMessage!.isNotEmpty,
                  listener: (context, state) {
                    final message = state.errorMessage;
                    if (message != null && message.isNotEmpty) {
                      _showSnack(message);
                    }
                  },
                  builder: (context, biometricState) {
                    // Only show if device supports biometrics
                    if (biometricState.status == BiometricStatus.unavailable) {
                      return const SizedBox.shrink();
                    }

                    final isEnabled =
                        biometricState.status != BiometricStatus.disabled &&
                        biometricState.status != BiometricStatus.initial &&
                        biometricState.status != BiometricStatus.checking &&
                        biometricState.status != BiometricStatus.unavailable;

                    return _SecurityTile(
                      icon: biometricState.biometricTypeName == 'Face ID'
                          ? Icons.face
                          : Icons.fingerprint,
                      iconColor: isEnabled ? DsColors.success : DsColors.info,
                      title: '${biometricState.biometricTypeName} Lock',
                      subtitle: isEnabled
                          ? 'Unlock Crush with ${biometricState.biometricTypeName}'
                          : 'Require ${biometricState.biometricTypeName} to open Crush',
                      trailing: Switch.adaptive(
                        value: isEnabled,
                        activeTrackColor: DsColors.primary,
                        onChanged: (value) {
                          if (value) {
                            context.read<BiometricCubit>().enable();
                          } else {
                            context.read<BiometricCubit>().disable();
                          }
                        },
                      ),
                    );
                  },
                ),
                DsGap.lg,
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Text(
                    'Linked Accounts',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DsGap.sm,
                _LinkedAccountTile(
                  icon: Icons.email_outlined,
                  provider: 'Email',
                  status: hasEmail
                      ? (emailVerified
                            ? 'Linked · Verified'
                            : 'Linked · Unverified')
                      : 'Not linked',
                  isLinked: hasEmail,
                  actionLabel: hasEmail ? 'Manage' : 'Link',
                  onAction: () {
                    if (hasEmail) {
                      context.push(CrushRoutes.emailProtection);
                      return;
                    }
                    _showSnack('Add and verify an email in Email Protection.');
                  },
                  onUnlink: hasEmail
                      ? () {
                          if (linkedRecoveryCount <= 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cannot unlink the last recovery method. Add another provider first.',
                                ),
                              ),
                            );
                            return;
                          }
                          context.push(CrushRoutes.emailProtection);
                        }
                      : null,
                ),
                _LinkedAccountTile(
                  icon: Icons.phone_outlined,
                  provider: 'Phone',
                  status: hasPhone
                      ? (phoneVerified
                            ? 'Linked · Verified'
                            : 'Linked · Unverified')
                      : 'Not linked',
                  isLinked: hasPhone,
                  actionLabel: hasPhone ? 'Manage' : 'Link',
                  onAction: () {
                    if (hasPhone) {
                      context.push(CrushRoutes.phoneProtection);
                      return;
                    }
                    _showSnack('Add and verify a phone in Phone Protection.');
                  },
                  onUnlink: hasPhone
                      ? () {
                          if (linkedRecoveryCount <= 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cannot unlink the last recovery method. Add another provider first.',
                                ),
                              ),
                            );
                            return;
                          }
                          context.push(CrushRoutes.phoneProtection);
                        }
                      : null,
                ),
                _LinkedAccountTile(
                  icon: Icons.g_mobiledata,
                  provider: 'Google',
                  status: _isLoadingLinkedProviders
                      ? 'Checking...'
                      : (googleLinked ? 'Linked' : 'Not linked'),
                  isLinked: googleLinked,
                  actionLabel: googleLinked ? 'Linked' : 'Link',
                  isBusy:
                      _busyProviderId == LinkedAuthProvider.google.providerId,
                  onAction: googleLinked
                      ? () => _showSnack('Google is already linked.')
                      : () => _handleLinkProvider(LinkedAuthProvider.google),
                  onUnlink: googleLinked
                      ? () => _handleUnlinkProvider(
                          LinkedAuthProvider.google,
                          linkedRecoveryCount: linkedRecoveryCount,
                        )
                      : null,
                ),
                _LinkedAccountTile(
                  icon: Icons.apple,
                  provider: 'Apple',
                  status: _isLoadingLinkedProviders
                      ? 'Checking...'
                      : (appleLinked ? 'Linked' : 'Not linked'),
                  isLinked: appleLinked,
                  actionLabel: appleLinked ? 'Linked' : 'Link',
                  isBusy:
                      _busyProviderId == LinkedAuthProvider.apple.providerId,
                  onAction: appleLinked
                      ? () => _showSnack('Apple is already linked.')
                      : () => _handleLinkProvider(LinkedAuthProvider.apple),
                  onUnlink: appleLinked
                      ? () => _handleUnlinkProvider(
                          LinkedAuthProvider.apple,
                          linkedRecoveryCount: linkedRecoveryCount,
                        )
                      : null,
                ),
                DsGap.xxl,
                // Security tips
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Container(
                    padding: DsEdgeInsets.allLg,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DsColors.surfaceDark
                          : DsColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? DsColors.borderDark
                            : DsColors.borderLight,
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
                              color: DsColors.warning,
                            ),
                            DsGap.mdH,
                            Text(
                              'Security tips',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
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
                          text:
                              'Enable email verification for account recovery',
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
          ),
        ),
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
    this.locked = false,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback? onTap;
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
      trailing:
          trailing ??
          (locked
              ? const Icon(Icons.lock_outline, color: DsColors.success)
              : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}

class _LinkedAccountTile extends StatelessWidget {
  const _LinkedAccountTile({
    required this.icon,
    required this.provider,
    required this.status,
    required this.isLinked,
    required this.actionLabel,
    required this.onAction,
    this.isBusy = false,
    this.onUnlink,
  });

  final IconData icon;
  final String provider;
  final String status;
  final bool isLinked;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isBusy;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(provider),
      subtitle: Text(status),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: isBusy ? null : onAction,
            child: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionLabel),
          ),
          if (isLinked && onUnlink != null)
            TextButton(
              onPressed: isBusy ? null : onUnlink,
              child: const Text('Unlink'),
            ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text, required this.isDark});

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
          color: DsColors.success.withValues(alpha: 0.7),
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

String _maskPhoneNumber(String phone) {
  if (phone.length <= 4) return phone;
  final visibleStart = phone.substring(0, phone.length > 6 ? 4 : 2);
  final visibleEnd = phone.substring(phone.length - 2);
  final maskedLength = phone.length - visibleStart.length - visibleEnd.length;
  return '$visibleStart${'*' * maskedLength}$visibleEnd';
}
