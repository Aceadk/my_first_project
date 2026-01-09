import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/privacy/privacy_settings_cubit.dart';
import '../../../data/models/privacy_settings.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing_widgets.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final cubit = context.read<PrivacySettingsCubit>();
              switch (value) {
                case 'public':
                  cubit.setAllPublic();
                  _showSnackBar(context, 'All information set to public');
                  break;
                case 'private':
                  cubit.setAllPrivate();
                  _showSnackBar(context, 'All information set to private');
                  break;
                case 'reset':
                  cubit.resetToDefaults();
                  _showSnackBar(context, 'Privacy settings reset to defaults');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'public',
                child: Row(
                  children: [
                    Icon(Icons.public, size: 20),
                    SizedBox(width: 12),
                    Text('Make all public'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'private',
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 20),
                    SizedBox(width: 12),
                    Text('Make all private'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Reset to defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<PrivacySettingsCubit, ProfilePrivacySettings>(
        builder: (context, state) {
          final cubit = context.read<PrivacySettingsCubit>();
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
                            'Control Your Privacy',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DsGap.xs,
                          Text(
                            'Choose what others can see when they view your profile.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sensitive Information Section
              _SectionHeader(
                title: 'Sensitive Information',
                subtitle: 'These are private by default',
                icon: Icons.security,
                color: Colors.red,
              ),
              _PrivacyTile(
                icon: Icons.cake_outlined,
                title: 'Age',
                subtitle: 'Show your age on your profile',
                value: state.showAge,
                onChanged: cubit.toggleShowAge,
              ),
              _PrivacyTile(
                icon: Icons.calendar_today_outlined,
                title: 'Date of Birth',
                subtitle: 'Show your exact birth date',
                value: state.showDateOfBirth,
                onChanged: cubit.toggleShowDateOfBirth,
                isSensitive: true,
              ),
              _PrivacyTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'Show your email address',
                value: state.showEmail,
                onChanged: cubit.toggleShowEmail,
                isSensitive: true,
              ),
              _PrivacyTile(
                icon: Icons.phone_outlined,
                title: 'Phone Number',
                subtitle: 'Show your phone number',
                value: state.showPhoneNumber,
                onChanged: cubit.toggleShowPhoneNumber,
                isSensitive: true,
              ),
              _PrivacyTile(
                icon: Icons.location_on_outlined,
                title: 'Exact Location',
                subtitle: 'Show exact location instead of city only',
                value: state.showExactLocation,
                onChanged: cubit.toggleShowExactLocation,
                isSensitive: true,
              ),

              // Dating Basics Section
              _SectionHeader(
                title: 'Dating Basics',
                subtitle: 'Basic dating profile information',
                icon: Icons.favorite_outline,
                color: DsColors.primary,
              ),
              _PrivacyTile(
                icon: Icons.height,
                title: 'Height',
                subtitle: 'Show your height',
                value: state.showHeight,
                onChanged: cubit.toggleShowHeight,
              ),
              _PrivacyTile(
                icon: Icons.favorite,
                title: 'Relationship Goals',
                subtitle: 'Show what you\'re looking for',
                value: state.showRelationshipGoals,
                onChanged: cubit.toggleShowRelationshipGoals,
              ),
              _PrivacyTile(
                icon: Icons.auto_awesome,
                title: 'Zodiac Sign',
                subtitle: 'Show your zodiac sign',
                value: state.showZodiacSign,
                onChanged: cubit.toggleShowZodiacSign,
              ),

              // Personal Details Section
              _SectionHeader(
                title: 'About Me',
                subtitle: 'Personal characteristics',
                icon: Icons.person_outline,
                color: Colors.blue,
              ),
              _PrivacyTile(
                icon: Icons.school_outlined,
                title: 'Education',
                subtitle: 'Show your education level',
                value: state.showEducation,
                onChanged: cubit.toggleShowEducation,
              ),
              _PrivacyTile(
                icon: Icons.family_restroom,
                title: 'Family Plans',
                subtitle: 'Show your family plans',
                value: state.showFamilyPlans,
                onChanged: cubit.toggleShowFamilyPlans,
              ),
              _PrivacyTile(
                icon: Icons.psychology_outlined,
                title: 'Personality Type',
                subtitle: 'Show your MBTI or personality',
                value: state.showPersonality,
                onChanged: cubit.toggleShowPersonality,
              ),

              // Lifestyle Section
              _SectionHeader(
                title: 'Lifestyle',
                subtitle: 'Your habits and preferences',
                icon: Icons.spa_outlined,
                color: Colors.green,
              ),
              _PrivacyTile(
                icon: Icons.fitness_center,
                title: 'Workout',
                subtitle: 'Show your exercise habits',
                value: state.showWorkout,
                onChanged: cubit.toggleShowWorkout,
              ),
              _PrivacyTile(
                icon: Icons.smoking_rooms,
                title: 'Smoking',
                subtitle: 'Show your smoking habits',
                value: state.showSmoking,
                onChanged: cubit.toggleShowSmoking,
              ),
              _PrivacyTile(
                icon: Icons.local_bar,
                title: 'Drinking',
                subtitle: 'Show your drinking habits',
                value: state.showDrinking,
                onChanged: cubit.toggleShowDrinking,
              ),
              _PrivacyTile(
                icon: Icons.restaurant_outlined,
                title: 'Diet',
                subtitle: 'Show your dietary preferences',
                value: state.showDiet,
                onChanged: cubit.toggleShowDiet,
              ),
              _PrivacyTile(
                icon: Icons.bedtime_outlined,
                title: 'Sleeping Habits',
                subtitle: 'Show your sleep schedule',
                value: state.showSleepingHabits,
                onChanged: cubit.toggleShowSleepingHabits,
              ),
              _PrivacyTile(
                icon: Icons.pets,
                title: 'Pets',
                subtitle: 'Show your pet preferences',
                value: state.showPets,
                onChanged: cubit.toggleShowPets,
              ),

              // Work Section
              _SectionHeader(
                title: 'Work & Education',
                subtitle: 'Professional information',
                icon: Icons.work_outline,
                color: Colors.orange,
              ),
              _PrivacyTile(
                icon: Icons.badge_outlined,
                title: 'Job Title',
                subtitle: 'Show your job title',
                value: state.showJobTitle,
                onChanged: cubit.toggleShowJobTitle,
              ),
              _PrivacyTile(
                icon: Icons.business_outlined,
                title: 'Company',
                subtitle: 'Show where you work',
                value: state.showCompany,
                onChanged: cubit.toggleShowCompany,
              ),
              _PrivacyTile(
                icon: Icons.school,
                title: 'School',
                subtitle: 'Show your school or university',
                value: state.showSchool,
                onChanged: cubit.toggleShowSchool,
              ),

              // Music Section
              _SectionHeader(
                title: 'Music',
                subtitle: 'Your music taste',
                icon: Icons.music_note_outlined,
                color: Colors.purple,
              ),
              _PrivacyTile(
                icon: Icons.mic_outlined,
                title: 'Favorite Singer',
                subtitle: 'Show your favorite artist',
                value: state.showFavoriteSinger,
                onChanged: cubit.toggleShowFavoriteSinger,
              ),
              _PrivacyTile(
                icon: Icons.queue_music,
                title: 'Favorite Songs',
                subtitle: 'Show your favorite songs',
                value: state.showFavoriteSongs,
                onChanged: cubit.toggleShowFavoriteSongs,
              ),

              // Social Section
              _SectionHeader(
                title: 'Social',
                subtitle: 'Social information',
                icon: Icons.people_outline,
                color: Colors.teal,
              ),
              _PrivacyTile(
                icon: Icons.language,
                title: 'Languages',
                subtitle: 'Show languages you speak',
                value: state.showLanguages,
                onChanged: cubit.toggleShowLanguages,
              ),
              _PrivacyTile(
                icon: Icons.share_outlined,
                title: 'Social Media',
                subtitle: 'Show your social media links',
                value: state.showSocialMedia,
                onChanged: cubit.toggleShowSocialMedia,
              ),

              // Activity Section
              _SectionHeader(
                title: 'Activity Status',
                subtitle: 'Online presence',
                icon: Icons.circle,
                color: Colors.green,
              ),
              _PrivacyTile(
                icon: Icons.circle,
                title: 'Online Status',
                subtitle: 'Show when you\'re online',
                value: state.showOnlineStatus,
                onChanged: cubit.toggleShowOnlineStatus,
              ),
              _PrivacyTile(
                icon: Icons.access_time,
                title: 'Last Active',
                subtitle: 'Show when you were last active',
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
                    color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? DsColors.borderDark : DsColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Text(
                          'Hidden information will only be visible to you. Matches can see public information.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
        color: isSensitive && value ? Colors.orange : null,
      ),
      title: Row(
        children: [
          Text(title),
          if (isSensitive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Sensitive',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
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
            ? Colors.orange.withValues(alpha: 0.5)
            : DsColors.primary.withValues(alpha: 0.5),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isSensitive ? Colors.orange : DsColors.primary;
          }
          return null;
        }),
      ),
    );
  }
}
