import 'dart:ui';

import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/chat/presentation/bloc/match_chat_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatMatchSettingsSheet extends StatelessWidget {
  const ChatMatchSettingsSheet({super.key, required this.otherName});

  final String otherName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
        child: Container(
          decoration: BoxDecoration(
            color: baseSurface.withValues(alpha: isDark ? 0.95 : 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderBase, width: 0.5),
          ),
          child: SafeArea(
            child: BlocConsumer<MatchChatSettingsCubit, MatchChatSettingsState>(
              listenWhen: (prev, curr) =>
                  prev.errorMessage != curr.errorMessage &&
                  curr.errorMessage != null,
              listener: (ctx, state) {
                if (state.errorMessage == null) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: DsColors.error,
                  ),
                );
                ctx.read<MatchChatSettingsCubit>().clearError();
              },
              builder: (ctx, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.surfaceLight.withValues(alpha: 0.24)
                              : DsColors.ink900.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        8,
                        20,
                        16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: DsColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.settings_outlined,
                              color: DsColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chat Settings',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Conversation with $otherName',
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
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: isDark
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.54,
                                    )
                                  : DsColors.ink900.withValues(alpha: 0.45),
                              size: 22,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.05,
                                    )
                                  : DsColors.ink900.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        color: isDark
                            ? DsColors.surfaceLight.withValues(alpha: 0.12)
                            : DsColors.ink900.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PRIVACY',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: isDark
                                      ? DsColors.textMutedDark
                                      : DsColors.textMutedLight,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.surfaceLight.withValues(alpha: 0.05)
                              : DsColors.ink900.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? DsColors.surfaceLight.withValues(alpha: 0.1)
                                : DsColors.ink900.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: DsColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.timer_outlined,
                                    color: DsColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Message Retention',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Messages auto-delete after this time',
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
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: DsColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: DsColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Currently: ${state.retentionDisplay}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: DsColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (state.isPremium) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      DsColors.warning.withValues(alpha: 0.15),
                                      DsColors.warning.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium,
                                      color: DsColors.warning,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Plus: 7 days retention',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: DsColors.warning,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Extended retention (24h)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  if (state.isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Switch.adaptive(
                                      value: state.settings.extendedRetention,
                                      onChanged: (value) => ctx
                                          .read<MatchChatSettingsCubit>()
                                          .toggleExtendedRetention(value),
                                      activeThumbColor: DsColors.primary,
                                      activeTrackColor: DsColors.primary
                                          .withValues(alpha: 0.4),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.settings.extendedRetention
                                    ? 'Messages deleted 24 hours after being read'
                                    : 'Messages deleted 1 hour after being read',
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
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
