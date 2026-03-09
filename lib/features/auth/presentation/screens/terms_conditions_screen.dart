import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const Key termsConditionsContentConstraintKey = ValueKey<String>(
  'terms_conditions_content_constraint',
);

double termsConditionsContentMaxWidthFor(double screenWidth) {
  return DsBreakpoints.contentMaxWidth(screenWidth);
}

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

  AuthFlowUseCases _authFlowUseCases() {
    return AuthFlowUseCases(context.read<AuthRepository>());
  }

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

    final acceptResult = await _authFlowUseCases().acceptTermsAndConditions();
    if (!acceptResult.isSuccess) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(
        context,
        acceptResult.errorMessage ??
            AppLocalizations.of(context).onboardingTermsSaveFailed,
      );
      return;
    }

    final refreshedUserResult = await _authFlowUseCases().refreshCurrentUser();
    if (mounted) {
      // Refresh auth state so router has updated user data
      context.read<AuthBloc>().add(AuthUserRefreshRequested());
      _routeAfterTerms(refreshedUserResult.data ?? acceptResult.data);
    }
    if (mounted) {
      setState(() => _isLoading = false);
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsConditions),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            key: termsConditionsContentConstraintKey,
            constraints: BoxConstraints(
              maxWidth: termsConditionsContentMaxWidthFor(
                MediaQuery.sizeOf(context).width,
              ),
            ),
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
                            l10n.onboardingTermsReadAndAccept,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: DsColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          if (!_hasScrolledToEnd)
                            Text(
                              l10n.onboardingTermsScrollToContinue,
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
                              l10n.onboardingTermsWelcomeTitle,
                              l10n.onboardingTermsWelcomeBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsEligibilityTitle,
                              l10n.onboardingTermsEligibilityBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsAccountSecurityTitle,
                              l10n.onboardingTermsAccountSecurityBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsUserConductTitle,
                              l10n.onboardingTermsUserConductBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsPrivacyTitle,
                              l10n.onboardingTermsPrivacyBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsContentOwnershipTitle,
                              l10n.onboardingTermsContentOwnershipBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsSafetyTitle,
                              l10n.onboardingTermsSafetyBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsTerminationTitle,
                              l10n.onboardingTermsTerminationBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsDisclaimerTitle,
                              l10n.onboardingTermsDisclaimerBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsChangesTitle,
                              l10n.onboardingTermsChangesBody,
                            ),
                            _buildSection(
                              context,
                              l10n.onboardingTermsContactTitle,
                              l10n.onboardingTermsContactBody,
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: DsColors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.onboardingTermsEndLabel,
                                      style: const TextStyle(
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
                        container: true,
                        enabled: _hasScrolledToEnd,
                        checked: _isAgreed,
                        label: l10n.onboardingTermsAgreementLabel,
                        hint: _hasScrolledToEnd
                            ? l10n.onboardingTermsAgreementToggleHint
                            : l10n.onboardingTermsScrollHint,
                        onTap: _hasScrolledToEnd
                            ? () => setState(() => _isAgreed = !_isAgreed)
                            : null,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
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
                                    l10n.onboardingTermsAgreementLabel,
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
                        label: l10n.onboardingTermsContinueSemantics,
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
                                : Text(
                                    l10n.commonContinue,
                                    style: const TextStyle(
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
                          l10n.onboardingTermsScrollHint,
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
