import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;
  bool _isAgreed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToEnd) {
        setState(() => _hasScrolledToEnd = true);
      }
    }
  }

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.acceptTermsAndConditions();
      final refreshedUser = await authRepo.refreshCurrentUser();

      if (mounted) {
        // Refresh auth state so router has updated user data
        context.read<AuthBloc>().add(AuthUserRefreshRequested());
        _routeAfterTerms(refreshedUser);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to save. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _routeAfterTerms(CrushUser? user) {
    final resolvedUser = user ?? context.read<AuthBloc>().state.user;
    if (resolvedUser == null) {
      context.go(CrushRoutes.authGateway);
      return;
    }

    if (!resolvedUser.hasAcceptedTerms) {
      context.go(CrushRoutes.termsConditions);
      return;
    }

    if (!resolvedUser.hasCompletedBasicInfo) {
      context.go(CrushRoutes.basicInfo);
      return;
    }

    if (!resolvedUser.hasCompletedProfileSetup) {
      context.go(CrushRoutes.profileSetup);
      return;
    }

    if (!resolvedUser.isAccountVerified) {
      context.go(CrushRoutes.emailVerification);
      return;
    }

    context.go(CrushRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).termsConditions),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: DsEdgeInsets.horizontalXxl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Please read and accept',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: DsColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          if (!_hasScrolledToEnd)
                            Text(
                              'Scroll to continue',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                            ),
                        ],
                      ),
                      DsGap.sm,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _hasScrolledToEnd ? 1.0 : 0.5,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? DsColors.skeletonDark
                              : DsColors.skeletonLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            DsColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DsGap.lg,
                // Scrollable terms content
                Expanded(
                  child: Container(
                    margin: DsEdgeInsets.horizontalXxl,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DsColors.surfaceDark.withValues(alpha: 0.5)
                          : DsColors.inputFillLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? DsColors.borderDark
                            : DsColors.borderLight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: DsEdgeInsets.allLg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              context,
                              'Welcome to Crush',
                              'By using our dating app, you agree to these Terms and Conditions. '
                                  'Please read them carefully before proceeding.',
                            ),
                            _buildSection(
                              context,
                              '1. Eligibility',
                              'You must be at least 18 years old to use Crush. By creating an account, '
                                  'you confirm that you are of legal age and have the right to enter into this agreement.',
                            ),
                            _buildSection(
                              context,
                              '2. Account Security',
                              'You are responsible for maintaining the confidentiality of your account credentials. '
                                  'Notify us immediately if you suspect unauthorized access to your account.',
                            ),
                            _buildSection(
                              context,
                              '3. User Conduct',
                              'You agree to:\n'
                                  '• Provide accurate information\n'
                                  '• Treat other users with respect\n'
                                  '• Not engage in harassment, hate speech, or illegal activities\n'
                                  '• Not impersonate others or create fake profiles\n'
                                  '• Not share inappropriate or explicit content',
                            ),
                            _buildSection(
                              context,
                              '4. Privacy',
                              'Your privacy is important to us. We collect and process your personal data '
                                  'in accordance with our Privacy Policy. By using Crush, you consent to our '
                                  'data practices as described in the Privacy Policy.',
                            ),
                            _buildSection(
                              context,
                              '5. Content Ownership',
                              'You retain ownership of content you post. However, you grant Crush a '
                                  'non-exclusive license to use, display, and distribute your content '
                                  'within the app for the purpose of providing our services.',
                            ),
                            _buildSection(
                              context,
                              '6. Safety',
                              'While we implement safety measures, you are responsible for your own safety '
                                  'when meeting people from the app. We recommend meeting in public places '
                                  'and informing someone you trust about your plans.',
                            ),
                            _buildSection(
                              context,
                              '7. Termination',
                              'We reserve the right to suspend or terminate your account if you violate '
                                  'these terms. You may also delete your account at any time through the app settings.',
                            ),
                            _buildSection(
                              context,
                              '8. Disclaimer',
                              'Crush is provided "as is" without warranties. We do not guarantee '
                                  'that you will find a match or that other users\' information is accurate.',
                            ),
                            _buildSection(
                              context,
                              '9. Changes to Terms',
                              'We may update these terms from time to time. Continued use of the app '
                                  'after changes constitutes acceptance of the new terms.',
                            ),
                            _buildSection(
                              context,
                              '10. Contact',
                              'If you have questions about these terms, please contact us through '
                                  'the app\'s support feature or email support@crushhour.app.',
                            ),
                            DsGap.xl,
                            // End marker
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: DsColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: DsColors.success,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'End of Terms',
                                      style: TextStyle(
                                        color: DsColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DsGap.lg,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                DsGap.lg,
                // Agreement checkbox and button
                Padding(
                  padding: DsEdgeInsets.horizontalXxl,
                  child: Column(
                    children: [
                      // Checkbox
                      Semantics(
                        checked: _isAgreed,
                        label:
                            'I have read and agree to the Terms and Conditions and Privacy Policy',
                        child: GestureDetector(
                          onTap: _hasScrolledToEnd
                              ? () => setState(() => _isAgreed = !_isAgreed)
                              : null,
                          child: Container(
                            padding: DsEdgeInsets.allMd,
                            decoration: BoxDecoration(
                              color: _hasScrolledToEnd
                                  ? (isDark
                                        ? DsColors.surfaceDark.withValues(
                                            alpha: 0.5,
                                          )
                                        : DsColors.inputFillLight)
                                  : DsColors.textMutedLight.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isAgreed
                                    ? DsColors.primary
                                    : (isDark
                                          ? DsColors.borderDark
                                          : DsColors.borderLight),
                                width: _isAgreed ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _isAgreed
                                        ? DsColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _isAgreed
                                          ? DsColors.primary
                                          : (_hasScrolledToEnd
                                                ? DsColors.primary
                                                : (isDark
                                                      ? DsColors.borderDark
                                                      : DsColors.borderLight)),
                                      width: 2,
                                    ),
                                  ),
                                  child: _isAgreed
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: DsColors.backgroundLight,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'I have read and agree to the Terms and Conditions and Privacy Policy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _hasScrolledToEnd
                                              ? (isDark
                                                    ? DsColors.textPrimaryDark
                                                    : DsColors.textPrimaryLight)
                                              : (isDark
                                                    ? DsColors.textMutedDark
                                                    : DsColors.textMutedLight),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      DsGap.lg,
                      // Continue button
                      Semantics(
                        button: true,
                        label: 'Continue',
                        child: SizedBox(
                          width: double.infinity,
                          child: GlassPrimaryButton(
                            onPressed:
                                (_hasScrolledToEnd && _isAgreed && !_isLoading)
                                ? _acceptTerms
                                : null,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DsColors.backgroundLight,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      DsGap.md,
                      // Hint text
                      if (!_hasScrolledToEnd)
                        Text(
                          'Please scroll down to read all terms before agreeing',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                          textAlign: TextAlign.center,
                        ),
                    ],
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

  Widget _buildSection(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? DsColors.textPrimaryDark
                  : DsColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
