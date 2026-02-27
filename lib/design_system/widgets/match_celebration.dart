import 'dart:math';
import 'dart:ui';

import 'package:crushhour/core/services/haptic_service.dart';
import 'package:crushhour/core/services/in_app_review_service.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A celebratory match animation with confetti and glass overlay.
class MatchCelebration extends StatefulWidget {
  const MatchCelebration({
    super.key,
    required this.yourImageUrl,
    required this.matchImageUrl,
    required this.matchName,
    this.onSendMessage,
    this.onKeepSwiping,
    this.onDismiss,
  });

  /// Your profile image URL.
  final String yourImageUrl;

  /// Match's profile image URL.
  final String matchImageUrl;

  /// Match's name.
  final String matchName;

  /// Callback to send a message.
  final VoidCallback? onSendMessage;

  /// Callback to keep swiping.
  final VoidCallback? onKeepSwiping;

  /// Callback when dismissed.
  final VoidCallback? onDismiss;

  /// Show the match celebration as a full-screen dialog.
  static Future<void> show({
    required BuildContext context,
    required String yourImageUrl,
    required String matchImageUrl,
    required String matchName,
    VoidCallback? onSendMessage,
    VoidCallback? onKeepSwiping,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return MatchCelebration(
          yourImageUrl: yourImageUrl,
          matchImageUrl: matchImageUrl,
          matchName: matchName,
          onSendMessage: () {
            Navigator.of(context).pop();
            onSendMessage?.call();
          },
          onKeepSwiping: () {
            Navigator.of(context).pop();
            onKeepSwiping?.call();
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  State<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<MatchCelebration>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  final List<_ConfettiParticle> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Scale animation for avatars
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_scaleController);

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_scaleController);

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Generate confetti particles
    _generateConfetti();
  }

  void _generateConfetti() {
    const colors = [
      DsColors.primary,
      DsColors.secondary,
      DsColors.accent,
      DsColors.warning,
      Color(0xFFFF8FA3), // Soft rose
      Colors.white,
    ];

    for (int i = 0; i < 100; i++) {
      _confetti.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: -_random.nextDouble() * 0.3,
          size: _random.nextDouble() * 8 + 4,
          color: colors[_random.nextInt(colors.length)],
          speed: _random.nextDouble() * 0.5 + 0.3,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
          wobble: _random.nextDouble() * 20,
          wobbleSpeed: _random.nextDouble() * 0.1 + 0.05,
        ),
      );
    }
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _startAnimations();
    }
  }

  void _startAnimations() async {
    HapticService.matchCelebration();

    // Record match for in-app review prompting
    InAppReviewService.instance.recordMatch();

    if (MediaQuery.disableAnimationsOf(context)) {
      _fadeController.value = 1.0;
      _scaleController.value = 1.0;
      _confettiController.value = 1.0;
      return;
    }

    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _scaleController.forward();
    if (mounted) _confettiController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _confettiController]),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background — blur only animates with fade (once on entry)
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: DsBlur.heavy * _fadeAnimation.value,
                    sigmaY: DsBlur.heavy * _fadeAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.6 * _fadeAnimation.value,
                    ),
                  ),
                ),
              ),
            ),

            // Confetti — single CustomPaint instead of 100 widgets
            CustomPaint(
              painter: _ConfettiPainter(
                particles: _confetti,
                progress: _confettiController.value,
              ),
              size: size,
            ),

            // Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "It's a Match!" text
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [DsColors.primary, DsColors.secondary],
                            ).createShader(bounds),
                            child: const Text(
                              "It's a Match!",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: DsSpacing.sm),

                    Text(
                      'You and ${widget.matchName} liked each other',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),

                    const SizedBox(height: DsSpacing.xxl),

                    // Avatar pair
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Your avatar
                              _buildAvatar(widget.yourImageUrl, false),
                              // Heart in the middle
                              Transform.scale(
                                scale: _heartAnimation.value,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: DsSpacing.md,
                                  ),
                                  padding: const EdgeInsets.all(DsSpacing.md),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        DsColors.primary,
                                        DsColors.secondary,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: DsColors.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              // Match avatar
                              _buildAvatar(widget.matchImageUrl, true),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: DsSpacing.xxl),

                    // Action buttons
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              // Send message button
                              _GlassActionButton(
                                onPressed: widget.onSendMessage,
                                gradient: const LinearGradient(
                                  colors: [
                                    DsColors.primary,
                                    DsColors.secondary,
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: DsSpacing.sm),
                                    Text(
                                      'Send a Message',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              // Keep swiping button
                              TextButton(
                                onPressed: widget.onKeepSwiping,
                                child: Text(
                                  'Keep Swiping',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(String imageUrl, bool isMatch) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isMatch ? DsColors.secondary : DsColors.primary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMatch ? DsColors.secondary : DsColors.primary).withValues(
              alpha: 0.4,
            ),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorWidget: Container(
            color: DsGlassColors.surfaceFor(
              context,
              strength: DsGlassSurfaceStrength.medium,
            ),
            child: const Icon(Icons.person, size: 48, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws all confetti particles directly on canvas
/// instead of creating 100 separate widgets.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = particle.y + progress * particle.speed * 1.5;
      if (y > 1.2) continue;

      final wobbleOffset =
          sin(progress * particle.wobbleSpeed * 2 * pi) * particle.wobble;
      final x = (particle.x * size.width) + wobbleOffset;
      final top = y * size.height;
      final opacity = (1 - (y - 0.8).clamp(0.0, 0.4) / 0.4).clamp(0.0, 1.0);
      final angle =
          particle.rotation + progress * particle.rotationSpeed * 2 * pi;

      canvas.save();
      canvas.translate(x, top);
      canvas.rotate(angle);

      final paint = Paint()..color = particle.color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final double wobble;
  final double wobbleSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobble,
    required this.wobbleSpeed,
  });
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.onPressed,
    required this.child,
    this.gradient,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticService.mediumTap();
          onPressed?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xl,
            vertical: DsSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(DsRadius.round),
            boxShadow: [
              BoxShadow(
                color: (gradient?.colors.first ?? DsColors.primary).withValues(
                  alpha: 0.4,
                ),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
