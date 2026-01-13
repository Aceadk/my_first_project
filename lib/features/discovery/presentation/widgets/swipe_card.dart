import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/features/discovery/presentation/widgets/content_reaction_button.dart';
import 'package:crushhour/presentation/widgets/cached_network_image.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

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

  /// Combined list of all media (photos first, then videos).
  List<_MediaItem> get _allMedia {
    final items = <_MediaItem>[];
    for (final url in widget.profile.photoUrls) {
      items.add(_MediaItem(url: url, isVideo: false));
    }
    for (final url in widget.profile.videoUrls) {
      items.add(_MediaItem(url: url, isVideo: true));
    }
    return items;
  }

  _MediaItem? get _currentMedia {
    final media = _allMedia;
    if (media.isEmpty || _currentMediaIndex >= media.length) return null;
    return media[_currentMediaIndex];
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _goToMedia(int index) {
    final media = _allMedia;
    if (index < 0 || index >= media.length) return;

    // Dispose previous video controller if switching away from video
    if (_currentMedia?.isVideo == true) {
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      _isVideoPlaying = false;
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
    final displayName =
        profile.name.trim().isEmpty ? 'Someone new' : profile.name.trim();
    final ageText = profile.age > 0 ? '${profile.age}' : 'N/A';
    final bio = profile.bio.trim().isEmpty
        ? 'This member has not added a bio yet.'
        : profile.bio;
    final city = profile.city.trim();
    final country = profile.country.trim();
    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');

    return Container(
      margin: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DsRadius.xl),
        border: Border.all(
          color: DsGlassColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DsColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media (photo or video)
            if (currentMedia != null)
              currentMedia.isVideo
                  ? _buildVideoPlayer(currentMedia.url)
                  : CachedNetworkImage(
                      imageUrl: currentMedia.url,
                      fit: BoxFit.cover,
                      placeholder: _placeholder(),
                      errorWidget: _placeholder(),
                    )
            else
              _placeholder(),

            // Tap zones for navigation
            Row(
              children: [
                // Left tap zone (previous)
                Expanded(
                  child: GestureDetector(
                    onTap: _goPrevious,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
                // Center tap zone (open full screen / toggle video)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (currentMedia?.isVideo == true) {
                        _toggleVideoPlayPause();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileMediaScreen(profile: profile),
                          ),
                        );
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
                // Right tap zone (next)
                Expanded(
                  child: GestureDetector(
                    onTap: _goNext,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),

            // Gradient overlay for readability
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7],
                  ),
                ),
              ),
            ),

            // Top gradient for indicators
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
              ),
            ),

            // Media progress indicators (top)
            if (media.length > 1)
              Positioned(
                top: DsSpacing.md,
                left: DsSpacing.md,
                right: DsSpacing.md,
                child: _MediaProgressIndicators(
                  count: media.length,
                  currentIndex: _currentMediaIndex,
                  videoProgress: _videoController != null && _isVideoInitialized
                      ? _videoController!.value.position.inMilliseconds /
                          (_videoController!.value.duration.inMilliseconds.clamp(1, double.maxFinite.toInt()))
                      : null,
                ),
              ),

            // Badges row (under indicators)
            Positioned(
              top: media.length > 1 ? DsSpacing.md + 12 : DsSpacing.md,
              left: DsSpacing.md,
              right: DsSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Video count badge (left)
                  if (profile.videoUrls.isNotEmpty)
                    _GlassMediaBadge(
                      icon: Icons.videocam_rounded,
                      label: '${profile.videoUrls.length}',
                    )
                  else
                    const SizedBox.shrink(),
                  // Verification badge (right)
                  _GlassVerificationPill(isVerified: profile.isVerified),
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

            // Reaction button (right side, above info panel)
            if (widget.onReaction != null)
              Positioned(
                right: DsSpacing.md,
                bottom: 180, // Above the info panel
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

            // Frosted glass info panel (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileMediaScreen(profile: profile),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(DsRadius.xl - 2),
                    bottomRight: Radius.circular(DsRadius.xl - 2),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: DsBlur.medium,
                      sigmaY: DsBlur.medium,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(DsSpacing.lg),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            DsGlassColors.surfaceDark,
                            DsGlassColors.surfaceDark,
                          ],
                        ),
                        border: Border(
                          top: BorderSide(
                            color: DsGlassColors.borderLight,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name and age
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$displayName, $ageText',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DsSpacing.xs),
                          // Bio or first prompt
                          if (profile.profilePrompts.isNotEmpty)
                            _CompactPromptDisplay(
                              prompt: profile.profilePrompts.first,
                            )
                          else
                            Text(
                              bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: DsSpacing.xs),
                          // Location and distance row
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: DsSpacing.xs / 2),
                              Flexible(
                                child: Text(
                                  location.isEmpty
                                      ? 'Location unavailable'
                                      : location,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
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
                                    color: DsColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(DsRadius.round),
                                    border: Border.all(
                                      color: DsColors.primary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.near_me,
                                        size: 12,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile.distanceDisplay!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
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

/// Compact prompt display for swipe cards.
class _CompactPromptDisplay extends StatelessWidget {
  const _CompactPromptDisplay({required this.prompt});

  final ProfilePrompt prompt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Question with emoji
        Row(
          children: [
            Text(
              prompt.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                prompt.question,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Answer
        Text(
          prompt.answer,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// A glassmorphism-styled verification badge for profile cards.
class _GlassVerificationPill extends StatelessWidget {
  const _GlassVerificationPill({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? Colors.lightBlueAccent : Colors.orangeAccent;
    final text = isVerified ? 'Verified' : 'Not verified';
    final icon = isVerified ? Icons.verified : Icons.privacy_tip_outlined;

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.25),
                DsGlassColors.surfaceDark.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: DsSpacing.xs),
              Text(
                text,
                style: TextStyle(
                  color: color,
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
