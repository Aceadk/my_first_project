import 'dart:math';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
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

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _leftPhotoSlide;
  late Animation<Offset> _rightPhotoSlide;
  late Animation<double> _heartScale;
  late Animation<double> _textScale;
  late Animation<double> _buttonsSlide;

  final List<_FloatingHeart> _floatingHearts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Main entrance animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Heart beat animation
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Floating hearts controller
    _floatingHeartsController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Setup animations
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _leftPhotoSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _rightPhotoSlide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _heartScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.elasticOut),
      ),
    );

    _textScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _buttonsSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Generate floating hearts
    _generateFloatingHearts();

    // Start animations
    _mainController.forward();

    // Start heart beat after entrance
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _heartBeatController.repeat(reverse: true);
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _generateFloatingHearts() {
    for (int i = 0; i < 20; i++) {
      _floatingHearts.add(_FloatingHeart(
        startX: _random.nextDouble(),
        startY: 1.0 + _random.nextDouble() * 0.5,
        endY: -0.2 - _random.nextDouble() * 0.3,
        size: 16 + _random.nextDouble() * 24,
        delay: _random.nextDouble(),
        duration: 2.0 + _random.nextDouble() * 2.0,
        swayAmount: 0.05 + _random.nextDouble() * 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _heartBeatController.dispose();
    _shimmerController.dispose();
    _floatingHeartsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedName = widget.matchedProfile.name.isNotEmpty
        ? widget.matchedProfile.name.split(' ').first
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
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B6B).withValues(alpha: 0.95),
                      const Color(0xFFFF8E8E).withValues(alpha: 0.95),
                      const Color(0xFFFFB4B4).withValues(alpha: 0.95),
                      const Color(0xFFFF6B9D).withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // "It's a Match!" text with shimmer
                          ScaleTransition(
                            scale: _textScale,
                            child: _buildMatchText(),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          FadeTransition(
                            opacity: _textScale,
                            child: Text(
                              'You and $matchedName liked each other',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Profile photos with heart
                          SizedBox(
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Left photo (current user)
                                Positioned(
                                  left: 40,
                                  child: SlideTransition(
                                    position: _leftPhotoSlide,
                                    child: _buildProfilePhoto(
                                      photoUrl: widget.currentUserPhotoUrl,
                                      isLeft: true,
                                    ),
                                  ),
                                ),

                                // Right photo (matched user)
                                Positioned(
                                  right: 40,
                                  child: SlideTransition(
                                    position: _rightPhotoSlide,
                                    child: _buildProfilePhoto(
                                      photoUrl: matchedPhotoUrl,
                                      isLeft: false,
                                    ),
                                  ),
                                ),

                                // Heart icon in center
                                ScaleTransition(
                                  scale: _heartScale,
                                  child: _buildCenterHeart(),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Action buttons
                          Transform.translate(
                            offset: Offset(0, _buttonsSlide.value),
                            child: Opacity(
                              opacity: (1 - _buttonsSlide.value / 100)
                                  .clamp(0.0, 1.0),
                              child: _buildActionButtons(matchedName),
                            ),
                          ),

                          const SizedBox(height: 40),
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
            Colors.white.withValues(alpha: 0.8),
            Colors.white,
          ],
          stops: [
            (_shimmerController.value - 0.3).clamp(0.0, 1.0),
            _shimmerController.value,
            (_shimmerController.value + 0.3).clamp(0.0, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Text(
        "It's a Match!",
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto({
    required String? photoUrl,
    required bool isLeft,
  }) {
    final borderGradient = LinearGradient(
      begin: isLeft ? Alignment.topRight : Alignment.topLeft,
      end: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
      colors: const [
        Colors.white,
        Color(0xFFFFD700),
        Colors.white,
      ],
    );

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: borderGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: DsColors.actionLike.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: photoUrl != null
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[500],
                ),
              ),
      ),
    );
  }

  Widget _buildCenterHeart() {
    final heartBeatValue = 1.0 + (_heartBeatController.value * 0.15);

    return Transform.scale(
      scale: heartBeatValue,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF4D6D),
              Color(0xFFFF0844),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0844).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String matchedName) {
    return Column(
      children: [
        // Send Message button - primary
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF5F5)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleSendMessage,
              borderRadius: BorderRadius.circular(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFFFF4D6D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Say Hi to $matchedName',
                    style: const TextStyle(
                      color: Color(0xFFFF4D6D),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Keep Swiping button - secondary
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleKeepSwiping,
              borderRadius: BorderRadius.circular(28),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Keep Swiping',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

      final currentY =
          heart.startY + (heart.endY - heart.startY) * adjustedProgress;
      final sway = sin(adjustedProgress * pi * 4) * heart.swayAmount;
      final currentX = heart.startX + sway;
      final opacity = (1.0 - adjustedProgress).clamp(0.0, 0.7);

      return Positioned(
        left: MediaQuery.of(context).size.width * currentX,
        top: MediaQuery.of(context).size.height * currentY,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.favorite,
            size: heart.size,
            color: Colors.white.withValues(alpha: 0.6),
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
