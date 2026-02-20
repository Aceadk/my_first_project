import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';

/// A full-screen semi-transparent overlay shown on top of the deck screen
/// after onboarding. Explains swipe gestures, like/pass buttons, and
/// navigation. Dismisses after user interaction.
class WelcomeTutorialOverlay extends StatefulWidget {
  const WelcomeTutorialOverlay({super.key, required this.onDismiss});

  /// Callback invoked when the user dismisses the overlay.
  final VoidCallback onDismiss;

  @override
  State<WelcomeTutorialOverlay> createState() => _WelcomeTutorialOverlayState();
}

class _WelcomeTutorialOverlayState extends State<WelcomeTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeAnimController;
  late final Animation<Offset> _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _swipeAnimation =
        Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: const Offset(0.3, 0),
        ).animate(
          CurvedAnimation(
            parent: _swipeAnimController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start animation only if reduced motion is not requested.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      _swipeAnimController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _swipeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label:
          'Welcome tutorial. Swipe left to pass, swipe right to like, swipe up to super like.',
      child: GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxCardWidth = DsBreakpoints.responsiveValue<double>(
                constraints.maxWidth,
                mobile: constraints.maxWidth * 0.88,
                tablet: 400,
                desktop: 400,
              );

              return Center(
                child: GestureDetector(
                  // Prevent taps on the card from propagating to the
                  // background dismiss handler.
                  onTap: () {},
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxCardWidth),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DsRadius.lg),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: DsBlur.medium,
                          sigmaY: DsBlur.medium,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: DsGlassColors.surfaceFor(
                              context,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(DsRadius.lg),
                            border: Border.all(
                              color: DsGlassColors.borderFor(context),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DsSpacing.xxl,
                            vertical: DsSpacing.xxxl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                'Welcome to CRUSH!',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              DsGap.xxl,

                              // Animated / static hand gesture icon
                              ExcludeSemantics(
                                child: reduceMotion
                                    ? const Icon(
                                        Icons.swipe,
                                        size: 56,
                                        color: Colors.white70,
                                      )
                                    : SlideTransition(
                                        position: _swipeAnimation,
                                        child: const Icon(
                                          Icons.swipe,
                                          size: 56,
                                          color: Colors.white70,
                                        ),
                                      ),
                              ),
                              DsGap.xxl,

                              // Instruction rows
                              const _InstructionRow(
                                icon: Icons.close_rounded,
                                iconColor: DsColors.ink300,
                                label: 'Swipe left to pass',
                                direction: '\u2190',
                              ),
                              DsGap.lg,
                              const _InstructionRow(
                                icon: Icons.favorite_rounded,
                                iconColor: DsColors.actionLike,
                                label: 'Swipe right to like',
                                direction: '\u2192',
                              ),
                              DsGap.lg,
                              const _InstructionRow(
                                icon: Icons.star_rounded,
                                iconColor: DsColors.actionSuperLike,
                                label: 'Swipe up to super like',
                                direction: '\u2191',
                              ),
                              DsGap.xxxl,

                              // "Got it!" button
                              GlassPrimaryButton(
                                onPressed: widget.onDismiss,
                                isExpanded: true,
                                semanticLabel: 'Got it! Dismiss tutorial',
                                child: const Text('Got it!'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A single instruction row displaying a direction arrow, icon, and label.
class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.direction,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String direction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Text(
            direction,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),
        ),
        DsGap.mdH,
        ExcludeSemantics(child: Icon(icon, color: iconColor, size: 24)),
        DsGap.mdH,
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
