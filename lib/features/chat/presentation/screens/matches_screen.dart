import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_state.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/skeleton_loader.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, this.onBackToDeck});

  final VoidCallback? onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final userId =
        context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in to view your matches.'),
        ),
      );
    }

    return BlocProvider(
      create: (context) => MatchesBloc(
        chatRepository: context.read<ChatRepository>(),
        authRepository: context.read<AuthRepository>(),
        userId: userId,
      )..add(const MatchesLoadRequested()),
      child: _MatchesView(currentUserId: userId, onBackToDeck: onBackToDeck),
    );
  }
}

class _MatchesView extends StatefulWidget {
  final String currentUserId;
  final VoidCallback? onBackToDeck;

  const _MatchesView({required this.currentUserId, this.onBackToDeck});

  @override
  State<_MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<_MatchesView> {
  List<Profile> _likesYouProfiles = [];
  bool _isLoadingLikes = true;
  String? _likesError;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() {
      _isLoadingLikes = true;
      _likesError = null;
    });

    try {
      final repo = context.read<DiscoveryRepository>();
      final profiles = await repo.fetchLikesYou(widget.currentUserId);
      if (!mounted) return;
      setState(() {
        _likesYouProfiles = profiles;
        _isLoadingLikes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLikes = false;
        _likesError = 'Could not load likes. Please try again.';
      });
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
                      Icons.lock_rounded,
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
                    'Upgrade to Crush Plus to reveal your admirers and match instantly.',
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

  @override
  Widget build(BuildContext context) {
    final isPlus = context.select<SubscriptionBloc, bool>(
      (bloc) => bloc.state.plan == SubscriptionPlan.plus,
    );

    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        final matched = state.matches;
        final showEmpty = matched.isEmpty &&
            !_isLoadingLikes &&
            _likesError == null &&
            _likesYouProfiles.isEmpty;

        final emptyView = showEmpty
            ? Center(
                child: Padding(
                  padding: DsEdgeInsets.allXxl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DsColors.primary.withValues(alpha: 0.1),
                              DsColors.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 56,
                          color: DsColors.primary,
                        ),
                      ),
                      DsGap.xxl,
                      Text(
                        'No matches yet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      DsGap.sm,
                      Text(
                        'Keep swiping and sending message requests.\nWhen you match with someone, they will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DsColors.textMutedLight,
                            ),
                      ),
                      DsGap.xxl,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.onBackToDeck,
                          icon: const Icon(Icons.style_outlined),
                          label: const Text('Back to deck'),
                        ),
                      ),
                      DsGap.lg,
                      BlocBuilder<SubscriptionBloc, SubscriptionState>(
                        builder: (context, subState) {
                          final isPlus = subState.plan == SubscriptionPlan.plus;
                          final loading = subState.isCheckoutInProgress;
                          if (isPlus) return const SizedBox.shrink();
                          return _PlusOfferCard(
                            loading: loading,
                            onTap: () => context
                                .read<SubscriptionBloc>()
                                .add(PlusCheckoutRequested()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null;

        return AsyncStateScaffold(
          appBar: GlassAppBar(
            title: 'Matches',
            actions: [
              GlassIconButton(
                icon: Icons.shield_outlined,
                onPressed: () => context.push(CrushRoutes.safety),
                size: 40,
              ),
              DsGap.smH,
            ],
          ),
          isLoading: state.isLoading && matched.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: emptyView,
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  state.hasMore &&
                  !state.isLoadingMore) {
                context.read<MatchesBloc>().add(const MatchesLoadMoreRequested());
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _LikesYouSection(
                    profiles: _likesYouProfiles,
                    isLoading: _isLoadingLikes,
                    errorMessage: _likesError,
                    isPlus: isPlus,
                    onRetry: _loadLikes,
                    onUpgradeRequested: () => _showUpgradePrompt(context),
                    onProfileTap: (profile) {
                      context.push(
                        CrushRoutes.userProfile,
                        extra: OtherUserProfileArgs(
                          profile: profile,
                          isMatch: false,
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Matched with you',
                    subtitle: '${matched.length} matches',
                  ),
                ),
                if (matched.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: DsEdgeInsets.allLg,
                      child: _EmptyMatchedCard(
                        onBackToDeck: widget.onBackToDeck,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: DsEdgeInsets.horizontalLg,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final matchCount = matched.length;
                          final loadingItemCount = state.isLoadingMore ? 1 : 0;
                          final separatorCount = matchCount > 0 ? matchCount - 1 : 0;
                          final totalItems = matchCount + separatorCount + loadingItemCount;

                          if (index >= totalItems) return null;
                          if (index == totalItems - 1 && state.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          if (index.isOdd) {
                            return DsGap.sm;
                          }

                          final matchIndex = index ~/ 2;
                          final match = matched[matchIndex];
                          final otherName = match.otherUserName ??
                              (match.otherUserId.trim().isNotEmpty
                                  ? match.otherUserId
                                  : null) ??
                              'Name unavailable';

                          return _MatchTile(
                            name: otherName,
                            photoUrl: match.otherUserPhotoUrl,
                            onTap: () {
                              context.push(
                                '/chat/${match.id}',
                                extra: ChatScreenArgs(
                                  matchId: match.id,
                                  currentUserId: widget.currentUserId,
                                  otherUserId: match.otherUserId,
                                  otherName: otherName,
                                ),
                              );
                            },
                          );
                        },
                        childCount: matched.length +
                            (matched.length > 0 ? matched.length - 1 : 0) +
                            (state.isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: DsGap.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.name,
    required this.onTap,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DsRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(DsSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark
                            ? DsGlassColors.surfaceDark
                            : DsGlassColors.surfaceLight)
                        .withValues(alpha: 0.5),
                    (isDark
                            ? DsGlassColors.surfaceDark
                            : DsGlassColors.surfaceLight)
                        .withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(DsRadius.lg),
                border: Border.all(
                  color: isDark
                      ? DsGlassColors.borderDark
                      : DsGlassColors.borderLight,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar with gradient border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? DsGlassColors.borderLight
                            : DsGlassColors.borderDark.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DsColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedCircleAvatar(
                      imageUrl: photoUrl,
                      radius: 28,
                    ),
                  ),
                  DsGap.lgH,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        DsGap.xs,
                        Text(
                          'Tap to open chat',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(DsSpacing.xs),
                    decoration: BoxDecoration(
                      color: DsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DsRadius.round),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: DsColors.primary,
                      size: 20,
                    ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: DsEdgeInsets.horizontalLg,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  DsGap.xs,
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LikesYouSection extends StatelessWidget {
  const _LikesYouSection({
    required this.profiles,
    required this.isLoading,
    required this.errorMessage,
    required this.isPlus,
    required this.onRetry,
    required this.onUpgradeRequested,
    required this.onProfileTap,
  });

  final List<Profile> profiles;
  final bool isLoading;
  final String? errorMessage;
  final bool isPlus;
  final VoidCallback onRetry;
  final VoidCallback onUpgradeRequested;
  final ValueChanged<Profile> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final count = profiles.length;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Likes You',
            subtitle: count == 0 ? 'No new likes yet' : '$count people like you',
            trailing: isPlus
                ? null
                : TextButton(
                    onPressed: onUpgradeRequested,
                    child: const Text('Upgrade'),
                  ),
          ),
          DsGap.md,
          if (isLoading)
            SizedBox(
              height: 210,
              child: ListView.separated(
                padding: DsEdgeInsets.horizontalLg,
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => DsGap.mdH,
                itemBuilder: (context, index) {
                  return const SkeletonBox(
                    width: 150,
                    height: 210,
                    borderRadius: DsRadius.lg,
                  );
                },
              ),
            )
          else if (errorMessage != null)
            Padding(
              padding: DsEdgeInsets.horizontalLg,
              child: GlassCard(
                padding: DsEdgeInsets.allLg,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: DsColors.error),
                    DsGap.smH,
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (profiles.isEmpty)
            Padding(
              padding: DsEdgeInsets.horizontalLg,
              child: GlassCard(
                padding: DsEdgeInsets.allLg,
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, color: DsColors.primary),
                    DsGap.smH,
                    Expanded(
                      child: Text(
                        'No likes yet. Keep swiping to get noticed.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 210,
              child: ListView.separated(
                padding: DsEdgeInsets.horizontalLg,
                scrollDirection: Axis.horizontal,
                itemCount: profiles.length,
                separatorBuilder: (_, __) => DsGap.mdH,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final blurred = !isPlus;
                  return _LikesYouCard(
                    profile: profile,
                    isBlurred: blurred,
                    onTap: () {
                      if (blurred) {
                        onUpgradeRequested();
                      } else {
                        onProfileTap(profile);
                      }
                    },
                  );
                },
              ),
            ),
          DsGap.lg,
        ],
      ),
    );
  }
}

class _LikesYouCard extends StatelessWidget {
  const _LikesYouCard({
    required this.profile,
    required this.isBlurred,
    required this.onTap,
  });

  final Profile profile;
  final bool isBlurred;
  final VoidCallback onTap;

  String _formatDob(Profile profile) {
    final dob = profile.dateOfBirth;
    if (dob == null) return 'DOB: --';
    final month = dob.month.toString().padLeft(2, '0');
    final day = dob.day.toString().padLeft(2, '0');
    return 'DOB: $month/$day/${dob.year}';
  }

  String _formatDistance(Profile profile) {
    final display = profile.distanceDisplay;
    return display == null ? 'Distance: --' : 'Distance: $display';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
    final dobLabel = _formatDob(profile);
    final distanceLabel = _formatDistance(profile);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        child: SizedBox(
          width: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoUrl != null)
                CachedImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                  child: const Icon(Icons.person, size: 48),
                ),
              if (isBlurred)
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: DsBlur.heavy,
                    sigmaY: DsBlur.heavy,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: DsSpacing.sm,
                right: DsSpacing.sm,
                bottom: DsSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBlurred ? 'Likes You' : profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dobLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      distanceLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBlurred)
                Positioned(
                  top: DsSpacing.sm,
                  right: DsSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 14,
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

class _EmptyMatchedCard extends StatelessWidget {
  const _EmptyMatchedCard({required this.onBackToDeck});

  final VoidCallback? onBackToDeck;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: DsEdgeInsets.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No matches yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          DsGap.sm,
          Text(
            'Keep swiping to turn likes into matches.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onBackToDeck != null) ...[
            DsGap.md,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBackToDeck,
                icon: const Icon(Icons.style_outlined),
                label: const Text('Back to deck'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlusOfferCard extends StatelessWidget {
  const _PlusOfferCard({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: DsEdgeInsets.allLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DsColors.secondary.withValues(alpha: 0.1),
            DsColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DsColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                color: DsColors.primary,
                size: 20,
              ),
              DsGap.smH,
              Text(
                'Intro offer: 50% off Plus',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DsColors.primary,
                    ),
              ),
            ],
          ),
          DsGap.sm,
          Text(
            'See likes first, Passport to any city, and unlimited likes to help you match faster.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DsColors.textMutedLight,
                ),
          ),
          DsGap.md,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: loading ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DsColors.primary),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Try Plus intro offer'),
            ),
          ),
        ],
      ),
    );
  }
}
