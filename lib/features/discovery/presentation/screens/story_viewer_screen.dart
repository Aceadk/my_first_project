import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/core/router.dart';

/// Full-screen story viewer with auto-advance and progress indicators.
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.profile,
    this.initialIndex = 0,
    this.onStoriesViewed,
  });

  /// List of stories to display.
  final List<ProfileStory> stories;

  /// Profile of the story owner.
  final Profile profile;

  /// Initial story index to start from.
  final int initialIndex;

  /// Callback when all stories have been viewed.
  final VoidCallback? onStoriesViewed;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isVideoInitialized = false;

  /// Duration for photo stories (5 seconds).
  static const _photoDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);

    _progressController = AnimationController(
      vsync: this,
      duration: _photoDuration,
    );

    _progressController.addStatusListener(_onProgressComplete);

    // Set fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _loadCurrentStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextStory();
    }
  }

  Future<void> _loadCurrentStory() async {
    final story = widget.stories[_currentIndex];

    // Mark as viewed
    StoryService.instance.viewStory(
      storyId: story.id,
      viewerId: 'current_user', // Replace with actual user ID
    );

    if (story.isVideo) {
      await _loadVideo(story.mediaUrl);
    } else {
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;

      // Start progress for photo
      _progressController.duration = _photoDuration;
      _progressController.forward(from: 0);
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadVideo(String url) async {
    _progressController.stop();

    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    try {
      final uri = Uri.tryParse(url);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        _videoController = VideoPlayerController.networkUrl(uri);
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.file(url));
      }

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Set progress controller to video duration
        _progressController.duration = _videoController!.value.duration;

        // Sync progress with video position
        _videoController!.addListener(_syncVideoProgress);

        // Start playing
        _videoController!.play();
        _progressController.forward(from: 0);
      }
    } catch (e) {
      // Failed to load video, skip to next
      if (mounted) {
        _goToNextStory();
      }
    }
  }

  void _syncVideoProgress() {
    if (_videoController == null || !_isVideoInitialized) return;

    final duration = _videoController!.value.duration.inMilliseconds;
    final position = _videoController!.value.position.inMilliseconds;

    if (duration > 0) {
      final progress = position / duration;
      if (!_isPaused && _progressController.value != progress) {
        _progressController.value = progress.clamp(0.0, 1.0);
      }
    }

    // Auto-advance when video completes
    if (_videoController!.value.position >= _videoController!.value.duration) {
      _goToNextStory();
    }
  }

  void _goToNextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _loadCurrentStory();
    } else {
      // All stories viewed
      widget.onStoriesViewed?.call();
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _loadCurrentStory();
    }
  }

  void _pause() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController.stop();
    _videoController?.pause();
    if (mounted) setState(() {});
  }

  void _resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController.forward();
    _videoController?.play();
    if (mounted) setState(() {});
  }

  Future<void> _openChatWithUser(BuildContext context) async {
    final currentUserId = context.read<AuthBloc>().state.user?.id;
    if (currentUserId == null) {
      _showSnackBarMessage('Please sign in to send messages');
      return;
    }

    final storyOwnerId = widget.profile.id;
    final storyOwnerName = widget.profile.name;

    // Pause story while we look up the match
    _pause();

    // Capture navigator and router before async gap
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    try {
      // Fetch user's matches to find existing chat with story owner
      final chatRepository = context.read<ChatRepository>();
      final matches = await chatRepository.fetchUserMatches(currentUserId);

      // Find a mutual match with the story owner
      final existingMatch = matches.cast<dynamic>().firstWhere(
        (match) => match.otherUserId == storyOwnerId && match.isMutual,
        orElse: () => null,
      );

      if (!mounted) return;

      if (existingMatch != null) {
        // Navigate to chat with existing match
        navigator.pop();
        router.push(
          '${CrushRoutes.chat}/${existingMatch.id}',
          extra: ChatScreenArgs(
            matchId: existingMatch.id,
            currentUserId: currentUserId,
            otherUserId: storyOwnerId,
            otherName: storyOwnerName,
          ),
        );
      } else {
        // No mutual match exists - inform user
        _resume();
        _showSnackBarMessage('Match with ${widget.profile.name} first to send messages');
      }
    } catch (e) {
      if (!mounted) return;
      _resume();
      _showSnackBarMessage('Unable to open chat. Please try again.');
    }
  }

  void _showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pause(),
        onTapUp: (details) {
          _resume();

          // Determine tap zone
          final width = MediaQuery.of(context).size.width;
          final x = details.globalPosition.dx;

          if (x < width / 3) {
            _goToPreviousStory();
          } else if (x > width * 2 / 3) {
            _goToNextStory();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content
            story.isVideo
                ? _buildVideoContent()
                : CachedNetworkImage(
                    imageUrl: story.mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: _buildLoading(),
                    errorWidget: _buildError(),
                  ),

            // Top gradient
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4],
                  ),
                ),
              ),
            ),

            // Bottom gradient
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
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

            // Progress indicators
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.md,
                  vertical: DsSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bars
                    _buildProgressIndicators(),
                    const SizedBox(height: DsSpacing.md),
                    // User info and close button
                    _buildHeader(),
                  ],
                ),
              ),
            ),

            // Story info (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: _buildStoryInfo(story),
              ),
            ),

            // Pause indicator
            if (_isPaused)
              Center(
                child: _buildPauseIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Row(
          children: List.generate(widget.stories.length, (index) {
            double progress;
            if (index < _currentIndex) {
              progress = 1.0;
            } else if (index == _currentIndex) {
              progress = _progressController.value;
            } else {
              progress = 0.0;
            }

            return Expanded(
              child: Container(
                height: 2.5,
                margin: EdgeInsets.only(
                  right: index < widget.stories.length - 1 ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHeader() {
    final profile = widget.profile;
    final story = widget.stories[_currentIndex];

    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: profile.displayPhotoUrl != null
                ? CachedNetworkImage(
                    imageUrl: profile.displayPhotoUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(width: DsSpacing.sm),
        // Name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                story.remainingTimeDisplay,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Video indicator
        if (story.isVideo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DsRadius.sm),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Video',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        const SizedBox(width: DsSpacing.sm),
        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStoryInfo(ProfileStory story) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: Container(
          padding: const EdgeInsets.all(DsSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              // View count
              Icon(
                Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${story.viewCount} views',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              // Reply button
              TextButton.icon(
                onPressed: () => _openChatWithUser(context),
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Send message',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (!_isVideoInitialized || _videoController == null) {
      return _buildLoading();
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

  Widget _buildLoading() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: DsColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load story',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseIndicator() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.medium, sigmaY: DsBlur.medium),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pause,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
