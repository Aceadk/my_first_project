import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/profile.dart';
import '../../data/models/privacy_settings.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/spacing_widgets.dart';
import '../../shared/widgets/cached_image.dart';

/// Arguments for viewing another user's profile
class OtherUserProfileArgs {
  final Profile profile;
  final bool isMatch; // If true, show more info (they matched with you)

  const OtherUserProfileArgs({
    required this.profile,
    this.isMatch = false,
  });
}

/// Screen for viewing another user's profile with privacy settings respected.
class OtherUserProfileScreen extends StatelessWidget {
  final OtherUserProfileArgs args;

  const OtherUserProfileScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final profile = args.profile;
    final privacy = profile.privacySettings;
    final isMatch = args.isMatch;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header with photo
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
                onPressed: () => _showOptionsMenu(context, profile),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  privacy.showAge
                                      ? '${profile.name}, ${profile.age}'
                                      : profile.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (profile.isVerified) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified,
                                    color: DsColors.primary,
                                    size: 24,
                                  ),
                                ],
                              ],
                            ),
                            if (profile.livingIn != null &&
                                profile.livingIn!.isNotEmpty) ...[
                              DsGap.xs,
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: DsColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    privacy.showExactLocation
                                        ? profile.livingIn!
                                        : '${profile.city}, ${profile.country}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (privacy.showJobTitle &&
                                (profile.jobTitle != null ||
                                    profile.company != null)) ...[
                              DsGap.xs,
                              Row(
                                children: [
                                  const Icon(Icons.work_outline,
                                      size: 16, color: DsColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      [
                                        if (privacy.showJobTitle)
                                          profile.jobTitle,
                                        if (privacy.showCompany) profile.company
                                      ]
                                          .where(
                                              (s) => s != null && s.isNotEmpty)
                                          .join(' at '),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
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
                    ],
                  ),
                  DsGap.lg,

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

                  // Dating Basics (respecting privacy)
                  if (_hasDatingBasics(profile, privacy)) ...[
                    _InfoSection(
                      title: 'Dating Basics',
                      icon: Icons.favorite_outline,
                      child: Column(
                        children: [
                          if (privacy.showHeight && profile.heightCm != null)
                            _InfoRow(
                              icon: Icons.height,
                              label: 'Height',
                              value: ProfileFieldOptions.formatHeightDisplay(
                                  profile.heightCm!),
                            ),
                          if (privacy.showRelationshipGoals &&
                              profile.relationshipGoals != null)
                            _InfoRow(
                              icon: Icons.favorite,
                              label: 'Looking for',
                              value:
                                  ProfileFieldOptions.getRelationshipGoalLabel(
                                          profile.relationshipGoals) ??
                                      '',
                            ),
                          if (privacy.showZodiacSign &&
                              profile.zodiacSign != null)
                            _InfoRow(
                              icon: Icons.auto_awesome,
                              label: 'Zodiac',
                              value: ProfileFieldOptions.getZodiacLabel(
                                      profile.zodiacSign) ??
                                  '',
                            ),
                        ],
                      ),
                    ),
                    DsGap.lg,
                  ],

                  // Languages
                  if (privacy.showLanguages && profile.languages.isNotEmpty) ...[
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

                  // More About Me (respecting privacy)
                  if (_hasAboutMe(profile, privacy)) ...[
                    _InfoSection(
                      title: 'More About Me',
                      icon: Icons.psychology_outlined,
                      child: Column(
                        children: [
                          if (privacy.showEducation &&
                              profile.educationLevel != null)
                            _InfoRow(
                              icon: Icons.school_outlined,
                              label: 'Education',
                              value: ProfileFieldOptions.getEducationLabel(
                                      profile.educationLevel) ??
                                  '',
                            ),
                          if (privacy.showFamilyPlans &&
                              profile.familyPlans != null)
                            _InfoRow(
                              icon: Icons.family_restroom,
                              label: 'Family Plans',
                              value: ProfileFieldOptions.getFamilyPlanLabel(
                                      profile.familyPlans) ??
                                  '',
                            ),
                          if (privacy.showPersonality &&
                              profile.personalityType != null)
                            _InfoRow(
                              icon: Icons.emoji_people,
                              label: 'Personality',
                              value: ProfileFieldOptions.getPersonalityLabel(
                                      profile.personalityType) ??
                                  '',
                            ),
                        ],
                      ),
                    ),
                    DsGap.lg,
                  ],

                  // Lifestyle (respecting privacy)
                  if (_hasLifestyle(profile, privacy)) ...[
                    _InfoSection(
                      title: 'Lifestyle',
                      icon: Icons.spa_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (privacy.showWorkout && profile.workout != null)
                            _InfoChip(
                              label: ProfileFieldOptions.getWorkoutLabel(
                                      profile.workout) ??
                                  '',
                              icon: Icons.fitness_center,
                            ),
                          if (privacy.showSleepingHabits &&
                              profile.sleepingHabits != null)
                            _InfoChip(
                              label: ProfileFieldOptions.getSleepingLabel(
                                      profile.sleepingHabits) ??
                                  '',
                              icon: Icons.bedtime_outlined,
                            ),
                          if (privacy.showSmoking && profile.smoking != null)
                            _InfoChip(
                              label: ProfileFieldOptions.getSmokingLabel(
                                      profile.smoking) ??
                                  '',
                              icon: Icons.smoking_rooms,
                            ),
                          if (privacy.showDrinking && profile.drinking != null)
                            _InfoChip(
                              label: ProfileFieldOptions.getDrinkingLabel(
                                      profile.drinking) ??
                                  '',
                              icon: Icons.local_bar,
                            ),
                          if (privacy.showPets && profile.pets != null)
                            _InfoChip(
                              label: ProfileFieldOptions.getPetLabel(
                                      profile.pets) ??
                                  '',
                              icon: Icons.pets,
                            ),
                        ],
                      ),
                    ),
                    DsGap.lg,
                  ],

                  // Music (respecting privacy)
                  if (_hasMusic(profile, privacy)) ...[
                    _InfoSection(
                      title: 'Music',
                      icon: Icons.music_note_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (privacy.showFavoriteSinger &&
                              profile.favoriteSinger != null)
                            _InfoRow(
                              icon: Icons.person,
                              label: 'Favorite Artist',
                              value: profile.favoriteSinger!,
                            ),
                          if (privacy.showFavoriteSongs &&
                              profile.favoriteSongs.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.favoriteSongs.map((song) {
                                return _InfoChip(
                                    label: song, icon: Icons.music_note);
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    DsGap.lg,
                  ],

                  // Contact info (only for matches and if public)
                  if (isMatch) ...[
                    if (privacy.showEmail || privacy.showPhoneNumber) ...[
                      _InfoSection(
                        title: 'Contact',
                        icon: Icons.contact_mail_outlined,
                        child: Column(
                          children: [
                            // Email and phone are very sensitive - only show to matches
                            if (privacy.showEmail)
                              const _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: 'Contact via chat first',
                              ),
                            if (privacy.showPhoneNumber)
                              const _InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: 'Contact via chat first',
                              ),
                          ],
                        ),
                      ),
                      DsGap.lg,
                    ],
                  ],

                  DsGap.xxl,
                ],
              ),
            ),
          ),
        ],
      ),
      // Action buttons at bottom
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Dislike button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Pass'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Like button
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liked!')),
                    );
                    context.pop();
                  },
                  icon: const Icon(Icons.favorite),
                  label: const Text('Like'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DsColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasDatingBasics(Profile profile, ProfilePrivacySettings privacy) {
    return (privacy.showHeight && profile.heightCm != null) ||
        (privacy.showRelationshipGoals && profile.relationshipGoals != null) ||
        (privacy.showZodiacSign && profile.zodiacSign != null);
  }

  bool _hasAboutMe(Profile profile, ProfilePrivacySettings privacy) {
    return (privacy.showEducation && profile.educationLevel != null) ||
        (privacy.showFamilyPlans && profile.familyPlans != null) ||
        (privacy.showPersonality && profile.personalityType != null);
  }

  bool _hasLifestyle(Profile profile, ProfilePrivacySettings privacy) {
    return (privacy.showWorkout && profile.workout != null) ||
        (privacy.showSleepingHabits && profile.sleepingHabits != null) ||
        (privacy.showSmoking && profile.smoking != null) ||
        (privacy.showDrinking && profile.drinking != null) ||
        (privacy.showPets && profile.pets != null);
  }

  bool _hasMusic(Profile profile, ProfilePrivacySettings privacy) {
    return (privacy.showFavoriteSinger && profile.favoriteSinger != null) ||
        (privacy.showFavoriteSongs && profile.favoriteSongs.isNotEmpty);
  }

  void _showOptionsMenu(BuildContext context, Profile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User blocked')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final Profile profile;

  const _ProfileHeader({required this.profile});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = widget.profile.photoUrls.isNotEmpty;
    final photoCount = widget.profile.photoUrls.length;

    return GestureDetector(
      onTapUp: (details) {
        if (!hasPhotos || photoCount <= 1) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final tapX = details.globalPosition.dx;

        setState(() {
          if (tapX < screenWidth / 2) {
            // Tap left - previous photo
            _currentPhotoIndex =
                (_currentPhotoIndex - 1 + photoCount) % photoCount;
          } else {
            // Tap right - next photo
            _currentPhotoIndex = (_currentPhotoIndex + 1) % photoCount;
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhotos)
            CachedImage(
              imageUrl: widget.profile.photoUrls[_currentPhotoIndex],
              fit: BoxFit.cover,
              errorWidget: _buildPlaceholder(),
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
          // Photo indicators
          if (photoCount > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(photoCount, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentPhotoIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
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
