import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'swipeable_card.dart';
import 'package:crushhour/presentation/widgets/cached_network_image.dart';

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

    // Preload next 3 images
    final urlsToPreload = <String>[];
    for (var i = currentIndex; i < currentIndex + 3 && i < deck.length; i++) {
      final url = deck[i].displayPhotoUrl;
      if (url != null) {
        urlsToPreload.add(url);
      }
    }

    if (urlsToPreload.isNotEmpty) {
      NetworkImageCache.instance.preload(urlsToPreload);
    }
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
  });

  final Profile currentProfile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DiscoveryBloc, DiscoveryState, List<Profile>>(
      selector: (state) {
        if (state.deck.isEmpty) return [];
        final start = state.currentIndex + 1;
        final end = (state.currentIndex + 3).clamp(0, state.deck.length);
        if (start >= state.deck.length) return [];
        return state.deck.sublist(start, end);
      },
      builder: (context, upcomingProfiles) {
        return Stack(
          children: [
            // Background cards (upcoming)
            for (var i = upcomingProfiles.length - 1; i >= 0; i--)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, (i + 1) * 8.0),
                  child: Transform.scale(
                    scale: 1 - ((i + 1) * 0.03),
                    child: RepaintBoundary(
                      child: _PreviewCard(
                        profile: upcomingProfiles[i],
                        opacity: 0.3 - (i * 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            // Current card on top
            child,
          ],
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.profile,
    required this.opacity,
  });

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
              )
            : Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
      ),
    );
  }
}
