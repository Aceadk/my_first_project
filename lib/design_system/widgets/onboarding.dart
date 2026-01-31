import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/gradients.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../theme/theme_extensions.dart';
import 'glass_button.dart';
import 'package:crushhour/core/services/haptic_service.dart';

/// An onboarding page model.
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient? iconGradient;
  final String? lottieAsset;
  final Widget? customWidget;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.iconGradient,
    this.lottieAsset,
    this.customWidget,
  });
}

/// Default onboarding pages for CrushHour.
class CrushHourOnboardingPages {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Discover People',
      description:
          'Swipe right to like, left to pass. Find your perfect match among thousands of singles.',
      icon: Icons.local_fire_department_rounded,
      iconGradient: DsGradients.discover,
    ),
    OnboardingPage(
      title: 'Make Connections',
      description:
          'When both of you like each other, it\'s a match! Start chatting and get to know them.',
      icon: Icons.favorite_rounded,
      iconGradient: DsGradients.matches,
    ),
    OnboardingPage(
      title: 'Chat Securely',
      description:
          'Your conversations are private and secure. Share moments and plan your first date.',
      icon: Icons.chat_bubble_rounded,
      iconGradient: DsGradients.chats,
    ),
    OnboardingPage(
      title: 'Be Yourself',
      description:
          'Create an authentic profile with photos and prompts. The more you share, the better your matches!',
      icon: Icons.auto_awesome_rounded,
      iconGradient: DsGradients.profile,
    ),
  ];
}

/// An animated onboarding flow widget.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.pages,
    required this.onComplete,
    this.onSkip,
    this.showSkip = true,
  });

  /// List of onboarding pages.
  final List<OnboardingPage> pages;

  /// Called when onboarding is completed.
  final VoidCallback onComplete;

  /// Called when skip is pressed.
  final VoidCallback? onSkip;

  /// Whether to show the skip button.
  final bool showSkip;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticService.lightTap();
    if (_currentPage < widget.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      HapticService.success();
      widget.onComplete();
    }
  }

  void _skip() {
    HapticService.lightTap();
    widget.onSkip?.call();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        DsColors.backgroundDark,
                        DsColors.surfaceDark,
                      ]
                    : [
                        DsColors.backgroundLight,
                        DsColors.surfaceLight,
                      ],
              ),
            ),
          ),

          // Page view
          PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (index) {
              HapticService.selection();
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _OnboardingPageView(
                page: widget.pages[index],
                isActive: _currentPage == index,
              );
            },
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DsSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    _PageIndicators(
                      count: widget.pages.length,
                      currentIndex: _currentPage,
                    ),
                    const SizedBox(height: DsSpacing.xl),
                    // Buttons
                    Row(
                      children: [
                        // Skip button
                        if (widget.showSkip &&
                            _currentPage < widget.pages.length - 1)
                          TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                                fontSize: 16,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 60),
                        const Spacer(),
                        // Next/Get Started button
                        GlassPrimaryButton(
                          onPressed: _nextPage,
                          child: Text(
                            _currentPage == widget.pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.page,
    required this.isActive,
  });

  final OnboardingPage page;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Icon with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: isActive ? 1 : 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: _AnimatedIconContainer(
              icon: page.icon,
              gradient: page.iconGradient ??
                  const LinearGradient(
                    colors: [DsColors.primary, DsColors.secondary],
                  ),
            ),
          ),
          const SizedBox(height: DsSpacing.xxl),
          // Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: isActive ? 1 : 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              page.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? DsColors.textPrimaryDark
                    : DsColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          // Description
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: isActive ? 1 : 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _AnimatedIconContainer extends StatefulWidget {
  const _AnimatedIconContainer({
    required this.icon,
    required this.gradient,
  });

  final IconData icon;
  final LinearGradient gradient;

  @override
  State<_AnimatedIconContainer> createState() => _AnimatedIconContainerState();
}

class _AnimatedIconContainerState extends State<_AnimatedIconContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.gradient,
          boxShadow: [
            BoxShadow(
              color: widget.gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final motionScale =
        Theme.of(context).extension<CrushThemeEffects>()?.motionScale ?? 1.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: Duration(milliseconds: (300 * motionScale).round()),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive
                ? const LinearGradient(
                    colors: [DsColors.primary, DsColors.secondary],
                  )
                : null,
            color: isActive
                ? null
                : DsGlassColors.surfaceFor(
                    context,
                    strength: DsGlassSurfaceStrength.medium,
                  ),
          ),
        );
      }),
    );
  }
}

/// A compact onboarding tooltip for specific features.
class OnboardingTooltip extends StatefulWidget {
  const OnboardingTooltip({
    super.key,
    required this.child,
    required this.message,
    this.title,
    this.onDismiss,
    this.showArrow = true,
    this.arrowPosition = ArrowPosition.bottom,
  });

  final Widget child;
  final String message;
  final String? title;
  final VoidCallback? onDismiss;
  final bool showArrow;
  final ArrowPosition arrowPosition;

  @override
  State<OnboardingTooltip> createState() => _OnboardingTooltipState();
}

enum ArrowPosition { top, bottom, left, right }

class _OnboardingTooltipState extends State<OnboardingTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          bottom: widget.arrowPosition == ArrowPosition.bottom ? null : -80,
          top: widget.arrowPosition == ArrowPosition.top ? null : -80,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: _dismiss,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DsRadius.md),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: DsBlur.light,
                    sigmaY: DsBlur.light,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(DsSpacing.md),
                    decoration: BoxDecoration(
                      color: DsGlassColors.surfaceFor(
                        context,
                        strength: DsGlassSurfaceStrength.medium,
                      ),
                      borderRadius: BorderRadius.circular(DsRadius.md),
                      border: Border.all(
                        color: DsColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to dismiss',
                          style: TextStyle(
                            fontSize: 11,
                            color: DsColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
