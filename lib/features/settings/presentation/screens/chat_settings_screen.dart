import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/chat_settings_cubit.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Settings'),
      ),
      body: BlocConsumer<ChatSettingsCubit, ChatSettingsState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: DsColors.error,
              ),
            );
            context.read<ChatSettingsCubit>().clearError();
          }
        },
        builder: (context, state) {
          final cubit = context.read<ChatSettingsCubit>();
          return ListView(
            children: [
              // Header
              Container(
                padding: DsEdgeInsets.allLg,
                margin: DsEdgeInsets.allLg,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DsColors.primary.withValues(alpha: 0.1),
                      DsColors.secondary.withValues(alpha: 0.1),
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
                        color: DsColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: DsColors.primary,
                        size: 28,
                      ),
                    ),
                    DsGap.lgH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message Retention',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          DsGap.xs,
                          Text(
                            'Control how long your messages are kept after being read.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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

              // Current retention display
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Container(
                  padding: DsEdgeInsets.allMd,
                  decoration: BoxDecoration(
                    color:
                        isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? DsColors.borderDark : DsColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: DsColors.primary,
                        size: 24,
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current retention',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                            ),
                            Text(
                              state.retentionDisplay,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: DsColors.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DsGap.lg,

              // Plus users get 7 days info
              if (state.isPremium) ...[
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Container(
                    padding: DsEdgeInsets.allMd,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DsColors.warning.withValues(alpha: 0.1),
                          DsColors.warning.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: DsColors.warning,
                          size: 24,
                        ),
                        DsGap.mdH,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plus Benefit',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              DsGap.xs,
                              Text(
                                'Your messages are kept for 7 days after being read. This is a Plus-exclusive benefit!',
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
                ),
              ] else ...[
                // Extended retention toggle for free users
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Retention Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: state.settings.extendedRetention
                          ? DsColors.primary
                          : DsColors.ink300,
                    ),
                  ),
                  title: const Text('Keep messages for 24 hours'),
                  subtitle: Text(
                    state.settings.extendedRetention
                        ? 'Messages are deleted 24 hours after being read'
                        : 'Messages are deleted 1 hour after being read',
                  ),
                  value: state.settings.extendedRetention,
                  onChanged: state.isLoading
                      ? null
                      : (value) => cubit.toggleExtendedRetention(value),
                  activeTrackColor: DsColors.primary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return DsColors.primary;
                    }
                    return null;
                  }),
                ),
                DsGap.lg,

                // Plus promotion
                Padding(
                  padding: DsEdgeInsets.horizontalLg,
                  child: Container(
                    padding: DsEdgeInsets.allMd,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DsColors.primary.withValues(alpha: 0.1),
                          DsColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: DsColors.primary,
                          size: 24,
                        ),
                        DsGap.mdH,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Want more time?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              DsGap.xs,
                              Text(
                                'Upgrade to Plus to keep messages for up to 7 days!',
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
                ),
              ],
              DsGap.xl,

              // Info section
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                        ),
                      ],
                    ),
                    DsGap.sm,
                    _InfoItem(
                      icon: Icons.visibility,
                      text:
                          'Messages are deleted after being read, based on your retention setting.',
                      isDark: isDark,
                    ),
                    DsGap.xs,
                    _InfoItem(
                      icon: Icons.person,
                      text:
                          'Your setting only affects your view. Others see messages based on their own settings.',
                      isDark: isDark,
                    ),
                    DsGap.xs,
                    _InfoItem(
                      icon: Icons.lock,
                      text: 'Deleted messages cannot be recovered.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              DsGap.xxl,

              // Loading indicator overlay
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
          ),
        ),
      ],
    );
  }
}
