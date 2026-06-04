import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final _datePlanService = DatePlanService.instance;
  List<DatePlan> _activePlans = [];
  StreamSubscription<DatePlan>? _planSubscription;
  bool _isLoadingPlans = true;

  @override
  void initState() {
    super.initState();
    // Load profile data for blocked/muted users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyCubit>().loadProfilesForSafetyUsers();
      _loadDatePlans();
    });

    // Listen for plan updates
    _planSubscription = _datePlanService.datePlanStream.listen((plan) {
      _loadDatePlans();
    });
  }

  @override
  void dispose() {
    _planSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDatePlans() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      setState(() => _isLoadingPlans = false);
      return;
    }

    final plans = await _datePlanService.getActivePlans(userId);
    if (mounted) {
      setState(() {
        _activePlans = plans;
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _checkIn(String planId) async {
    try {
      await _datePlanService.checkIn(planId);
      if (mounted) {
        showSuccessSnackBar(
          context,
          AppLocalizations.of(context).safetyCheckedInSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          AppLocalizations.of(context).safetyCheckInFailed,
        );
      }
    }
  }

  Future<void> _startDate(String planId) async {
    try {
      await _datePlanService.startDate(planId);
      if (mounted) {
        showSuccessSnackBar(
          context,
          AppLocalizations.of(context).safetyDateStartedSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          AppLocalizations.of(context).safetyDateStartFailed,
        );
      }
    }
  }

  Future<void> _endDateSafely(String planId) async {
    try {
      await _datePlanService.endDateSafely(planId);
      if (mounted) {
        showSuccessSnackBar(
          context,
          AppLocalizations.of(context).safetyDateEndedSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          AppLocalizations.of(context).safetyDateEndFailed,
        );
      }
    }
  }

  Future<void> _triggerEmergency(BuildContext context, String planId) async {
    final l10n = AppLocalizations.of(context);
    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: DsColors.error),
            const SizedBox(width: 8),
            Text(l10n.safetyEmergencyAlertTitle),
          ],
        ),
        content: Text(l10n.safetyEmergencyAlertBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DsColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.safetySendAlert),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datePlanService.triggerEmergencyAlert(planId);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              // success/mint needs a dark foreground for legible text (9.72:1).
              content: Text(
                l10n.safetyEmergencyAlertSent,
                style: TextStyle(
                  color: DsAccessibility.accessibleTextColor(DsColors.success),
                ),
              ),
              backgroundColor: DsColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.safetyEmergencyAlertFailed),
              backgroundColor: DsColors.error,
            ),
          );
        }
      }
    }
  }

  void _showCreateDatePlanSheet(BuildContext context, String? userId) {
    if (userId == null) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(context).safetySignInToCreatePlan,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateDatePlanSheet(
        userId: userId,
        onPlanCreated: () {
          Navigator.pop(ctx);
          _loadDatePlans();
          showSuccessSnackBar(
            context,
            AppLocalizations.of(context).safetyDatePlanCreated,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocConsumer<SafetyCubit, SafetyState>(
              listenWhen: (previous, current) =>
                  previous.errorMessage != current.errorMessage,
              listener: (context, state) {
                final error = state.errorMessage;
                if (error != null && error.isNotEmpty) {
                  showErrorSnackBar(context, error);
                }
              },
              builder: (context, state) {
                final cubit = context.read<SafetyCubit>();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _SafetyEducationCard(),
                    const SizedBox(height: 16),
                    _DatePlansSection(
                      plans: _activePlans,
                      isLoading: _isLoadingPlans,
                      onCreatePlan: () =>
                          _showCreateDatePlanSheet(context, currentUserId),
                      onCheckIn: (planId) => _checkIn(planId),
                      onEndDate: (planId) => _endDateSafely(planId),
                      onEmergency: (planId) =>
                          _triggerEmergency(context, planId),
                      onStartDate: (planId) => _startDate(planId),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: l10n.safetyBlockedUsers,
                      emptyText: l10n.safetyBlockedUsersEmpty,
                      items: state.blockedUsers.toList(),
                      profileCache: state.profileCache,
                      isLoading: state.isLoadingProfiles,
                      onRemove: (userId) =>
                          _unblock(context, cubit, currentUserId, userId),
                      removeLabel: l10n.safetyUnblock,
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: l10n.safetyMutedMessages,
                      emptyText: l10n.safetyMutedMessagesEmpty,
                      items: state.mutedMessages.toList(),
                      profileCache: state.profileCache,
                      isLoading: state.isLoadingProfiles,
                      onRemove: (userId) =>
                          cubit.toggleMuteMessages(userId, mute: false),
                      removeLabel: l10n.safetyUnmuteMessages,
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: l10n.safetyMutedCalls,
                      emptyText: l10n.safetyMutedCallsEmpty,
                      items: state.mutedCalls.toList(),
                      profileCache: state.profileCache,
                      isLoading: state.isLoadingProfiles,
                      onRemove: (userId) =>
                          cubit.toggleMuteCalls(userId, mute: false),
                      removeLabel: l10n.safetyUnmuteCalls,
                    ),
                    const SizedBox(height: 16),
                    _ReportHistorySection(
                      reportedUsers: state.reportedUsers,
                      profileCache: state.profileCache,
                      isLoading: state.isLoadingProfiles,
                      onGuidelinesTap: () =>
                          context.push(CrushRoutes.safetyGuidelines),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.safetyNeedToReport,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.safetyReportInstructions),
                            TextButton.icon(
                              onPressed: () {
                                context.push(CrushRoutes.safetyGuidelines);
                              },
                              icon: const Icon(Icons.policy),
                              label: Text(l10n.safetyReadCommunityGuidelines),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: currentUserId == null
                                  ? null
                                  : () => _showAppealDialog(
                                      context,
                                      cubit,
                                      currentUserId,
                                    ),
                              icon: const Icon(Icons.gavel_outlined),
                              label: Text(l10n.safetySubmitAppeal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    SafetyCubit cubit,
    String? currentUserId,
    String userId,
  ) async {
    if (currentUserId == null) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(context).safetySignInToManage,
      );
      return;
    }
    await cubit.toggleBlock(userId, block: false, currentUserId: currentUserId);
  }

  Future<void> _showAppealDialog(
    BuildContext context,
    SafetyCubit cubit,
    String currentUserId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.safetyAppealDialogTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.safetyAppealHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonSubmit),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (submitted == true) {
      final reason = controller.text.trim();
      if (reason.isEmpty) {
        showErrorSnackBar(context, l10n.safetyAppealDetailsRequired);
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      await cubit.submitAppeal(
        userId: currentUserId,
        reason: reason,
        targetType: 'account',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.safetyAppealSubmitted)),
      );
    }
  }
}

class _ReportHistorySection extends StatelessWidget {
  const _ReportHistorySection({
    required this.reportedUsers,
    required this.profileCache,
    required this.onGuidelinesTap,
    this.isLoading = false,
  });

  final Map<String, DateTime> reportedUsers;
  final Map<String, SafetyProfileInfo> profileCache;
  final VoidCallback onGuidelinesTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = reportedUsers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.safetyReportHistory, style: theme.textTheme.titleMedium),
                if (isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.safetyReportHistoryDesc,
              style: TextStyle(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                l10n.safetyNoRecentReports,
                style: TextStyle(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
              )
            else
              ...entries.map((entry) {
                final profile = profileCache[entry.key];
                final locale = Localizations.localeOf(context).toLanguageTag();
                final reportedAt = DateTimeFormatter.formatDate(
                  entry.value,
                  locale: locale,
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _ReportAvatar(profile: profile),
                  title: Text(
                    profile?.name ?? l10n.safetyUnknownUser,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(l10n.safetyReportedOn(reportedAt)),
                  trailing: const Icon(Icons.lock_outline, size: 18),
                );
              }),
            TextButton.icon(
              onPressed: onGuidelinesTap,
              icon: const Icon(Icons.policy_outlined),
              label: Text(l10n.safetyReviewReportingRules),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportAvatar extends StatelessWidget {
  const _ReportAvatar({required this.profile});

  final SafetyProfileInfo? profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarFill = isDark ? DsColors.surfaceDark : DsColors.surfaceLight;
    if (profile?.photoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: avatarFill,
        child: ClipOval(
          child: CachedImage(
            imageUrl: profile!.photoUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: avatarFill,
      child: Icon(
        Icons.flag_outlined,
        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
      ),
    );
  }
}

class _SafetyEducationCard extends StatelessWidget {
  const _SafetyEducationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: DsColors.success),
                const SizedBox(width: 8),
                Text(
                  l10n.safetyEducationTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SafetyTip(
              icon: Icons.place_outlined,
              text: l10n.safetyTipMeetPublic,
            ),
            _SafetyTip(
              icon: Icons.lock_outline,
              text: l10n.safetyTipKeepInApp,
            ),
            _SafetyTip(
              icon: Icons.verified_user_outlined,
              text: l10n.safetyTipVerify,
            ),
            _SafetyTip(
              icon: Icons.flag_outlined,
              text: l10n.safetyTipBlockReport,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.push(CrushRoutes.safetyGuidelines);
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.safetyReviewGuidelines),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.profileCache,
    required this.onRemove,
    required this.removeLabel,
    this.isLoading = false,
  });

  final String title;
  final String emptyText;
  final List<String> items;
  final Map<String, SafetyProfileInfo> profileCache;
  final ValueChanged<String> onRemove;
  final String removeLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                emptyText,
                style: TextStyle(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
              )
            else
              ...items.map((id) {
                final profile = profileCache[id];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildAvatar(context, profile),
                  title: Text(
                    profile?.name ?? AppLocalizations.of(context).safetyUnknownUser,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    id,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => onRemove(id),
                    child: Text(removeLabel),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, SafetyProfileInfo? profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarFill = isDark ? DsColors.surfaceDark : DsColors.surfaceLight;
    if (profile?.photoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: avatarFill,
        child: ClipOval(
          child: CachedImage(
            imageUrl: profile!.photoUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: avatarFill,
      child: Icon(
        Icons.person,
        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
      ),
    );
  }
}

/// Section displaying active date plans with safety actions.
class _DatePlansSection extends StatelessWidget {
  const _DatePlansSection({
    required this.plans,
    required this.isLoading,
    required this.onCreatePlan,
    required this.onCheckIn,
    required this.onEndDate,
    required this.onEmergency,
    required this.onStartDate,
  });

  final List<DatePlan> plans;
  final bool isLoading;
  final VoidCallback onCreatePlan;
  final ValueChanged<String> onCheckIn;
  final ValueChanged<String> onEndDate;
  final ValueChanged<String> onEmergency;
  final ValueChanged<String> onStartDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: DsColors.primary,
                    size: 20,
                  ),
                ),
                DsGap.mdH,
                Expanded(
                  child: Text(
                    l10n.safetyDatePlansTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            DsGap.md,
            Text(
              l10n.safetyDatePlansDesc,
              style: TextStyle(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
                fontSize: 13,
              ),
            ),
            DsGap.lg,
            if (plans.isEmpty)
              _EmptyDatePlans(onCreatePlan: onCreatePlan)
            else
              ...plans.map(
                (plan) => _DatePlanCard(
                  plan: plan,
                  onCheckIn: () => onCheckIn(plan.id),
                  onEndDate: () => onEndDate(plan.id),
                  onEmergency: () => onEmergency(plan.id),
                  onStartDate: () => onStartDate(plan.id),
                ),
              ),
            if (plans.isNotEmpty) ...[
              DsGap.md,
              SizedBox(
                width: double.infinity,
                child: GlassOutlinedButton(
                  onPressed: onCreatePlan,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.safetyPlanAnotherDate),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyDatePlans extends StatelessWidget {
  const _EmptyDatePlans({required this.onCreatePlan});

  final VoidCallback onCreatePlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DsColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.favorite_border,
                size: 48,
                color: DsColors.primary,
              ),
              DsGap.md,
              Text(
                l10n.safetyNoActiveDatePlans,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              DsGap.sm,
              Text(
                l10n.safetyNoActiveDatePlansDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        DsGap.lg,
        SizedBox(
          width: double.infinity,
          child: GlassPrimaryButton(
            onPressed: onCreatePlan,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 8),
                Text(l10n.safetyCreateDatePlan),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePlanCard extends StatelessWidget {
  const _DatePlanCard({
    required this.plan,
    required this.onCheckIn,
    required this.onEndDate,
    required this.onEmergency,
    required this.onStartDate,
  });

  final DatePlan plan;
  final VoidCallback onCheckIn;
  final VoidCallback onEndDate;
  final VoidCallback onEmergency;
  final VoidCallback onStartDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isOngoing = plan.status == DatePlanStatus.ongoing;
    final isScheduled = plan.status == DatePlanStatus.scheduled;
    final mutedFill = isDark ? DsColors.ink600 : DsColors.ink100;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? DsColors.surfaceElevatedDark.withValues(alpha: 0.6)
            : DsColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOngoing
              ? DsColors.success.withValues(alpha: 0.5)
              : (isDark ? DsColors.borderDark : DsColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: DsColors.primary.withValues(alpha: 0.1),
                child: Text(
                  plan.matchName.isNotEmpty
                      ? plan.matchName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: DsColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DsGap.mdH,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.safetyDateWith(plan.matchName),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${plan.formattedDate} at ${plan.formattedTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: plan.status),
            ],
          ),
          DsGap.sm,
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 14,
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plan.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
              ),
            ],
          ),
          if (plan.sharedWith.isNotEmpty) ...[
            DsGap.xs,
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.safetySharedWithContacts(plan.sharedWith.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
          DsGap.md,
          // Action buttons based on status
          if (isScheduled) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStartDate,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.safetyStartDate),
                  ),
                ),
              ],
            ),
          ] else if (isOngoing) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: plan.hasCheckedIn ? null : onCheckIn,
                    icon: Icon(
                      plan.hasCheckedIn ? Icons.check : Icons.safety_check,
                      size: 18,
                    ),
                    label: Text(
                      plan.hasCheckedIn
                          ? l10n.safetyCheckedIn
                          : l10n.safetyCheckInSafe,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: plan.hasCheckedIn
                          ? mutedFill
                          : DsColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEndDate,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(l10n.safetyEndSafely),
                  ),
                ),
              ],
            ),
            DsGap.sm,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEmergency,
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: DsColors.error,
                ),
                label: Text(
                  l10n.safetyEmergencyAlertTitle,
                  style: const TextStyle(color: DsColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DsColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DatePlanStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? DsColors.ink300 : DsColors.ink300;
    final (color, label) = switch (status) {
      DatePlanStatus.scheduled => (DsColors.info, l10n.safetyStatusScheduled),
      DatePlanStatus.ongoing => (DsColors.success, l10n.safetyStatusOngoing),
      DatePlanStatus.completed => (muted, l10n.safetyStatusCompleted),
      DatePlanStatus.cancelled => (muted, l10n.safetyStatusCancelled),
      DatePlanStatus.emergency => (DsColors.error, l10n.safetyStatusEmergency),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Bottom sheet for creating a new date plan.
class _CreateDatePlanSheet extends StatefulWidget {
  const _CreateDatePlanSheet({
    required this.userId,
    required this.onPlanCreated,
  });

  final String userId;
  final VoidCallback onPlanCreated;

  @override
  State<_CreateDatePlanSheet> createState() => _CreateDatePlanSheetState();
}

class _CreateDatePlanSheetState extends State<_CreateDatePlanSheet> {
  final _matchNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _matchNameController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? DsColors.ink600 : DsColors.ink100,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            DsGap.lg,
            Text(
              l10n.safetyCreateDatePlan,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            DsGap.sm,
            Text(
              l10n.safetyCreateDatePlanDesc,
              style: TextStyle(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            ),
            DsGap.xl,
            // Match name
            GlassTextField(
              controller: _matchNameController,
              label: l10n.safetyWhoMeeting,
              hintText: l10n.safetyTheirNameHint,
              prefixIcon: Icons.person_outline,
            ),
            DsGap.lg,
            // Date & Time
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today,
                    label:
                        '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    onTap: _selectDate,
                  ),
                ),
                DsGap.mdH,
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.access_time,
                    label: _selectedTime.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            DsGap.lg,
            // Location
            GlassTextField(
              controller: _locationController,
              label: l10n.safetyWhereLabel,
              hintText: l10n.safetyLocationHint,
              prefixIcon: Icons.place_outlined,
            ),
            DsGap.xl,
            // Emergency contact section
            Text(
              l10n.safetyEmergencyContact,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            DsGap.sm,
            Text(
              l10n.safetyEmergencyContactDesc,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            ),
            DsGap.md,
            GlassTextField(
              controller: _contactNameController,
              label: l10n.safetyContactName,
              hintText: l10n.safetyContactNameHint,
              prefixIcon: Icons.person,
            ),
            DsGap.md,
            GlassTextField(
              controller: _contactEmailController,
              label: l10n.safetyContactEmail,
              hintText: l10n.safetyContactEmailHint,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            DsGap.lg,
            // Notes (optional)
            GlassTextField(
              controller: _notesController,
              label: l10n.safetyNotesLabel,
              hintText: l10n.safetyNotesHint,
              prefixIcon: Icons.note_outlined,
            ),
            if (_error != null) ...[
              DsGap.md,
              Text(
                _error!,
                style: const TextStyle(color: DsColors.error, fontSize: 13),
              ),
            ],
            DsGap.xl,
            SizedBox(
              width: double.infinity,
              child: GlassPrimaryButton(
                onPressed: _isLoading ? null : _createPlan,
                isLoading: _isLoading,
                child: Text(l10n.safetyCreatePlan),
              ),
            ),
            DsGap.md,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createPlan() async {
    final l10n = AppLocalizations.of(context);
    // Validate
    if (_matchNameController.text.trim().isEmpty) {
      setState(() => _error = l10n.safetyErrorEnterMatch);
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      setState(() => _error = l10n.safetyErrorEnterLocation);
      return;
    }
    final contactName = _contactNameController.text.trim();
    final contactEmail = _contactEmailController.text.trim();
    if (contactName.isEmpty || contactEmail.isEmpty) {
      setState(() => _error = l10n.safetyErrorAddContact);
      return;
    }
    if (!looksLikeEmail(contactEmail)) {
      setState(() => _error = l10n.safetyErrorValidEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await DatePlanService.instance.createDatePlan(
        userId: widget.userId,
        matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
        matchName: _matchNameController.text.trim(),
        dateTime: dateTime,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        sharedWith: [
          EmergencyContact(
            name: contactName,
            phone: '', // Phone is optional, using email instead
            email: contactEmail,
            notifyBySms: false,
            notifyByEmail: true,
          ),
        ],
      );

      widget.onPlanCreated();
    } catch (e) {
      final rawMessage = e.toString();
      final cleaned = rawMessage.startsWith('Exception: ')
          ? rawMessage.substring(11)
          : rawMessage;
      setState(() {
        _isLoading = false;
        _error = cleaned.isNotEmpty ? cleaned : l10n.safetyCreatePlanFailed;
      });
    }
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? DsColors.inputFillDark : DsColors.inputFillLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: DsColors.primary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
