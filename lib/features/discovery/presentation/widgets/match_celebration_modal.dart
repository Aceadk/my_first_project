import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';

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
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MatchCelebrationModal> createState() => _MatchCelebrationModalState();
}

class _MatchCelebrationModalState extends State<MatchCelebrationModal>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _heartBeatController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartBeatAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Trigger strong haptic feedback immediately
    HapticFeedback.heavyImpact();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    // Pulse animation for "It's a Match!" text
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Heart beat animation for center heart
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heartBeatAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _heartBeatController, curve: Curves.easeInOut));

    // Slide animation for profile photos
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    // Start animations with proper sequencing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _confettiController.play();
        _slideController.forward();
      }
    });

    // Start heart beat after slide completes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _heartBeatController.repeat();
        // Additional haptic pulses synced with heart beat
        _triggerHeartBeatHaptics();
      }
    });
  }

  void _triggerHeartBeatHaptics() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 800), _triggerHeartBeatHaptics);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _heartBeatController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchedName = widget.matchedProfile.name.isNotEmpty
        ? widget.matchedProfile.name.split(' ').first
        : 'Someone';
    final matchedPhotoUrl = widget.matchedProfile.photoUrls.isNotEmpty
        ? widget.matchedProfile.photoUrls.first
        : null;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // "It's a Match!" text
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          DsColors.actionLike,
                          DsColors.actionLike.withValues(alpha: 0.8),
                          Colors.pinkAccent,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        "It's a Match!",
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  DsGap.md,
                  Text(
                    'You and $matchedName liked each other',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DsGap.xxl,
                  // Profile photos with heart overlay
                  SlideTransition(
                    position: _slideAnimation,
                    child: SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Current user photo (left)
                          Positioned(
                            left: MediaQuery.of(context).size.width / 2 - 140,
                            child: _buildProfileCircle(
                              photoUrl: widget.currentUserPhotoUrl,
                              isCurrentUser: true,
                            ),
                          ),
                          // Matched user photo (right)
                          Positioned(
                            right: MediaQuery.of(context).size.width / 2 - 140,
                            child: _buildProfileCircle(
                              photoUrl: matchedPhotoUrl,
                              isCurrentUser: false,
                            ),
                          ),
                          // Heart icon in center with beat animation
                          ScaleTransition(
                            scale: _heartBeatAnimation,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: DsColors.actionLike,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: DsColors.actionLike.withValues(alpha: 0.4),
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
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _handleSendMessage,
                      icon: const Icon(Icons.message),
                      label: Text('Message $matchedName'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DsColors.actionLike,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  DsGap.md,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleKeepSwiping,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Keep Swiping'),
                    ),
                  ),
                  DsGap.xl,
                ],
              ),
            ),
          ),
          // Confetti from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.pink,
                Colors.pinkAccent,
                Colors.white,
                Colors.yellow,
                Colors.orange,
              ],
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.03,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCircle({
    required String? photoUrl,
    required bool isCurrentUser,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[800],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[600],
                ),
              ),
      ),
    );
  }

  void _handleSendMessage() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    if (widget.onSendMessage != null) {
      widget.onSendMessage!();
    } else {
      // Navigate to chat with matched user
      context.push(
        CrushRoutes.chat,
        extra: {'userId': widget.matchedProfile.id},
      );
    }
  }

  void _handleKeepSwiping() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    widget.onKeepSwiping?.call();
  }
}
