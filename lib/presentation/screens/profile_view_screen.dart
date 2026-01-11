import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../data/models/profile.dart';
import '../../core/profile_field_options.dart';
import '../../core/profile_completeness.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/spacing_widgets.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state.isLoading && state.profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = state.profile;
        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: DsColors.textMutedLight),
                  DsGap.lg,
                  const Text('Profile not found'),
                  DsGap.lg,
                  FilledButton(
                    onPressed: () => context.read<ProfileBloc>().add(ProfileLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = evaluateProfileCompleteness(profile);
        final percent = (summary.score * 100).round();
        final isComplete = summary.missing.isEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Profile Header with photo
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(CrushRoutes.settings),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(profile: profile),
                ),
              ),
              // Profile Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: DsEdgeInsets.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and basic info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (profile.livingIn != null && profile.livingIn!.isNotEmpty) ...[
                                  DsGap.xs,
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: DsColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile.livingIn!,
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (profile.jobTitle != null || profile.company != null) ...[
                                  DsGap.xs,
                                  Row(
                                    children: [
                                      const Icon(Icons.work_outline, size: 16, color: DsColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          [profile.jobTitle, profile.company]
                                              .where((s) => s != null && s.isNotEmpty)
                                              .join(' at '),
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Edit button
                          FilledButton.icon(
                            onPressed: () => context.push(CrushRoutes.profileEdit),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: FilledButton.styleFrom(
                              backgroundColor: DsColors.primary,
                            ),
                          ),
                        ],
                      ),
                      DsGap.lg,

                      // Profile completion card (if not complete)
                      if (!isComplete) ...[
                        _CompletionCard(percent: percent, missing: summary.missing),
                        DsGap.lg,
                      ],

                      // About
                      if (profile.bio.isNotEmpty) ...[
                        _InfoSection(
                          title: 'About',
                          icon: Icons.person_outline,
                          child: Text(
                            profile.bio,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                        DsGap.lg,
                      ],

                      // Interests
                      if (profile.interests.isNotEmpty) ...[
                        _InfoSection(
                          title: 'Interests',
                          icon: Icons.interests_outlined,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.interests.map((interest) {
                              return _InfoChip(label: interest);
                            }).toList(),
                          ),
                        ),
                        DsGap.lg,
                      ],

                      // Dating Basics
                      _InfoSection(
                        title: 'Dating Basics',
                        icon: Icons.favorite_outline,
                        child: Column(
                          children: [
                            if (profile.heightCm != null)
                              _InfoRow(
                                icon: Icons.height,
                                label: 'Height',
                                value: ProfileFieldOptions.formatHeightDisplay(profile.heightCm!),
                              ),
                            if (profile.relationshipGoals != null)
                              _InfoRow(
                                icon: Icons.favorite,
                                label: 'Looking for',
                                value: ProfileFieldOptions.getRelationshipGoalLabel(profile.relationshipGoals) ?? '',
                              ),
                            if (profile.zodiacSign != null)
                              _InfoRow(
                                icon: Icons.auto_awesome,
                                label: 'Zodiac',
                                value: ProfileFieldOptions.getZodiacLabel(profile.zodiacSign) ?? '',
                              ),
                          ],
                        ),
                      ),
                      DsGap.lg,

                      // Languages
                      if (profile.languages.isNotEmpty) ...[
                        _InfoSection(
                          title: 'Languages',
                          icon: Icons.language,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.languages.map((lang) {
                              return _InfoChip(label: lang);
                            }).toList(),
                          ),
                        ),
                        DsGap.lg,
                      ],

                      // More About Me
                      _InfoSection(
                        title: 'More About Me',
                        icon: Icons.psychology_outlined,
                        child: Column(
                          children: [
                            if (profile.educationLevel != null)
                              _InfoRow(
                                icon: Icons.school_outlined,
                                label: 'Education',
                                value: ProfileFieldOptions.getEducationLabel(profile.educationLevel) ?? '',
                              ),
                            if (profile.familyPlans != null)
                              _InfoRow(
                                icon: Icons.family_restroom,
                                label: 'Family Plans',
                                value: ProfileFieldOptions.getFamilyPlanLabel(profile.familyPlans) ?? '',
                              ),
                            if (profile.personalityType != null)
                              _InfoRow(
                                icon: Icons.emoji_people,
                                label: 'Personality',
                                value: ProfileFieldOptions.getPersonalityLabel(profile.personalityType) ?? '',
                              ),
                          ],
                        ),
                      ),
                      DsGap.lg,

                      // Lifestyle
                      _InfoSection(
                        title: 'Lifestyle',
                        icon: Icons.spa_outlined,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (profile.workout != null)
                              _InfoChip(
                                label: ProfileFieldOptions.getWorkoutLabel(profile.workout) ?? '',
                                icon: Icons.fitness_center,
                              ),
                            if (profile.sleepingHabits != null)
                              _InfoChip(
                                label: ProfileFieldOptions.getSleepingLabel(profile.sleepingHabits) ?? '',
                                icon: Icons.bedtime_outlined,
                              ),
                            if (profile.smoking != null)
                              _InfoChip(
                                label: ProfileFieldOptions.getSmokingLabel(profile.smoking) ?? '',
                                icon: Icons.smoking_rooms,
                              ),
                            if (profile.drinking != null)
                              _InfoChip(
                                label: ProfileFieldOptions.getDrinkingLabel(profile.drinking) ?? '',
                                icon: Icons.local_bar,
                              ),
                            if (profile.pets != null)
                              _InfoChip(
                                label: ProfileFieldOptions.getPetLabel(profile.pets) ?? '',
                                icon: Icons.pets,
                              ),
                          ],
                        ),
                      ),
                      DsGap.lg,

                      // Music
                      if (profile.favoriteSinger != null || profile.favoriteSongs.isNotEmpty) ...[
                        _InfoSection(
                          title: 'Music',
                          icon: Icons.music_note_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (profile.favoriteSinger != null)
                                _InfoRow(
                                  icon: Icons.person,
                                  label: 'Favorite Artist',
                                  value: profile.favoriteSinger!,
                                ),
                              if (profile.favoriteSongs.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profile.favoriteSongs.map((song) {
                                    return _InfoChip(label: song, icon: Icons.music_note);
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DsGap.lg,
                      ],

                      DsGap.xxl,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Profile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final displayPhoto = profile.displayPhotoUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (displayPhoto != null)
          Image.network(
            displayPhoto,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          )
        else
          _buildPlaceholder(),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        // Photo count badge
        if (profile.photoUrls.length > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.photoUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: DsColors.primary.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 80,
          color: DsColors.primary,
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final int percent;
  final List<String> missing;

  const _CompletionCard({required this.percent, required this.missing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DsColors.primary.withValues(alpha: 0.15),
            DsColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DsColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DsColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up, color: DsColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete your profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '$percent% complete',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push(CrushRoutes.profileEdit),
                style: FilledButton.styleFrom(
                  backgroundColor: DsColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Complete'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: DsColors.primary.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(DsColors.primary),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Add: ${missing.take(3).join(', ')}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(DsSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? DsColors.borderDark : DsColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: DsColors.primary),
              const SizedBox(width: DsSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DsColors.textMutedLight),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _InfoChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? DsColors.inputFillDark : DsColors.inputFillLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: DsColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
