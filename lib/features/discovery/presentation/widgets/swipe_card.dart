import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';
import 'package:crushhour/features/discovery/presentation/screens/story_viewer_screen.dart';
import 'package:crushhour/features/discovery/presentation/widgets/story_ring.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/features/discovery/presentation/widgets/content_reaction_button.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/core/accessibility/semantics_helper.dart';
import 'package:crushhour/core/router.dart';

/// A swipeable card showing a profile with photos and videos.
class SwipeCard extends StatefulWidget {
  final Profile profile;

  /// Callback when user reacts to content.
  final void Function(String reactionType, ReactionContentType contentType, int index, String? comment)? onReaction;

  const SwipeCard({
    super.key,
    required this.profile,
    this.onReaction,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _currentMediaIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  String? _sentReactionEmoji;
  bool _showSentReaction = false;

  /// Cached media list to avoid recreation on every access.
  List<_MediaItem>? _cachedMedia;
  String? _cachedProfileId;

  /// Combined list of all media (photos first, then videos).
  List<_MediaItem> get _allMedia {
    // Return cached list if profile hasn't changed
    if (_cachedMedia != null && _cachedProfileId == widget.profile.id) {
      return _cachedMedia!;
    }
    // Rebuild and cache the media list
    final items = <_MediaItem>[];
    for (final url in widget.profile.photoUrls) {
      items.add(_MediaItem(url: url, isVideo: false));
    }
    for (final url in widget.profile.videoUrls) {
      items.add(_MediaItem(url: url, isVideo: true));
    }
    _cachedMedia = items;
    _cachedProfileId = widget.profile.id;
    return items;
  }

  _MediaItem? get _currentMedia {
    final media = _allMedia;
    if (media.isEmpty || _currentMediaIndex >= media.length) return null;
    return media[_currentMediaIndex];
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clean up video when profile changes
    if (oldWidget.profile.id != widget.profile.id) {
      _disposeVideoController();
      _currentMediaIndex = 0;
    }
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoStateChanged);
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      _isVideoPlaying = false;
    }
  }

  void _goToMedia(int index) {
    final media = _allMedia;
    if (index < 0 || index >= media.length) return;

    // Dispose previous video controller if switching away from video
    if (_currentMedia?.isVideo == true) {
      _disposeVideoController();
    }

    setState(() {
      _currentMediaIndex = index;
    });

    // Initialize video if new media is video
    if (media[index].isVideo) {
      _initializeVideo(media[index].url);
    }
  }

  void _goNext() {
    if (_currentMediaIndex < _allMedia.length - 1) {
      _goToMedia(_currentMediaIndex + 1);
    }
  }

  void _goPrevious() {
    if (_currentMediaIndex > 0) {
      _goToMedia(_currentMediaIndex - 1);
    }
  }

  Future<void> _initializeVideo(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        _videoController = VideoPlayerController.networkUrl(uri);
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.file(url));
      }

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.addListener(_onVideoStateChanged);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        // Auto-play video
        _videoController!.play();
      }
    } catch (e) {
      // Video failed to load
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted) return;
    final playing = _videoController?.value.isPlaying ?? false;
    if (playing != _isVideoPlaying) {
      setState(() {
        _isVideoPlaying = playing;
      });
    }
  }

  void _toggleVideoPlayPause() {
    if (_videoController == null) return;
    if (_isVideoPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  void _handleReaction(String reactionType) {
    final currentMedia = _currentMedia;
    if (currentMedia == null) return;

    HapticFeedback.mediumImpact();

    // Show sent reaction animation
    setState(() {
      _sentReactionEmoji = getReactionEmoji(reactionType);
      _showSentReaction = true;
    });

    // Determine content type
    final contentType = currentMedia.isVideo
        ? ReactionContentType.video
        : ReactionContentType.photo;

    // Call callback
    widget.onReaction?.call(
      reactionType,
      contentType,
      _currentMediaIndex,
      null,
    );
  }

  void _handleCommentReaction() async {
    final currentMedia = _currentMedia;
    if (currentMedia == null) return;

    final contentType = currentMedia.isVideo
        ? ReactionContentType.video
        : ReactionContentType.photo;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => ReactionCommentDialog(
        contentPreview: currentMedia.isVideo
            ? 'Video ${_currentMediaIndex + 1}'
            : 'Photo ${_currentMediaIndex + 1}',
        contentType: contentType,
      ),
    );

    if (result != null && mounted) {
      final reaction = result['reaction'] ?? 'like';
      final comment = result['comment'];

      HapticFeedback.mediumImpact();

      setState(() {
        _sentReactionEmoji = getReactionEmoji(reaction);
        _showSentReaction = true;
      });

      widget.onReaction?.call(
        reaction,
        contentType,
        _currentMediaIndex,
        comment,
      );
    }
  }

  void _onSentReactionComplete() {
    if (mounted) {
      setState(() {
        _showSentReaction = false;
        _sentReactionEmoji = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final media = _allMedia;
    final currentMedia = _currentMedia;
    final displayName = profile.publicDisplayName;
    final bio = profile.bio.trim().isEmpty
        ? 'This member has not added a bio yet.'
        : profile.bio;
    final city = profile.city.trim();
    final country = profile.country.trim();
    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');
    final stories = profile.id.activeStories;
    final hasStories = stories.isNotEmpty;

    // Build semantic label for screen readers
    final semanticLabel = SemanticsHelper.profileCardLabel(
      name: displayName,
      age: profile.age,
      location: location.isNotEmpty ? location : null,
      bio: profile.profilePrompts.isNotEmpty
          ? '${profile.profilePrompts.first.question}: ${profile.profilePrompts.first.answer}'
          : bio,
      isVerified: profile.isVerified,
    );

    // Tinder-like immersive card - edge-to-edge, no rounded corners for full-screen feel
    return Semantics(
      label: semanticLabel,
      hint: 'Swipe right to like, swipe left to pass',
      container: true,
      child: Container(
      // Full-screen immersive card - no borders, no shadows, pure photo
      color: Colors.black,
      child: Stack(
          fit: StackFit.expand,
          children: [
            // Media (photo or video) with accessibility
            Semantics(
              label: currentMedia != null
                  ? currentMedia.isVideo
                      ? 'Video ${_currentMediaIndex + 1} of ${_allMedia.length} for $displayName'
                      : 'Photo ${_currentMediaIndex + 1} of ${_allMedia.length} for $displayName'
                  : 'No photo available for $displayName',
              image: currentMedia != null && !currentMedia.isVideo,
              child: currentMedia != null
                  ? currentMedia.isVideo
                      ? _buildVideoPlayer(currentMedia.url)
                      : CachedNetworkImage(
                          imageUrl: currentMedia.url,
                          fit: BoxFit.cover,
                          placeholder: _placeholder(),
                          errorWidget: _placeholder(),
                        )
                  : _placeholder(),
            ),

            // Tap zones for navigation with accessibility
            Row(
              children: [
                // Left tap zone (previous)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Previous photo',
                    hint: _currentMediaIndex > 0 ? 'Double tap to view previous photo' : 'No previous photo',
                    child: GestureDetector(
                      onTap: _goPrevious,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                // Center tap zone (open full screen / toggle video)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: currentMedia?.isVideo == true
                        ? 'Play or pause video'
                        : 'View full profile',
                    hint: 'Double tap to ${currentMedia?.isVideo == true ? 'toggle video playback' : 'see full profile'}',
                    child: GestureDetector(
                      onTap: () {
                        if (currentMedia?.isVideo == true) {
                          _toggleVideoPlayPause();
                        } else {
                          context.push(
                            CrushRoutes.profileMedia,
                            extra: ProfileMediaArgs(profile: profile),
                          );
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                // Right tap zone (next)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Next photo',
                    hint: _currentMediaIndex < _allMedia.length - 1 ? 'Double tap to view next photo' : 'No next photo',
                    child: GestureDetector(
                      onTap: _goNext,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),

            // Gradient overlay for readability - extended for floating action buttons
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: const Alignment(0, -0.3), // Extend higher for action buttons
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75],
                  ),
                ),
              ),
            ),

            // Top gradient - subtle, blends with dark mode
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.15, 0.35],
                  ),
                ),
              ),
            ),

            // Top navigation area with "For You" badge
            Positioned(
              top: DsSpacing.md,
              left: DsSpacing.md,
              right: DsSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: For You badge + Video count (verification badge moved to name area)
                  Row(
                    children: [
                      const _ForYouBadge(),
                      if (profile.videoUrls.isNotEmpty) ...[
                        const SizedBox(width: DsSpacing.xs),
                        _GlassMediaBadge(
                          icon: Icons.videocam_rounded,
                          label: '${profile.videoUrls.length}',
                        ),
                      ],
                      if (hasStories) ...[
                        const SizedBox(width: DsSpacing.xs),
                        Semantics(
                          button: true,
                          label: 'View stories',
                          child: GestureDetector(
                            onTap: () {
                              context.push(
                                CrushRoutes.storyViewer,
                                extra: StoryViewerArgs(
                                  stories: stories,
                                  profile: profile,
                                ),
                              );
                            },
                            child: StoryBadge(
                              storyCount: stories.length,
                              hasUnseen: false,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Media progress indicators (below badges)
                  if (media.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: DsSpacing.sm),
                      child: _MediaProgressIndicators(
                        count: media.length,
                        currentIndex: _currentMediaIndex,
                        videoProgress: _videoController != null && _isVideoInitialized
                            ? _videoController!.value.position.inMilliseconds /
                                (_videoController!.value.duration.inMilliseconds.clamp(1, double.maxFinite.toInt()))
                            : null,
                      ),
                    ),
                ],
              ),
            ),

            // Video play/pause indicator (center)
            if (currentMedia?.isVideo == true && _isVideoInitialized)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isVideoPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: _GlassPlayButton(isPlaying: _isVideoPlaying),
                    ),
                  ),
                ),
              ),

            // Reaction button (left side, above profile info since action buttons are on right)
            if (widget.onReaction != null)
              Positioned(
                left: DsSpacing.md,
                bottom: 240, // Above the profile identity overlay
                child: ContentReactionButton(
                  onReaction: _handleReaction,
                  onComment: _handleCommentReaction,
                  reactions: currentMedia?.isVideo == true
                      ? QuickReaction.photoReactions
                      : QuickReaction.photoReactions,
                ),
              ),

            // Sent reaction animation (center)
            if (_showSentReaction && _sentReactionEmoji != null)
              Positioned.fill(
                child: Center(
                  child: SentReactionIndicator(
                    emoji: _sentReactionEmoji!,
                    onAnimationComplete: _onSentReactionComplete,
                  ),
                ),
              ),

            // Profile identity overlay (name, age, verification, traits) - positioned above info panel
            Positioned(
              left: 0,
              right: 70, // Leave space for action buttons on right
              bottom: 140, // Above the info panel, clear of bottom nav
              child: _ProfileIdentityOverlay(profile: profile),
            ),

            // Info panel (minimal prompt/bio + location) - no background, above bottom nav
            Positioned(
              left: 0,
              right: 70, // Leave space for action buttons on right
              bottom: 90, // Above bottom navigation bar
              child: GestureDetector(
                onTap: () {
                  context.push(
                    CrushRoutes.profileMedia,
                    extra: ProfileMediaArgs(profile: profile),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minimal bio or first prompt - single line for cleaner look
                      if (profile.profilePrompts.isNotEmpty)
                        _CompactPromptDisplayClean(
                          prompt: profile.profilePrompts.first,
                        )
                      else if (bio.isNotEmpty && bio != 'This member has not added a bio yet.')
                        Text(
                          bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: DsSpacing.xs),
                      // Location and distance row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          const SizedBox(width: DsSpacing.xs / 2),
                          Flexible(
                            child: Text(
                              location.isEmpty
                                  ? 'Location unavailable'
                                  : location,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Distance indicator
                          if (profile.distanceDisplay != null) ...[
                            const SizedBox(width: DsSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DsSpacing.sm,
                                vertical: DsSpacing.xs / 2,
                              ),
                              decoration: BoxDecoration(
                                color: DsColors.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(DsRadius.round),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.near_me,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.distanceDisplay!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String url) {
    if (!_isVideoInitialized || _videoController == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _placeholder(),
          const Center(
            child: CircularProgressIndicator(
              color: DsColors.primary,
              strokeWidth: 2,
            ),
          ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController!.value.size.width,
        height: _videoController!.value.size.height,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white.withValues(alpha: 0.3),
          size: 80,
        ),
      ),
    );
  }
}

/// Represents a media item (photo or video).
class _MediaItem {
  final String url;
  final bool isVideo;

  const _MediaItem({required this.url, required this.isVideo});
}

/// Progress indicators for multiple media items.
class _MediaProgressIndicators extends StatelessWidget {
  const _MediaProgressIndicators({
    required this.count,
    required this.currentIndex,
    this.videoProgress,
  });

  final int count;
  final int currentIndex;
  final double? videoProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        final isPast = index < currentIndex;

        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: index < count - 1 ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isPast
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.3),
            ),
            child: isActive
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final progress = videoProgress ?? 1.0;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [DsColors.primary, DsColors.secondary],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }),
    );
  }
}

/// Glass-styled media badge (video count, etc.).
class _GlassMediaBadge extends StatelessWidget {
  const _GlassMediaBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DsColors.secondary.withValues(alpha: 0.5),
                DsColors.primary.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass play button for video overlay.
class _GlassPlayButton extends StatelessWidget {
  const _GlassPlayButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

/// Minimal prompt display - single line answer for cleaner deck view.
class _CompactPromptDisplayClean extends StatelessWidget {
  const _CompactPromptDisplayClean({required this.prompt});

  final ProfilePrompt prompt;

  @override
  Widget build(BuildContext context) {
    final textShadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.8),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ];

    // Minimal single-line display: "emoji answer"
    return Row(
      children: [
        Text(
          prompt.emoji,
          style: TextStyle(
            fontSize: 13,
            shadows: textShadows,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            prompt.answer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              shadows: textShadows,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Profile identity overlay with name, age, status badge, and trait chips.
/// Displayed on the lower-left of the photo.
class _ProfileIdentityOverlay extends StatelessWidget {
  const _ProfileIdentityOverlay({
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.publicDisplayName;
    final ageText = profile.age > 0 ? '${profile.age}' : '';

    // Collect trait chips (limit to 3-4 for clean layout)
    final traits = _buildTraitChips();

    return Padding(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status badge (Active or New here) - above the name
          if (profile.isActive || profile.isNewUser)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.xs),
              child: _ProfileStatusBadge(
                isActive: profile.isActive,
                isNewUser: profile.isNewUser,
              ),
            ),
          // Name, age, and verification badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  ageText.isNotEmpty ? '$displayName, $ageText' : displayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Verification badge after name/age
              if (profile.isVerified) ...[
                const SizedBox(width: DsSpacing.sm),
                const Icon(
                  Icons.verified,
                  size: 22,
                  color: Colors.lightBlueAccent,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ],
            ],
          ),
          // Trait chips below name
          if (traits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DsSpacing.sm),
              child: Wrap(
                spacing: DsSpacing.xs,
                runSpacing: DsSpacing.xs,
                children: traits.take(4).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Build trait chips from profile data
  List<Widget> _buildTraitChips() {
    final chips = <Widget>[];

    // Smoking
    if (profile.smoking != null && profile.smoking!.isNotEmpty) {
      chips.add(_TraitChip(
        icon: Icons.smoking_rooms_outlined,
        label: _formatSmoking(profile.smoking!),
      ));
    }

    // Drinking
    if (profile.drinking != null && profile.drinking!.isNotEmpty) {
      chips.add(_TraitChip(
        icon: Icons.local_bar_outlined,
        label: _formatDrinking(profile.drinking!),
      ));
    }

    // Education
    if (profile.educationLevel != null && profile.educationLevel!.isNotEmpty) {
      chips.add(_TraitChip(
        icon: Icons.school_outlined,
        label: _formatEducation(profile.educationLevel!),
      ));
    }

    // Relationship goals
    if (profile.relationshipGoals != null && profile.relationshipGoals!.isNotEmpty) {
      chips.add(_TraitChip(
        icon: Icons.favorite_outline,
        label: profile.relationshipGoals!,
      ));
    }

    // Workout/Fitness
    if (profile.workout != null && profile.workout!.isNotEmpty) {
      chips.add(_TraitChip(
        icon: Icons.fitness_center_outlined,
        label: profile.workout!,
      ));
    }

    // Pets
    if (profile.pets != null && profile.pets!.isNotEmpty) {
      chips.add(_TraitChip(
        icon: Icons.pets_outlined,
        label: profile.pets!,
      ));
    }

    return chips;
  }

  String _formatSmoking(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('never') || lower.contains('non')) return 'Non-smoker';
    if (lower.contains('social') || lower.contains('occasion')) return 'Social smoker';
    return value;
  }

  String _formatDrinking(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('never') || lower.contains('non') || lower.contains('sober')) return 'Sober';
    if (lower.contains('social') || lower.contains('occasion')) return 'Social drinker';
    if (lower.contains('regular') || lower.contains('often')) return 'Regular drinker';
    return value;
  }

  String _formatEducation(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('bachelor')) return "Bachelor's";
    if (lower.contains('master')) return "Master's";
    if (lower.contains('phd') || lower.contains('doctor')) return 'Doctorate';
    if (lower.contains('high school')) return 'High school';
    if (lower.contains('associate')) return 'Associate';
    return value;
  }
}

/// Compact trait chip with icon for profile overlay.
class _TraitChip extends StatelessWidget {
  const _TraitChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xs / 2 + 1,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(DsRadius.round),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// "For You" badge displayed at the top of the swipe card.
/// Subtle, polished pill that blends with dark mode.
class _ForYouBadge extends StatelessWidget {
  const _ForYouBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm + 2,
            vertical: DsSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                'For You',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status badge showing "Active" or "New here".
/// Prioritizes "Active" if both conditions apply.
class _ProfileStatusBadge extends StatelessWidget {
  const _ProfileStatusBadge({
    required this.isActive,
    required this.isNewUser,
  });

  final bool isActive;
  final bool isNewUser;

  @override
  Widget build(BuildContext context) {
    // Prioritize Active badge over New here
    final showActive = isActive;
    final showNewHere = !isActive && isNewUser;

    if (!showActive && !showNewHere) {
      return const SizedBox.shrink();
    }

    final label = showActive ? 'Active' : 'New here';
    final color = showActive
        ? const Color(0xFF7ED687) // Light green for Active
        : DsColors.secondary.withValues(alpha: 0.9); // Muted accent for New here

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(DsRadius.round),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showActive)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
