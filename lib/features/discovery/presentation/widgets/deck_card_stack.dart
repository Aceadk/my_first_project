import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'swipeable_card.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';

/// Optimized card stack widget that only rebuilds when the current profile changes.
/// Uses BlocSelector to avoid unnecessary rebuilds from unrelated state changes.
class DeckCardStack extends StatefulWidget {
  const DeckCardStack({
    super.key,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  State<DeckCardStack> createState() => _DeckCardStackState();
}

class _DeckCardStackState extends State<DeckCardStack> {
  int _lastPreloadedIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload next few images for smoother transitions
    _preloadNextImages();
  }

  void _preloadNextImages() {
    final state = context.read<DiscoveryBloc>().state;
    final deck = state.deck;
    final currentIndex = state.currentIndex;

    // Skip if already preloaded for this index
    if (currentIndex == _lastPreloadedIndex) return;
    _lastPreloadedIndex = currentIndex;

    // Priority-based preloading
    String? immediateUrl;
    final highPriorityUrls = <String>[];
    final lowPriorityUrls = <String>[];

    // Current card - immediate priority
    if (currentIndex < deck.length) {
      immediateUrl = deck[currentIndex].displayPhotoUrl;
    }

    // Next 2 cards - high priority
    for (
      var i = currentIndex + 1;
      i <= currentIndex + 2 && i < deck.length;
      i++
    ) {
      final url = deck[i].displayPhotoUrl;
      if (url != null) highPriorityUrls.add(url);
    }

    // Preview cards (3-4) - low priority
    for (
      var i = currentIndex + 3;
      i <= currentIndex + 4 && i < deck.length;
      i++
    ) {
      final url = deck[i].displayPhotoUrl;
      if (url != null) lowPriorityUrls.add(url);
    }

    // Use priority-based preloading
    NetworkImageCache.instance.preloadWithPriority(
      immediateUrls: immediateUrl != null ? [immediateUrl] : null,
      highUrls: highPriorityUrls.isNotEmpty ? highPriorityUrls : null,
      lowUrls: lowPriorityUrls.isNotEmpty ? lowPriorityUrls : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only select the current profile to minimize rebuilds
    return BlocSelector<DiscoveryBloc, DiscoveryState, Profile?>(
      selector: (state) {
        if (state.deck.isEmpty || state.currentIndex >= state.deck.length) {
          return null;
        }
        return state.deck[state.currentIndex];
      },
      builder: (context, currentProfile) {
        if (currentProfile == null) {
          return const SizedBox.shrink();
        }

        // Preload when profile changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preloadNextImages();
        });

        return SwipeableCard(
          key: ValueKey(currentProfile.id),
          profile: currentProfile,
          onTap: widget.onTap,
          onSwipeLeft: widget.onSwipeLeft,
          onSwipeRight: widget.onSwipeRight,
        );
      },
    );
  }
}

/// A widget that displays a stack of upcoming cards for visual preview.
/// Uses RepaintBoundary to optimize rendering.
class DeckPreviewStack extends StatelessWidget {
  const DeckPreviewStack({
    super.key,
    required this.currentProfile,
    required this.child,
    this.upcomingProfiles,
  });

  final Profile currentProfile;
  final Widget child;
  final List<Profile>? upcomingProfiles;

  Widget _buildStack(List<Profile> profiles) {
    return Stack(
      children: [
        // Background cards (upcoming)
        for (var i = profiles.length - 1; i >= 0; i--)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, (i + 1) * 8.0),
              child: Transform.scale(
                scale: 1 - ((i + 1) * 0.03),
                child: RepaintBoundary(
                  child: _PreviewCard(
                    profile: profiles[i],
                    opacity: 0.4 - (i * 0.08),
                  ),
                ),
              ),
            ),
          ),
        // Current card on top
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provided = upcomingProfiles;
    if (provided != null) {
      return _buildStack(provided);
    }
    return BlocSelector<DiscoveryBloc, DiscoveryState, List<Profile>>(
      selector: (state) {
        if (state.deck.isEmpty) return [];
        final start = state.currentIndex + 1;
        final end = (state.currentIndex + 5).clamp(0, state.deck.length);
        if (start >= state.deck.length) return [];
        return state.deck.sublist(start, end);
      },
      builder: (context, upcomingProfiles) {
        return _buildStack(upcomingProfiles);
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.profile, required this.opacity});

  final Profile profile;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.displayPhotoUrl;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Card(
        margin: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: const _PreviewCardShimmer(),
              )
            : Container(
                color: DsColors.surfaceDark,
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: DsColors.textMutedLight.withValues(alpha: 0.6),
                    size: 64,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Shimmer placeholder for preview cards - lightweight for background cards.
class _PreviewCardShimmer extends StatefulWidget {
  const _PreviewCardShimmer();

  @override
  State<_PreviewCardShimmer> createState() => _PreviewCardShimmerState();
}

class _PreviewCardShimmerState extends State<_PreviewCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? DsColors.skeletonDark : DsColors.skeletonLight;
    final highlightColor = isDark
        ? DsColors.surfaceElevatedDark
        : DsColors.surfaceElevatedLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
