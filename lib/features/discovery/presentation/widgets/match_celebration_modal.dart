import 'dart:math';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal displayed when two users match after a swipe.
class MatchCelebrationModal extends StatefulWidget {
  const MatchCelebrationModal({
    super.key,
    required this.matchedProfile,
    required this.currentUserPhotoUrl,
    this.onSendMessage,
    this.onKeepSwiping,
  });

  final Profile matchedProfile;
  final String? currentUserPhotoUrl;
  final VoidCallback? onSendMessage;
  final VoidCallback? onKeepSwiping;

  /// Show the match celebration modal as a full-screen dialog.
  static Future<void> show({
    required BuildContext context,
    required Profile matchedProfile,
    String? currentUserPhotoUrl,
    VoidCallback? onSendMessage,
    VoidCallback? onKeepSwiping,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return MatchCelebrationModal(
          matchedProfile: matchedProfile,
          currentUserPhotoUrl: currentUserPhotoUrl,
          onSendMessage: onSendMessage,
          onKeepSwiping: onKeepSwiping,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  @override
  State<MatchCelebrationModal> createState() => _MatchCelebrationModalState();
}

class _MatchCelebrationModalState extends State<MatchCelebrationModal>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _heartBeatController;
  late AnimationController _shimmerController;
  late AnimationController _floatingHeartsController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _leftPhotoSlide;
  late Animation<double> _rightPhotoSlide;
  late Animation<double> _heartScale;
  late Animation<double> _heartPulse;
  late Animation<double> _ringPulse;
  late Animation<double> _textScale;
  late Animation<double> _buttonsSlide;
  late Animation<double> _glowAnimation;

  final List<_FloatingHeart> _floatingHearts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Main entrance animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Heart beat animation
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    // Floating hearts controller
    _floatingHeartsController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // Glow animation for golden ring
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Setup animations
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Photos slide from sides and meet in center
    _leftPhotoSlide = Tween<double>(begin: -150.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _rightPhotoSlide = Tween<double>(begin: 150.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _heartScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.7, curve: Curves.elasticOut),
      ),
    );

    _heartPulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _heartBeatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _ringPulse = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(
        parent: _heartBeatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _textScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _buttonsSlide = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Generate floating hearts
    _generateFloatingHearts();

    // Start animations
    _mainController.forward();

    // Start heart beat after photos come together
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _heartBeatController.repeat(reverse: true);
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _generateFloatingHearts() {
    for (int i = 0; i < 25; i++) {
      _floatingHearts.add(_FloatingHeart(
        startX: _random.nextDouble(),
        startY: 1.0 + _random.nextDouble() * 0.5,
        endY: -0.3 - _random.nextDouble() * 0.3,
        size: 14 + _random.nextDouble() * 20,
        delay: _random.nextDouble(),
        duration: 2.5 + _random.nextDouble() * 2.0,
        swayAmount: 0.03 + _random.nextDouble() * 0.08,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _heartBeatController.dispose();
    _shimmerController.dispose();
    _floatingHeartsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedDisplayName = widget.matchedProfile.publicDisplayName;
    final matchedName = matchedDisplayName.isNotEmpty
        ? matchedDisplayName.split(' ').first
        : 'Someone';
    final matchedPhotoUrl = widget.matchedProfile.photoUrls.isNotEmpty
        ? widget.matchedProfile.photoUrls.first
        : null;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _heartBeatController,
          _shimmerController,
          _floatingHeartsController,
          _glowController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Gradient background with subtle animation
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF5E7D),
                      Color(0xFFFF6B8A),
                      Color(0xFFFF8BA0),
                      Color(0xFFFFABB8),
                    ],
                  ),
                ),
              ),

              // Floating hearts background
              ..._buildFloatingHearts(),

              // Main content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // "It's a Match!" text with shimmer
                          ScaleTransition(
                            scale: _textScale,
                            child: _buildMatchText(),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          FadeTransition(
                            opacity: _textScale,
                            child: Text(
                              'You and $matchedName liked each other',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 50),

                          // Profile photos with heart above
                          _buildProfilePhotosWithHeart(matchedPhotoUrl),

                          const Spacer(flex: 3),

                          // Action buttons
                          Transform.translate(
                            offset: Offset(0, _buttonsSlide.value),
                            child: Opacity(
                              opacity: (1 - _buttonsSlide.value / 120).clamp(0.0, 1.0),
                              child: _buildActionButtons(matchedName),
                            ),
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchText() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.7),
            Colors.white,
          ],
          stops: [
            (_shimmerController.value - 0.4).clamp(0.0, 1.0),
            _shimmerController.value,
            (_shimmerController.value + 0.4).clamp(0.0, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Text(
        "It's a Match!",
        style: TextStyle(
          fontSize: 46,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotosWithHeart(String? matchedPhotoUrl) {
    const double photoSize = 130.0;
    const double overlap = 56.0; // How much photos overlap in center
    const double heartSize = 64.0;

    return SizedBox(
      height: photoSize + 70,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Heart above the photos
          Positioned(
            top: -heartSize * 0.55,
            child: ScaleTransition(
              scale: _heartScale,
              child: _buildPoundingHeart(heartSize),
            ),
          ),

          // Left photo (current user) - slides from left
          Transform.translate(
            offset: Offset(_leftPhotoSlide.value - overlap, 0),
            child: _buildGoldenCirclePhoto(
              photoUrl: widget.currentUserPhotoUrl,
              size: photoSize,
              isLeft: true,
            ),
          ),

          // Right photo (matched user) - slides from right
          Transform.translate(
            offset: Offset(_rightPhotoSlide.value + overlap, 0),
            child: _buildGoldenCirclePhoto(
              photoUrl: matchedPhotoUrl,
              size: photoSize,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenCirclePhoto({
    required String? photoUrl,
    required double size,
    required bool isLeft,
  }) {
    final glowIntensity = _glowAnimation.value;
    final ringOpacity =
        (0.2 + (glowIntensity * 0.35)).clamp(0.2, 0.6).toDouble();

    return SizedBox(
      width: size + 30,
      height: size + 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Transform.scale(
            scale: _ringPulse.value,
            child: Container(
              width: size + 18,
              height: size + 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: ringOpacity),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLeft
                            ? const Color(0xFFFFE1EC)
                            : const Color(0xFFFFF2D9))
                        .withValues(alpha: ringOpacity * 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // Golden ring + photo
          Container(
            width: size + 8,
            height: size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFC107), // Amber
                  Color(0xFFFFB300), // Dark gold
                  Color(0xFFFFD700), // Gold
                ],
              ),
              boxShadow: [
                // Golden glow
                BoxShadow(
                  color:
                      const Color(0xFFFFD700).withValues(alpha: glowIntensity * 0.6),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
                // Outer shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                      )
                    : Container(
                        width: size,
                        height: size,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: size * 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoundingHeart(double size) {
    final glowIntensity = _glowAnimation.value;
    final floatOffset = sin(_heartBeatController.value * pi) * -6.0;

    return Transform.translate(
      offset: Offset(0, floatOffset),
      child: Transform.scale(
        scale: _heartPulse.value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF7A92),
                Color(0xFFFF1744),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744)
                    .withValues(alpha: glowIntensity * 0.6),
                blurRadius: 22,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: -2,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String matchedName) {
    return Column(
      children: [
        // Say Hi button - primary with gradient
        Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFFF8F8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 0,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleSendMessage,
              borderRadius: BorderRadius.circular(29),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF5E7D).withValues(alpha: 0.15),
                            const Color(0xFFFF1744).withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Color(0xFFFF1744),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Say Hi to $matchedName',
                      style: const TextStyle(
                        color: Color(0xFFFF1744),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Keep Swiping button - secondary glass style
        Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleKeepSwiping,
              borderRadius: BorderRadius.circular(29),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Keep Swiping',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingHearts() {
    return _floatingHearts.map((heart) {
      final progress = ((_floatingHeartsController.value + heart.delay) % 1.0);
      final adjustedProgress = progress / heart.duration.clamp(0.5, 1.0);

      if (adjustedProgress > 1.0) return const SizedBox.shrink();

      final currentY = heart.startY + (heart.endY - heart.startY) * adjustedProgress;
      final sway = sin(adjustedProgress * pi * 5) * heart.swayAmount;
      final currentX = heart.startX + sway;
      final opacity = (1.0 - adjustedProgress * 1.2).clamp(0.0, 0.6);

      return Positioned(
        left: MediaQuery.of(context).size.width * currentX,
        top: MediaQuery.of(context).size.height * currentY,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.favorite,
            size: heart.size,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }).toList();
  }

  void _handleSendMessage() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.onSendMessage?.call();
  }

  void _handleKeepSwiping() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    widget.onKeepSwiping?.call();
  }
}

class _FloatingHeart {
  final double startX;
  final double startY;
  final double endY;
  final double size;
  final double delay;
  final double duration;
  final double swayAmount;

  _FloatingHeart({
    required this.startX,
    required this.startY,
    required this.endY,
    required this.size,
    required this.delay,
    required this.duration,
    required this.swayAmount,
  });
}
