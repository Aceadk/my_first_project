import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:crushhour/features/profile/presentation/widgets/prompt_card.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';

/// Arguments for viewing another user's profile
class OtherUserProfileArgs {
  final Profile profile;
  final bool isMatch; // If true, show more info (they matched with you)
  final String? matchId;

  const OtherUserProfileArgs({
    required this.profile,
    this.isMatch = false,
    this.matchId,
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
    final matchId = args.matchId;
    // Show full real name when viewing someone's profile (first + last name)
    final displayName =
        profile.fullName.isNotEmpty ? profile.fullName : 'Someone new';

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
                  color: DsColors.ink900.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back, color: DsColors.surfaceLight),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DsColors.ink900.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.more_vert, color: DsColors.surfaceLight),
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
                                      ? '$displayName, ${profile.age}'
                                      : displayName,
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
                  if (privacy.showLanguages &&
                      profile.languages.isNotEmpty) ...[
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
                          if (privacy.showReligion && profile.religion != null)
                            _InfoRow(
                              icon: Icons.self_improvement,
                              label: 'Religion',
                              value: ProfileFieldOptions.getReligionLabel(
                                      profile.religion) ??
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
                            GlassChip.icon(
                              label: ProfileFieldOptions.getWorkoutLabel(
                                      profile.workout) ??
                                  '',
                              icon: Icons.fitness_center,
                            ),
                          if (privacy.showSleepingHabits &&
                              profile.sleepingHabits != null)
                            GlassChip.icon(
                              label: ProfileFieldOptions.getSleepingLabel(
                                      profile.sleepingHabits) ??
                                  '',
                              icon: Icons.bedtime_outlined,
                            ),
                          if (privacy.showSmoking && profile.smoking != null)
                            GlassChip.icon(
                              label: ProfileFieldOptions.getSmokingLabel(
                                      profile.smoking) ??
                                  '',
                              icon: Icons.smoking_rooms,
                            ),
                          if (privacy.showDrinking && profile.drinking != null)
                            GlassChip.icon(
                              label: ProfileFieldOptions.getDrinkingLabel(
                                      profile.drinking) ??
                                  '',
                              icon: Icons.local_bar,
                            ),
                          if (privacy.showPets && profile.pets != null)
                            GlassChip.icon(
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
                                return GlassChip.icon(
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
              color: DsColors.ink900.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: isMatch
              ? SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _handleSendMessage(
                        context,
                        profile,
                        isMatch: true,
                        matchId: matchId,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Send Message'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DsColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                )
              : Row(
                  children: [
                    // Dislike button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _handlePass(context, profile);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Pass'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: DsColors.ink300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<bool>(
                        future: _hasPendingMessageRequest(context, profile),
                        builder: (context, snapshot) {
                          final hasPending = snapshot.data ?? false;
                          return FilledButton.icon(
                            onPressed: hasPending
                                ? null
                                : () async {
                                    await _handleSendMessage(
                                      context,
                                      profile,
                                      isMatch: false,
                                      matchId: matchId,
                                    );
                                  },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(
                                hasPending ? 'Request Sent' : 'Send Message'),
                            style: FilledButton.styleFrom(
                              backgroundColor: DsColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Like button
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await _handleLike(context, profile);
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

  Future<bool> _hasPendingMessageRequest(
    BuildContext context,
    Profile profile,
  ) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return true;
    return context.read<ChatRepository>().hasPendingMessageRequest(
          userId: userId,
          otherUserId: profile.id,
        );
  }

  bool _isCurrentDeckProfile(DiscoveryState state, String profileId) {
    if (state.deck.isEmpty) return false;
    if (state.currentIndex < 0 || state.currentIndex >= state.deck.length) {
      return false;
    }
    return state.deck[state.currentIndex].id == profileId;
  }

  void _returnToDeck(BuildContext context, {required bool preferPop}) {
    if (preferPop && Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(CrushRoutes.home);
  }

  Future<void> _handlePass(BuildContext context, Profile profile) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      showErrorSnackBar(context, 'Sign in again to pass on profiles.');
      return;
    }

    final discoveryBloc = context.read<DiscoveryBloc>();
    final isDeckProfile =
        _isCurrentDeckProfile(discoveryBloc.state, profile.id);

    if (isDeckProfile) {
      discoveryBloc.add(
        DiscoverySwipedLeft(
          userId: userId,
          targetUserId: profile.id,
        ),
      );
      if (context.mounted) {
        _returnToDeck(context, preferPop: true);
      }
      return;
    }

    try {
      await context.read<DiscoveryRepository>().swipeLeft(
            userId: userId,
            targetUserId: profile.id,
          );
      if (!context.mounted) return;
      discoveryBloc.add(DiscoveryDeckRequested(userId));
      _returnToDeck(context, preferPop: false);
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not pass. Please try again.');
      }
    }
  }

  Future<void> _handleLike(BuildContext context, Profile profile) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      showErrorSnackBar(context, 'Sign in again to like profiles.');
      return;
    }

    final discoveryBloc = context.read<DiscoveryBloc>();
    final isDeckProfile =
        _isCurrentDeckProfile(discoveryBloc.state, profile.id);

    if (isDeckProfile) {
      discoveryBloc.add(
        DiscoverySwipedRight(
          userId: userId,
          targetUserId: profile.id,
        ),
      );
      if (context.mounted) {
        _returnToDeck(context, preferPop: true);
      }
      return;
    }

    try {
      final match = await context.read<DiscoveryRepository>().swipeRight(
            userId: userId,
            targetUserId: profile.id,
          );
      if (!context.mounted) return;

      if (match != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("It's a match with ${profile.publicDisplayName}!"),
            backgroundColor: DsColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liked!')),
        );
      }

      discoveryBloc.add(DiscoveryDeckRequested(userId));
      _returnToDeck(context, preferPop: false);
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(
            context, 'Could not like this profile. Please try again.');
      }
    }
  }

  Future<void> _handleSendMessage(
    BuildContext context,
    Profile profile, {
    required bool isMatch,
    required String? matchId,
  }) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      showErrorSnackBar(context, 'Sign in again to send messages.');
      return;
    }

    if (isMatch) {
      if (matchId == null || matchId.isEmpty) {
        showErrorSnackBar(context, 'Could not open chat. Please try again.');
        return;
      }
      context.push(
        '${CrushRoutes.chat}/$matchId',
        extra: ChatScreenArgs(
          matchId: matchId,
          currentUserId: userId,
          otherUserId: profile.id,
          otherName: profile.publicDisplayName,
          otherPhotoUrl:
              profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null,
        ),
      );
      return;
    }

    final hasPending = await _hasPendingMessageRequest(context, profile);
    if (!context.mounted) return;
    if (hasPending) {
      showErrorSnackBar(context, 'You already sent a message request.');
      return;
    }

    await _showMessageRequestComposer(context, profile);
  }

  Future<void> _showMessageRequestComposer(
    BuildContext context,
    Profile profile,
  ) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    final controller = TextEditingController();
    var isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send a message request',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Say something to start the conversation...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSending
                            ? null
                            : () async {
                                final content = controller.text.trim();
                                if (content.isEmpty) {
                                  showErrorSnackBar(
                                      context, 'Message cannot be empty.');
                                  return;
                                }
                                setState(() => isSending = true);
                                try {
                                  final currentProfile = context
                                      .read<AuthBloc>()
                                      .state
                                      .user
                                      ?.profile;
                                  final request = await context
                                      .read<ChatRepository>()
                                      .sendMessageRequest(
                                        fromUserId: userId,
                                        toUserId: profile.id,
                                        content: content,
                                        type: MessageType.text,
                                        fromUserName:
                                            currentProfile?.publicDisplayName,
                                        fromUserPhotoUrl: currentProfile
                                                    ?.photoUrls.isNotEmpty ==
                                                true
                                            ? currentProfile!.photoUrls.first
                                            : null,
                                        toUserName: profile.publicDisplayName,
                                        toUserPhotoUrl:
                                            profile.photoUrls.isNotEmpty
                                                ? profile.photoUrls.first
                                                : null,
                                      );
                                  if (!context.mounted) return;
                                  if (request == null) {
                                    showErrorSnackBar(context,
                                        'You already sent a message request.');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Message request sent.')),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    showErrorSnackBar(context,
                                        'Could not send request. Please try again.');
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isSending = false);
                                  }
                                }
                              },
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(isSending ? 'Sending...' : 'Send Request'),
                        style: FilledButton.styleFrom(
                          backgroundColor: DsColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can send only one message request before a match.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: DsColors.textMutedLight),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  bool _hasDatingBasics(Profile profile, ProfilePrivacySettings privacy) {
    return (privacy.showHeight && profile.heightCm != null) ||
        (privacy.showRelationshipGoals && profile.relationshipGoals != null) ||
        (privacy.showZodiacSign && profile.zodiacSign != null);
  }

  bool _hasAboutMe(Profile profile, ProfilePrivacySettings privacy) {
    return (privacy.showEducation && profile.educationLevel != null) ||
        (privacy.showFamilyPlans && profile.familyPlans != null) ||
        (privacy.showPersonality && profile.personalityType != null) ||
        (privacy.showReligion && profile.religion != null);
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
    final currentUserId = context.read<AuthBloc>().state.user?.id;
    final safetyCubit = context.read<SafetyCubit>();
    final isBlocked = safetyCubit.isBlocked(profile.id);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showReportDialog(context, profile, safetyCubit, currentUserId);
              },
            ),
            ListTile(
              leading: Icon(isBlocked ? Icons.check_circle : Icons.block),
              title: Text(isBlocked ? 'Unblock' : 'Block'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (currentUserId == null) {
                  showErrorSnackBar(
                      context, 'Sign in again to manage safety actions.');
                  return;
                }
                await safetyCubit.toggleBlock(
                  profile.id,
                  block: !isBlocked,
                  currentUserId: currentUserId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(isBlocked ? 'User unblocked' : 'User blocked'),
                    ),
                  );
                  if (!isBlocked) {
                    // Go back after blocking
                    context.pop();
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                safetyCubit.isMessagesMuted(profile.id)
                    ? Icons.volume_up
                    : Icons.volume_off,
              ),
              title: Text(
                safetyCubit.isMessagesMuted(profile.id)
                    ? 'Unmute Messages'
                    : 'Mute Messages',
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final isMuted = safetyCubit.isMessagesMuted(profile.id);
                await safetyCubit.toggleMuteMessages(profile.id,
                    mute: !isMuted);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(isMuted ? 'Messages unmuted' : 'Messages muted'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                safetyCubit.isCallsMuted(profile.id)
                    ? Icons.call
                    : Icons.call_end,
              ),
              title: Text(
                safetyCubit.isCallsMuted(profile.id)
                    ? 'Unmute Calls'
                    : 'Mute Calls',
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final isMuted = safetyCubit.isCallsMuted(profile.id);
                await safetyCubit.toggleMuteCalls(profile.id, mute: !isMuted);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isMuted ? 'Calls unmuted' : 'Calls muted'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(sheetContext);
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

  void _showReportDialog(
    BuildContext context,
    Profile profile,
    SafetyCubit safetyCubit,
    String? currentUserId,
  ) {
    final reasons = [
      'Inappropriate photos',
      'Fake profile',
      'Harassment',
      'Scam or spam',
      'Underage user',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Why are you reporting this profile?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(reason),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await safetyCubit.reportWithContext(
                    reporterId: currentUserId ?? 'anonymous',
                    reportedId: profile.id,
                    reason: reason,
                    source: 'profile_view',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Report submitted. Thanks for keeping Crush safe!'),
                      ),
                    );
                  }
                },
              ),
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
            CachedNetworkImage(
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
                  DsColors.ink900.withValues(alpha: 0.7),
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
                            ? DsColors.surfaceLight
                            : DsColors.surfaceLight.withValues(alpha: 0.4),
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
