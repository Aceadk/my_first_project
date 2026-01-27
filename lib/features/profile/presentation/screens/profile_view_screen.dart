import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:crushhour/features/profile/presentation/widgets/prompt_card.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.logInfo('[ProfileViewScreen] initState - requesting profile load');
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        AppLogger.logInfo('[ProfileViewScreen] Building with state: status=${state.status}, isLoading=${state.isLoading}, hasProfile=${state.profile != null}, hasUser=${state.user != null}');

        if (state.isLoading && state.profile == null) {
          AppLogger.logInfo('[ProfileViewScreen] Showing loading skeleton');
          return const Scaffold(
            body: GlassSkeletonProfile(),
          );
        }

        final profile = state.profile;

        // Handle empty state - user exists but hasn't created profile yet
        if (state.status == ProfileStatus.empty || profile == null) {
          final isEmpty = state.status == ProfileStatus.empty;
          AppLogger.logInfo('[ProfileViewScreen] Showing empty/error state: isEmpty=$isEmpty, profile=$profile');
          return Scaffold(
            body: Center(
              child: Padding(
                padding: DsEdgeInsets.allXxl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEmpty ? Icons.person_add_outlined : Icons.person_off,
                        size: 64,
                        color: DsColors.primary,
                      ),
                    ),
                    DsGap.xl,
                    Text(
                      isEmpty ? 'Complete Your Profile' : 'Profile not found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    DsGap.sm,
                    Text(
                      isEmpty
                          ? 'Add your details to start connecting with others'
                          : 'There was a problem loading your profile',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DsColors.textMutedLight),
                    ),
                    DsGap.xl,
                    FilledButton.icon(
                      onPressed: () => isEmpty
                          ? context.push(CrushRoutes.profileEdit)
                          : context.read<ProfileBloc>().add(ProfileLoadRequested()),
                      icon: Icon(isEmpty ? Icons.edit : Icons.refresh),
                      label: Text(isEmpty ? 'Create Profile' : 'Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DsColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final summary = evaluateProfileCompleteness(profile);
        final percent = (summary.score * 100).round();
        final isComplete = summary.missing.isEmpty;
        // Check if profile has basic info (age > 0 means they've filled basic info)
        final hasBasicInfo = profile.age > 0;

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
                    icon: const Icon(Icons.insights_outlined),
                    tooltip: 'Profile Insights',
                    onPressed: () => context.push(CrushRoutes.profileInsights),
                  ),
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
                                  hasBasicInfo ? '${profile.fullName}, ${profile.age}' : profile.fullName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Username display
                                if (state.user?.username != null && state.user!.username!.isNotEmpty) ...[
                                  DsGap.xs,
                                  Row(
                                    children: [
                                      const Icon(Icons.alternate_email, size: 16, color: DsColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        state.user!.username!,
                                        style: const TextStyle(
                                          color: DsColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

                      // Profile completion card (always show if incomplete or missing basic info)
                      if (!isComplete || !hasBasicInfo) ...[
                        _CompletionCard(
                          percent: hasBasicInfo ? percent : 0,
                          missing: hasBasicInfo ? summary.missing : ['age', 'gender', 'bio', 'photos'],
                          isNewProfile: !hasBasicInfo,
                        ),
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

                      // Photos Gallery with blend effect
                      if (profile.photoUrls.isNotEmpty) ...[
                        _InfoSection(
                          title: 'My Photos',
                          icon: Icons.photo_library_outlined,
                          child: _PhotosGrid(photos: profile.photoUrls),
                        ),
                        DsGap.lg,
                      ],

                      // Profile Prompts
                      if (profile.profilePrompts.isNotEmpty) ...[
                        _InfoSection(
                          title: 'Conversation Starters',
                          icon: Icons.chat_bubble_outline,
                          child: PromptCardColumn(
                            prompts: profile.profilePrompts,
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
                              return GlassChip(label: interest);
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
                              return GlassChip(label: lang);
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
                            if (profile.religion != null)
                              _InfoRow(
                                icon: Icons.self_improvement,
                                label: 'Religion',
                                value: ProfileFieldOptions.getReligionLabel(profile.religion) ?? '',
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
                              GlassChip.icon(
                                label: ProfileFieldOptions.getWorkoutLabel(profile.workout) ?? '',
                                icon: Icons.fitness_center,
                              ),
                            if (profile.sleepingHabits != null)
                              GlassChip.icon(
                                label: ProfileFieldOptions.getSleepingLabel(profile.sleepingHabits) ?? '',
                                icon: Icons.bedtime_outlined,
                              ),
                            if (profile.smoking != null)
                              GlassChip.icon(
                                label: ProfileFieldOptions.getSmokingLabel(profile.smoking) ?? '',
                                icon: Icons.smoking_rooms,
                              ),
                            if (profile.drinking != null)
                              GlassChip.icon(
                                label: ProfileFieldOptions.getDrinkingLabel(profile.drinking) ?? '',
                                icon: Icons.local_bar,
                              ),
                            if (profile.pets != null)
                              GlassChip.icon(
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
                                    return GlassChip.icon(label: song, icon: Icons.music_note);
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
        // Hero photo - displayed clearly without blur
        // Uses top-center alignment to prioritize showing face/head area
        if (displayPhoto != null)
          CachedNetworkImage(
            imageUrl: displayPhoto,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter, // Prioritize upper portion (face)
            errorWidget: _buildPlaceholder(),
          )
        else
          _buildPlaceholder(),
        // Subtle gradient overlay at bottom only (for text readability)
        // Does NOT blur or obscure the photo - only adds subtle shadow at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DsColors.ink900.withValues(alpha: 0.5),
                ],
              ),
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
                color: DsColors.ink900.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library, size: 16, color: DsColors.surfaceLight),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.photoUrls.length}',
                    style: const TextStyle(
                      color: DsColors.surfaceLight,
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
  final bool isNewProfile;

  const _CompletionCard({
    required this.percent,
    required this.missing,
    this.isNewProfile = false,
  });

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
                child: Icon(
                  isNewProfile ? Icons.person_add : Icons.trending_up,
                  color: DsColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNewProfile ? 'Set up your profile' : 'Complete your profile',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      isNewProfile
                          ? 'Add your details to start connecting'
                          : '$percent% complete',
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
                child: Text(isNewProfile ? 'Get Started' : 'Complete'),
              ),
            ],
          ),
          if (!isNewProfile) ...[
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
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isNewProfile
                  ? 'Add your age, photos, and more to get started'
                  : 'Add: ${missing.take(3).join(', ')}',
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

/// Grid of photos for user's own profile (no blur/overlay effects)
/// Photos are displayed at full quality with top-center alignment to prioritize faces
class _PhotosGrid extends StatelessWidget {
  final List<String> photos;

  const _PhotosGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Larger photos (2 columns instead of 3)
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8, // Slightly taller aspect ratio for portraits
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(DsRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo - displayed clearly without blur at full quality
              // Uses top-center alignment to prioritize showing face/head area
              CachedNetworkImage(
                imageUrl: photos[index],
                fit: BoxFit.cover,
                alignment: Alignment.topCenter, // Prioritize face area
                placeholder: Container(
                  color: DsGlassColors.surfaceFor(context),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DsColors.primary,
                    ),
                  ),
                ),
                errorWidget: Container(
                  color: DsGlassColors.surfaceFor(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to retry',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Subtle border overlay (no gradient/blur - photos remain clear)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DsRadius.md),
                  border: Border.all(
                    color: DsGlassColors.borderFor(context),
                    width: 1,
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
