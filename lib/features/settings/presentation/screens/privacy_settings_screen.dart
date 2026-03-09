import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPrivacy),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final cubit = context.read<PrivacySettingsCubit>();
              switch (value) {
                case 'public':
                  cubit.setAllPublic();
                  _showSnackBar(context, l10n.settingsPrivacySnackAllPublic);
                  break;
                case 'private':
                  cubit.setAllPrivate();
                  _showSnackBar(context, l10n.settingsPrivacySnackAllPrivate);
                  break;
                case 'reset':
                  cubit.resetToDefaults();
                  _showSnackBar(
                    context,
                    l10n.settingsPrivacySnackResetDefaults,
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'public',
                child: Row(
                  children: [
                    const Icon(Icons.public, size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.makeAllPublic),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'private',
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.makeAllPrivate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.resetToDefaults),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocBuilder<PrivacySettingsCubit, ProfilePrivacySettings>(
              builder: (context, state) {
                final cubit = context.read<PrivacySettingsCubit>();
                final l10n = context.l10n;
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
                              color: DsColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
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
                                  l10n.settingsPrivacyHeaderTitle,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                DsGap.xs,
                                Text(
                                  l10n.settingsPrivacyHeaderSubtitle,
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

                    // Name Visibility Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionNameVisibilityTitle,
                      subtitle:
                          l10n.settingsPrivacySectionNameVisibilitySubtitle,
                      icon: Icons.badge_outlined,
                      color: DsColors.primary,
                    ),
                    _PrivacyTile(
                      icon: Icons.person_outline,
                      title: l10n.settingsPrivacyFirstNameTitle,
                      subtitle: l10n.settingsPrivacyFirstNameSubtitle,
                      value: state.showFirstName,
                      onChanged: cubit.toggleShowFirstName,
                    ),
                    _PrivacyTile(
                      icon: Icons.person,
                      title: l10n.settingsPrivacyLastNameTitle,
                      subtitle: l10n.settingsPrivacyLastNameSubtitle,
                      value: state.showLastName,
                      onChanged: cubit.toggleShowLastName,
                    ),

                    // Sensitive Information Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionSensitiveInfoTitle,
                      subtitle:
                          l10n.settingsPrivacySectionSensitiveInfoSubtitle,
                      icon: Icons.security,
                      color: DsColors.error,
                    ),
                    _PrivacyTile(
                      icon: Icons.cake_outlined,
                      title: l10n.settingsPrivacyAgeTitle,
                      subtitle: l10n.settingsPrivacyAgeSubtitle,
                      value: state.showAge,
                      onChanged: cubit.toggleShowAge,
                    ),
                    _PrivacyTile(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.settingsPrivacyDateOfBirthTitle,
                      subtitle: l10n.settingsPrivacyDateOfBirthSubtitle,
                      value: state.showDateOfBirth,
                      onChanged: cubit.toggleShowDateOfBirth,
                      isSensitive: true,
                    ),
                    _PrivacyTile(
                      icon: Icons.email_outlined,
                      title: l10n.settingsPrivacyEmailTitle,
                      subtitle: l10n.settingsPrivacyEmailSubtitle,
                      value: state.showEmail,
                      onChanged: cubit.toggleShowEmail,
                      isSensitive: true,
                    ),
                    _PrivacyTile(
                      icon: Icons.phone_outlined,
                      title: l10n.settingsPrivacyPhoneNumberTitle,
                      subtitle: l10n.settingsPrivacyPhoneNumberSubtitle,
                      value: state.showPhoneNumber,
                      onChanged: cubit.toggleShowPhoneNumber,
                      isSensitive: true,
                    ),
                    _PrivacyTile(
                      icon: Icons.location_on_outlined,
                      title: l10n.settingsPrivacyExactLocationTitle,
                      subtitle: l10n.settingsPrivacyExactLocationSubtitle,
                      value: state.showExactLocation,
                      onChanged: cubit.toggleShowExactLocation,
                      isSensitive: true,
                    ),

                    // Dating Basics Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionDatingBasicsTitle,
                      subtitle: l10n.settingsPrivacySectionDatingBasicsSubtitle,
                      icon: Icons.favorite_outline,
                      color: DsColors.primary,
                    ),
                    _PrivacyTile(
                      icon: Icons.height,
                      title: l10n.settingsPrivacyHeightTitle,
                      subtitle: l10n.settingsPrivacyHeightSubtitle,
                      value: state.showHeight,
                      onChanged: cubit.toggleShowHeight,
                    ),
                    _PrivacyTile(
                      icon: Icons.favorite,
                      title: l10n.settingsPrivacyRelationshipGoalsTitle,
                      subtitle: l10n.settingsPrivacyRelationshipGoalsSubtitle,
                      value: state.showRelationshipGoals,
                      onChanged: cubit.toggleShowRelationshipGoals,
                    ),
                    _PrivacyTile(
                      icon: Icons.auto_awesome,
                      title: l10n.settingsPrivacyZodiacSignTitle,
                      subtitle: l10n.settingsPrivacyZodiacSignSubtitle,
                      value: state.showZodiacSign,
                      onChanged: cubit.toggleShowZodiacSign,
                    ),

                    // Personal Details Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionAboutMeTitle,
                      subtitle: l10n.settingsPrivacySectionAboutMeSubtitle,
                      icon: Icons.person_outline,
                      color: DsColors.info,
                    ),
                    _PrivacyTile(
                      icon: Icons.school_outlined,
                      title: l10n.settingsPrivacyEducationTitle,
                      subtitle: l10n.settingsPrivacyEducationSubtitle,
                      value: state.showEducation,
                      onChanged: cubit.toggleShowEducation,
                    ),
                    _PrivacyTile(
                      icon: Icons.family_restroom,
                      title: l10n.settingsPrivacyFamilyPlansTitle,
                      subtitle: l10n.settingsPrivacyFamilyPlansSubtitle,
                      value: state.showFamilyPlans,
                      onChanged: cubit.toggleShowFamilyPlans,
                    ),
                    _PrivacyTile(
                      icon: Icons.psychology_outlined,
                      title: l10n.settingsPrivacyPersonalityTypeTitle,
                      subtitle: l10n.settingsPrivacyPersonalityTypeSubtitle,
                      value: state.showPersonality,
                      onChanged: cubit.toggleShowPersonality,
                    ),

                    // Lifestyle Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionLifestyleTitle,
                      subtitle: l10n.settingsPrivacySectionLifestyleSubtitle,
                      icon: Icons.spa_outlined,
                      color: DsColors.success,
                    ),
                    _PrivacyTile(
                      icon: Icons.fitness_center,
                      title: l10n.settingsPrivacyWorkoutTitle,
                      subtitle: l10n.settingsPrivacyWorkoutSubtitle,
                      value: state.showWorkout,
                      onChanged: cubit.toggleShowWorkout,
                    ),
                    _PrivacyTile(
                      icon: Icons.smoking_rooms,
                      title: l10n.settingsPrivacySmokingTitle,
                      subtitle: l10n.settingsPrivacySmokingSubtitle,
                      value: state.showSmoking,
                      onChanged: cubit.toggleShowSmoking,
                    ),
                    _PrivacyTile(
                      icon: Icons.local_bar,
                      title: l10n.settingsPrivacyDrinkingTitle,
                      subtitle: l10n.settingsPrivacyDrinkingSubtitle,
                      value: state.showDrinking,
                      onChanged: cubit.toggleShowDrinking,
                    ),
                    _PrivacyTile(
                      icon: Icons.restaurant_outlined,
                      title: l10n.settingsPrivacyDietTitle,
                      subtitle: l10n.settingsPrivacyDietSubtitle,
                      value: state.showDiet,
                      onChanged: cubit.toggleShowDiet,
                    ),
                    _PrivacyTile(
                      icon: Icons.bedtime_outlined,
                      title: l10n.settingsPrivacySleepingHabitsTitle,
                      subtitle: l10n.settingsPrivacySleepingHabitsSubtitle,
                      value: state.showSleepingHabits,
                      onChanged: cubit.toggleShowSleepingHabits,
                    ),
                    _PrivacyTile(
                      icon: Icons.pets,
                      title: l10n.settingsPrivacyPetsTitle,
                      subtitle: l10n.settingsPrivacyPetsSubtitle,
                      value: state.showPets,
                      onChanged: cubit.toggleShowPets,
                    ),

                    // Work Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionWorkEducationTitle,
                      subtitle:
                          l10n.settingsPrivacySectionWorkEducationSubtitle,
                      icon: Icons.work_outline,
                      color: DsColors.warning,
                    ),
                    _PrivacyTile(
                      icon: Icons.badge_outlined,
                      title: l10n.settingsPrivacyJobTitleTitle,
                      subtitle: l10n.settingsPrivacyJobTitleSubtitle,
                      value: state.showJobTitle,
                      onChanged: cubit.toggleShowJobTitle,
                    ),
                    _PrivacyTile(
                      icon: Icons.business_outlined,
                      title: l10n.settingsPrivacyCompanyTitle,
                      subtitle: l10n.settingsPrivacyCompanySubtitle,
                      value: state.showCompany,
                      onChanged: cubit.toggleShowCompany,
                    ),
                    _PrivacyTile(
                      icon: Icons.school,
                      title: l10n.settingsPrivacySchoolTitle,
                      subtitle: l10n.settingsPrivacySchoolSubtitle,
                      value: state.showSchool,
                      onChanged: cubit.toggleShowSchool,
                    ),

                    // Music Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionMusicTitle,
                      subtitle: l10n.settingsPrivacySectionMusicSubtitle,
                      icon: Icons.music_note_outlined,
                      color: DsColors.secondary,
                    ),
                    _PrivacyTile(
                      icon: Icons.mic_outlined,
                      title: l10n.settingsPrivacyFavoriteSingerTitle,
                      subtitle: l10n.settingsPrivacyFavoriteSingerSubtitle,
                      value: state.showFavoriteSinger,
                      onChanged: cubit.toggleShowFavoriteSinger,
                    ),
                    _PrivacyTile(
                      icon: Icons.queue_music,
                      title: l10n.settingsPrivacyFavoriteSongsTitle,
                      subtitle: l10n.settingsPrivacyFavoriteSongsSubtitle,
                      value: state.showFavoriteSongs,
                      onChanged: cubit.toggleShowFavoriteSongs,
                    ),

                    // Social Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionSocialTitle,
                      subtitle: l10n.settingsPrivacySectionSocialSubtitle,
                      icon: Icons.people_outline,
                      color: DsColors.accent,
                    ),
                    _PrivacyTile(
                      icon: Icons.language,
                      title: l10n.settingsPrivacyLanguagesTitle,
                      subtitle: l10n.settingsPrivacyLanguagesSubtitle,
                      value: state.showLanguages,
                      onChanged: cubit.toggleShowLanguages,
                    ),
                    _PrivacyTile(
                      icon: Icons.share_outlined,
                      title: l10n.settingsPrivacySocialMediaTitle,
                      subtitle: l10n.settingsPrivacySocialMediaSubtitle,
                      value: state.showSocialMedia,
                      onChanged: cubit.toggleShowSocialMedia,
                    ),

                    // Activity Section
                    _SectionHeader(
                      title: l10n.settingsPrivacySectionActivityStatusTitle,
                      subtitle:
                          l10n.settingsPrivacySectionActivityStatusSubtitle,
                      icon: Icons.circle,
                      color: DsColors.success,
                    ),
                    _PrivacyTile(
                      icon: Icons.circle,
                      title: l10n.settingsPrivacyOnlineStatusTitle,
                      subtitle: l10n.settingsPrivacyOnlineStatusSubtitle,
                      value: state.showOnlineStatus,
                      onChanged: cubit.toggleShowOnlineStatus,
                    ),
                    _PrivacyTile(
                      icon: Icons.access_time,
                      title: l10n.settingsPrivacyLastActiveTitle,
                      subtitle: l10n.settingsPrivacyLastActiveSubtitle,
                      value: state.showLastActive,
                      onChanged: cubit.toggleShowLastActive,
                    ),

                    DsGap.xxl,

                    // Info card
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Container(
                        padding: DsEdgeInsets.allMd,
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: isDark
                                  ? DsColors.textMutedDark
                                  : DsColors.textMutedLight,
                            ),
                            DsGap.mdH,
                            Expanded(
                              child: Text(
                                l10n.settingsPrivacyInfoNote,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? DsColors.textMutedDark
                                          : DsColors.textMutedLight,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DsGap.xxl,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
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

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isSensitive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;
  final bool isSensitive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSensitive && value ? DsColors.warning : null,
      ),
      title: Row(
        children: [
          Text(title),
          if (isSensitive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DsColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                context.l10n.settingsPrivacySensitiveBadge,
                style: const TextStyle(
                  fontSize: 10,
                  color: DsColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: isSensitive
            ? DsColors.warning.withValues(alpha: 0.5)
            : DsColors.primary.withValues(alpha: 0.5),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isSensitive ? DsColors.warning : DsColors.primary;
          }
          return null;
        }),
      ),
    );
  }
}
