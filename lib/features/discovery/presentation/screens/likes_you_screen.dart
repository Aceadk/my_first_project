import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:crushhour/design_system/widgets/skeleton_loader.dart';

/// Screen showing profiles that have liked the current user.
/// Free users see blurred profiles; Premium users see full profiles.
class LikesYouScreen extends StatefulWidget {
  const LikesYouScreen({super.key});

  @override
  State<LikesYouScreen> createState() => _LikesYouScreenState();
}

class _LikesYouScreenState extends State<LikesYouScreen> {
  List<Profile>? _profiles;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DiscoveryRepository>();
      final profiles = await repo.fetchLikesYou(userId);

      if (mounted) {
        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });

        // Track analytics
        AnalyticsService.instance.logLikesYouViewed(count: profiles.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load likes. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = context.select<SubscriptionBloc, bool>(
      (bloc) => bloc.state.plan == SubscriptionPlan.plus,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes You'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLikes,
          ),
        ],
      ),
      body: _buildBody(context, isDark, isPremium),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, bool isPremium) {
    if (_isLoading) {
      return const SkeletonGrid(
        itemCount: 6,
        crossAxisCount: 2,
        childAspectRatio: 0.75,
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DsColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: DsSpacing.md),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DsSpacing.lg),
            GlassPrimaryButton(
              onPressed: _loadLikes,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final profiles = _profiles ?? [];

    if (profiles.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return Stack(
      children: [
        // Profile grid
        GridView.builder(
          padding: const EdgeInsets.all(DsSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: DsSpacing.sm,
            mainAxisSpacing: DsSpacing.sm,
            childAspectRatio: 0.75,
          ),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            return _LikeCard(
              profile: profiles[index],
              isBlurred: !isPremium,
              onTap: isPremium
                  ? () => _showProfileDetail(profiles[index])
                  : () => _showUpgradePrompt(context),
            );
          },
        ),

        // Upgrade overlay for free users
        if (!isPremium && profiles.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildUpgradeOverlay(context, isDark, profiles.length),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xl),
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
                Icons.favorite_border,
                size: 64,
                color: DsColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            Text(
              'No likes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(
              'Keep swiping and completing your profile to get more likes!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeOverlay(BuildContext context, bool isDark, int count) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.medium, sigmaY: DsBlur.medium),
        child: Container(
          padding: const EdgeInsets.all(DsSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.lg,
                    vertical: DsSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DsColors.primary, DsColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: DsSpacing.xs),
                      Text(
                        '$count ${count == 1 ? 'person likes' : 'people like'} you',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                Text(
                  'Upgrade to Crush Plus to see who likes you and match instantly!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DsSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: GlassPrimaryButton(
                    onPressed: () => _showUpgradePrompt(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 20),
                        SizedBox(width: 8),
                        Text('Upgrade to Plus'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileDetail(Profile profile) {
    HapticFeedback.lightImpact();
    // Navigate to profile detail or show bottom sheet
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileDetailSheet(
        profile: profile,
        onLikeBack: () {
          Navigator.pop(context);
          _likeBack(profile);
        },
        onPass: () {
          Navigator.pop(context);
          _pass(profile);
        },
      ),
    );
  }

  void _likeBack(Profile profile) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    HapticFeedback.mediumImpact();

    try {
      final repo = context.read<DiscoveryRepository>();
      final match = await repo.swipeRight(
        userId: userId,
        targetUserId: profile.id,
      );

      if (match != null && mounted) {
        // It's a match! Show celebration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("It's a match with ${profile.publicDisplayName}!"),
            backgroundColor: DsColors.success,
          ),
        );
      }

      // Remove from list
      setState(() {
        _profiles?.removeWhere((p) => p.id == profile.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not like back. Please try again.'),
            backgroundColor: DsColors.error,
          ),
        );
      }
    }
  }

  void _pass(Profile profile) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    try {
      final repo = context.read<DiscoveryRepository>();
      await repo.swipeLeft(
        userId: userId,
        targetUserId: profile.id,
      );

      // Remove from list
      setState(() {
        _profiles?.removeWhere((p) => p.id == profile.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not pass. Please try again.'),
            backgroundColor: DsColors.error,
          ),
        );
      }
    }
  }

  void _showUpgradePrompt(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? DsGlassColors.surfaceHeavyDark
                  : DsGlassColors.surfaceHeavyLight,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DsColors.primary.withValues(alpha: 0.2),
                          DsColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 40,
                      color: DsColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'See Who Likes You',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'See all the people who already like you and match instantly. No more guessing!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GlassPrimaryButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context
                            .read<SubscriptionBloc>()
                            .add(PlusCheckoutRequested());
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 20),
                          SizedBox(width: 8),
                          Text('Upgrade to Plus'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Maybe Later'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual like card with optional blur.
class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.profile,
    required this.isBlurred,
    required this.onTap,
  });

  final Profile profile;
  final bool isBlurred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;

    return Semantics(
      label: isBlurred
          ? 'Someone likes you. Upgrade to see who.'
          : '${profile.publicDisplayName}, ${profile.age} years old',
      hint: isBlurred ? 'Double tap to upgrade' : 'Double tap to view profile',
      image: !isBlurred && photoUrl != null,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DsSpacing.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (photoUrl != null)
                CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                  child: const Icon(Icons.person, size: 64),
                ),

            // Blur overlay for free users
            if (isBlurred)
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: DsBlur.heavy,
                  sigmaY: DsBlur.heavy,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
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
            ),

            // Name and age (blurred for free users)
            Positioned(
              bottom: DsSpacing.sm,
              left: DsSpacing.sm,
              right: DsSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBlurred ? '???' : profile.publicDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isBlurred)
                    Text(
                      '${profile.age}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            // Lock icon for blurred cards
            if (isBlurred)
              Positioned(
                top: DsSpacing.sm,
                right: DsSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Bottom sheet showing profile details with like/pass actions.
class _ProfileDetailSheet extends StatelessWidget {
  const _ProfileDetailSheet({
    required this.profile,
    required this.onLikeBack,
    required this.onPass,
  });

  final Profile profile;
  final VoidCallback onLikeBack;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DsSpacing.md),
                        child: AspectRatio(
                          aspectRatio: 0.8,
                          child: photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: isDark
                                      ? DsColors.surfaceDark
                                      : DsColors.surfaceLight,
                                  child: const Icon(Icons.person, size: 100),
                                ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.lg),

                      // Name and age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${profile.publicDisplayName}, ${profile.age}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (profile.isVerified)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: DsColors.verified,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),

                      if (profile.bio.isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.md),
                        Text(
                          profile.bio,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],

                      if (profile.interests.isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.lg),
                        Wrap(
                          spacing: DsSpacing.xs,
                          runSpacing: DsSpacing.xs,
                          children: profile.interests.map((interest) {
                            return Chip(
                              label: Text(interest),
                              backgroundColor: DsColors.primary
                                  .withValues(alpha: 0.1),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassOutlinedButton(
                          onPressed: onPass,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 20),
                              SizedBox(width: 8),
                              Text('Pass'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                        flex: 2,
                        child: GlassPrimaryButton(
                          onPressed: onLikeBack,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite, size: 20),
                              SizedBox(width: 8),
                              Text('Like Back'),
                            ],
                          ),
                        ),
                      ),
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
