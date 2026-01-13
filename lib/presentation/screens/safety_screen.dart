import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
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
        showSuccessSnackBar(context, 'Checked in safely! Your contacts have been notified.');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not check in. Please try again.');
      }
    }
  }

  Future<void> _startDate(String planId) async {
    try {
      await _datePlanService.startDate(planId);
      if (mounted) {
        showSuccessSnackBar(context, 'Date started! Your contacts have been notified.');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not start date. Please try again.');
      }
    }
  }

  Future<void> _endDateSafely(String planId) async {
    try {
      await _datePlanService.endDateSafely(planId);
      if (mounted) {
        showSuccessSnackBar(context, 'Date ended safely! Your contacts have been notified.');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not end date. Please try again.');
      }
    }
  }

  Future<void> _triggerEmergency(BuildContext context, String planId) async {
    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'This will immediately notify all your emergency contacts with your location. '
          'Only use this if you feel unsafe.\n\n'
          'Are you sure you want to send an emergency alert?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datePlanService.triggerEmergencyAlert(planId);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Emergency alert sent to all contacts!'),
              backgroundColor: DsColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Could not send alert. Please call emergency services directly.'),
              backgroundColor: DsColors.error,
            ),
          );
        }
      }
    }
  }

  void _showCreateDatePlanSheet(BuildContext context, String? userId) {
    if (userId == null) {
      showErrorSnackBar(context, 'Please sign in to create a date plan.');
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
          showSuccessSnackBar(context, 'Date plan created! Share it with your trusted contacts.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & blocking')),
      body: BlocConsumer<SafetyCubit, SafetyState>(
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
                onCreatePlan: () => _showCreateDatePlanSheet(context, currentUserId),
                onCheckIn: (planId) => _checkIn(planId),
                onEndDate: (planId) => _endDateSafely(planId),
                onEmergency: (planId) => _triggerEmergency(context, planId),
                onStartDate: (planId) => _startDate(planId),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Blocked users',
                emptyText:
                    "People you block can't see your profile, message, or call you.",
                items: state.blockedUsers.toList(),
                profileCache: state.profileCache,
                isLoading: state.isLoadingProfiles,
                onRemove: (userId) => _unblock(
                  context,
                  cubit,
                  currentUserId,
                  userId,
                ),
                removeLabel: 'Unblock',
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Muted messages',
                emptyText:
                    'Mute message alerts for someone without blocking them.',
                items: state.mutedMessages.toList(),
                profileCache: state.profileCache,
                isLoading: state.isLoadingProfiles,
                onRemove: (userId) =>
                    cubit.toggleMuteMessages(userId, mute: false),
                removeLabel: 'Unmute messages',
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Muted calls',
                emptyText: 'Silence call alerts from selected people.',
                items: state.mutedCalls.toList(),
                profileCache: state.profileCache,
                isLoading: state.isLoadingProfiles,
                onRemove: (userId) => cubit.toggleMuteCalls(userId, mute: false),
                removeLabel: 'Unmute calls',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need to report someone?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Open their profile or chat, choose Report, and pick a reason. '
                    'We review reports to keep the community safe.',
                      ),
                      TextButton.icon(
                        onPressed: () {
                          context.push(CrushRoutes.safetyGuidelines);
                        },
                        icon: const Icon(Icons.policy),
                        label: const Text('Read community guidelines'),
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
                        label: const Text('Submit an appeal'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      showErrorSnackBar(context, 'Sign in again to manage safety actions.');
      return;
    }
    await cubit.toggleBlock(
      userId,
      block: false,
      currentUserId: currentUserId,
    );
  }

  Future<void> _showAppealDialog(
    BuildContext context,
    SafetyCubit cubit,
    String currentUserId,
  ) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appeal a safety action'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Share why you are appealing'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (submitted == true) {
      final reason = controller.text.trim();
      if (reason.isEmpty) {
        showErrorSnackBar(context, 'Please add details for your appeal.');
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      await cubit.submitAppeal(
        userId: currentUserId,
        reason: reason,
        targetType: 'account',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Appeal submitted')),
      );
    }
  }
}

class _SafetyEducationCard extends StatelessWidget {
  const _SafetyEducationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Stay safe while you connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _SafetyTip(
              icon: Icons.place_outlined,
              text: 'Plan first meetups in busy public places and share details with a friend.',
            ),
            const _SafetyTip(
              icon: Icons.lock_outline,
              text: 'Keep chats in CrushHour until you trust someone. Never send money or codes.',
            ),
            const _SafetyTip(
              icon: Icons.verified_user_outlined,
              text: 'Look for verification badges and report profiles that feel fake or pushy.',
            ),
            const _SafetyTip(
              icon: Icons.flag_outlined,
              text:
                  'Use block or report if anyone crosses a boundary. We act on reports to protect the community.',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.push(CrushRoutes.safetyGuidelines);
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Review safety & community guidelines'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                style: const TextStyle(color: Colors.grey),
              )
            else
              ...items.map((id) {
                final profile = profileCache[id];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildAvatar(profile),
                  title: Text(
                    profile?.name ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    id,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  Widget _buildAvatar(SafetyProfileInfo? profile) {
    if (profile?.photoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: DsColors.surfaceLight,
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
      backgroundColor: DsColors.surfaceLight,
      child: Icon(
        Icons.person,
        color: Colors.grey.shade600,
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
                const Expanded(
                  child: Text(
                    'Date Plans',
                    style: TextStyle(
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
              'Share your date details with trusted contacts who can check on you.',
              style: TextStyle(
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                fontSize: 13,
              ),
            ),
            DsGap.lg,
            if (plans.isEmpty)
              _EmptyDatePlans(onCreatePlan: onCreatePlan)
            else
              ...plans.map((plan) => _DatePlanCard(
                    plan: plan,
                    onCheckIn: () => onCheckIn(plan.id),
                    onEndDate: () => onEndDate(plan.id),
                    onEmergency: () => onEmergency(plan.id),
                    onStartDate: () => onStartDate(plan.id),
                  )),
            if (plans.isNotEmpty) ...[
              DsGap.md,
              SizedBox(
                width: double.infinity,
                child: GlassOutlinedButton(
                  onPressed: onCreatePlan,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('Plan Another Date'),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DsColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 48,
                color: DsColors.primary,
              ),
              DsGap.md,
              Text(
                'No active date plans',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              DsGap.sm,
              Text(
                'Create a plan before meeting someone and share it with a trusted friend or family member.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        DsGap.lg,
        SizedBox(
          width: double.infinity,
          child: GlassPrimaryButton(
            onPressed: onCreatePlan,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Create Date Plan'),
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
    final isOngoing = plan.status == DatePlanStatus.ongoing;
    final isScheduled = plan.status == DatePlanStatus.scheduled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOngoing
              ? DsColors.success.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.black12),
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
                  plan.matchName.isNotEmpty ? plan.matchName[0].toUpperCase() : '?',
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
                      'Date with ${plan.matchName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${plan.formattedDate} at ${plan.formattedTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plan.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Shared with ${plan.sharedWith.length} contact${plan.sharedWith.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
                    label: const Text('Start Date'),
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
                    label: Text(plan.hasCheckedIn ? 'Checked In' : 'Check In Safe'),
                    style: FilledButton.styleFrom(
                      backgroundColor: plan.hasCheckedIn ? Colors.grey : DsColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEndDate,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('End Safely'),
                  ),
                ),
              ],
            ),
            DsGap.sm,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEmergency,
                icon: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                label: const Text(
                  'Emergency Alert',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
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
    final (color, label) = switch (status) {
      DatePlanStatus.scheduled => (DsColors.info, 'Scheduled'),
      DatePlanStatus.ongoing => (DsColors.success, 'Ongoing'),
      DatePlanStatus.completed => (Colors.grey, 'Completed'),
      DatePlanStatus.cancelled => (Colors.grey, 'Cancelled'),
      DatePlanStatus.emergency => (Colors.red, 'Emergency'),
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
  final _contactPhoneController = TextEditingController();
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
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            DsGap.lg,
            const Text(
              'Create Date Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            DsGap.sm,
            Text(
              'Share your date details with someone you trust.',
              style: TextStyle(
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
            ),
            DsGap.xl,
            // Match name
            GlassTextField(
              controller: _matchNameController,
              label: 'Who are you meeting?',
              hintText: 'Their name',
              prefixIcon: Icons.person_outline,
            ),
            DsGap.lg,
            // Date & Time
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today,
                    label: '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
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
              label: 'Where?',
              hintText: 'Location name or address',
              prefixIcon: Icons.place_outlined,
            ),
            DsGap.xl,
            // Emergency contact section
            const Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            DsGap.sm,
            Text(
              'This person will be notified of your date details and can check on you.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
            ),
            DsGap.md,
            GlassTextField(
              controller: _contactNameController,
              label: 'Contact name',
              hintText: 'Mom, Best friend, etc.',
              prefixIcon: Icons.person,
            ),
            DsGap.md,
            GlassTextField(
              controller: _contactPhoneController,
              label: 'Contact phone',
              hintText: '+1 555 123 4567',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            DsGap.lg,
            // Notes (optional)
            GlassTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hintText: 'Any additional details...',
              prefixIcon: Icons.note_outlined,
            ),
            if (_error != null) ...[
              DsGap.md,
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            DsGap.xl,
            SizedBox(
              width: double.infinity,
              child: GlassPrimaryButton(
                onPressed: _isLoading ? null : _createPlan,
                isLoading: _isLoading,
                child: const Text('Create Plan'),
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
    // Validate
    if (_matchNameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter who you are meeting');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a location');
      return;
    }
    if (_contactNameController.text.trim().isEmpty ||
        _contactPhoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please add an emergency contact');
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
            name: _contactNameController.text.trim(),
            phone: _contactPhoneController.text.trim(),
          ),
        ],
      );

      widget.onPlanCreated();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not create plan. Please try again.';
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
