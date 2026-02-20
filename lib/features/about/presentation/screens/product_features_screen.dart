import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class ProductFeaturesScreen extends StatelessWidget {
  const ProductFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: ListView(
              padding: const EdgeInsets.all(DsSpacing.lg),
              children: [
                Text(
                  'Everything you need to find your perfect match',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Text(
                  'Crush is built with powerful features to help you connect with the right people.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                ),
                const SizedBox(height: DsSpacing.xxl),

                // Core Features
                const _SectionHeader(
                  'Core Features',
                  subtitle: 'Free for everyone',
                ),
                const SizedBox(height: DsSpacing.md),
                const _FeatureCard(
                  icon: Icons.auto_awesome,
                  iconColor: DsColors.primary,
                  title: 'Smart Matching Algorithm',
                  description:
                      'Our AI-powered algorithm learns from your preferences and behavior to show you the most compatible matches based on interests, values, and lifestyle.',
                  badge: 'AI Powered',
                ),
                const _FeatureCard(
                  icon: Icons.tune,
                  iconColor: DsColors.warning,
                  title: 'Advanced Discovery Filters',
                  description:
                      'Filter potential matches by age, distance, interests, education, and more. Find exactly who you\'re looking for.',
                ),
                const _FeatureCard(
                  icon: Icons.chat_bubble_outline,
                  iconColor: DsColors.info,
                  title: 'Rich Messaging',
                  description:
                      'Send text, photos, GIFs, and voice notes. Express yourself fully with our feature-rich chat experience.',
                ),
                const _FeatureCard(
                  icon: Icons.format_quote,
                  iconColor: DsColors.secondary,
                  title: 'Profile Prompts',
                  description:
                      'Stand out with creative prompts that showcase your personality. Break the ice before the conversation even starts.',
                ),
                const _FeatureCard(
                  icon: Icons.place_outlined,
                  iconColor: DsColors.success,
                  title: 'Location-Based Discovery',
                  description:
                      'Find matches near you or expand your search to new areas. Perfect for local dating or meeting people when traveling.',
                ),
                const _FeatureCard(
                  icon: Icons.notifications_outlined,
                  iconColor: DsColors.accent,
                  title: 'Smart Notifications',
                  description:
                      'Get notified when you have new matches, messages, or when someone special is nearby. Stay connected without being overwhelmed.',
                ),

                const SizedBox(height: DsSpacing.xxl),

                // Premium Features
                const _SectionHeader(
                  'Premium Features',
                  subtitle: 'Crush+ & Platinum',
                ),
                const SizedBox(height: DsSpacing.md),
                Container(
                  padding: const EdgeInsets.all(DsSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DsColors.primary.withValues(alpha: 0.08),
                        DsColors.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DsColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      _FeatureCard(
                        icon: Icons.favorite,
                        iconColor: DsColors.primary,
                        title: 'See Who Likes You',
                        description:
                            'No more guessing! See everyone who has already swiped right on you and match instantly.',
                        compact: true,
                      ),
                      _FeatureCard(
                        icon: Icons.replay,
                        iconColor: DsColors.info,
                        title: 'Unlimited Rewinds',
                        description:
                            'Changed your mind? Undo your last swipe and get a second chance with anyone you accidentally passed.',
                        compact: true,
                      ),
                      _FeatureCard(
                        icon: Icons.star,
                        iconColor: DsColors.warning,
                        title: 'Super Likes',
                        description:
                            'Stand out from the crowd. Send Super Likes to show you\'re really interested and get noticed faster.',
                        compact: true,
                      ),
                      _FeatureCard(
                        icon: Icons.public,
                        iconColor: DsColors.success,
                        title: 'Passport Mode',
                        description:
                            'Match with people anywhere in the world. Perfect for planning trips or exploring long-distance connections.',
                        compact: true,
                      ),
                      _FeatureCard(
                        icon: Icons.bolt,
                        iconColor: DsColors.accent,
                        title: 'Priority Boost',
                        description:
                            'Get seen by more people. Boost your profile to the top of the deck and get up to 10x more matches.',
                        compact: true,
                      ),
                      _FeatureCard(
                        icon: Icons.visibility_off,
                        iconColor: DsColors.secondary,
                        title: 'Incognito Mode',
                        description:
                            'Browse privately. Your profile will only be visible to people you like, giving you full control over who sees you.',
                        compact: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DsSpacing.xxl),

                // Safety Features
                const _SectionHeader(
                  'Safety Features',
                  subtitle: 'Your safety is our priority',
                ),
                const SizedBox(height: DsSpacing.md),
                const _FeatureCard(
                  icon: Icons.verified_user,
                  iconColor: DsColors.success,
                  title: 'Photo Verification',
                  description:
                      'Verify your identity with a quick selfie. Get a blue checkmark badge to show others you\'re real and build trust.',
                ),
                const _FeatureCard(
                  icon: Icons.security,
                  iconColor: DsColors.info,
                  title: 'AI-Powered Moderation',
                  description:
                      'Our AI automatically detects and removes inappropriate content, spam, and fake profiles to keep the community safe.',
                ),
                const _FeatureCard(
                  icon: Icons.block,
                  iconColor: DsColors.error,
                  title: 'Easy Blocking & Reporting',
                  description:
                      'Block or report anyone with just a few taps. Our team reviews all reports 24/7 and takes appropriate action.',
                ),
                const _FeatureCard(
                  icon: Icons.lock_outline,
                  iconColor: DsColors.secondary,
                  title: 'Data Privacy',
                  description:
                      'Your data is encrypted and never sold to third parties. You control what you share and can request data deletion at any time.',
                ),
                const _FeatureCard(
                  icon: Icons.safety_check,
                  iconColor: DsColors.primary,
                  title: 'Date Check-In',
                  description:
                      'Share your date details with trusted contacts who can check on you. Get reminders and use the emergency alert if needed.',
                ),

                const SizedBox(height: DsSpacing.xxl),

                // Communication Features
                const _SectionHeader(
                  'Communication Features',
                  subtitle: 'Connect in every way',
                ),
                const SizedBox(height: DsSpacing.md),
                const _FeatureCard(
                  icon: Icons.message_outlined,
                  iconColor: DsColors.primary,
                  title: 'Text Chat',
                  description:
                      'Rich text messaging with read receipts and typing indicators. Share your thoughts seamlessly.',
                ),
                const _FeatureCard(
                  icon: Icons.mic_outlined,
                  iconColor: DsColors.warning,
                  title: 'Voice Notes',
                  description:
                      'Send voice messages to add a personal touch. Let your matches hear the real you.',
                ),
                const _FeatureCard(
                  icon: Icons.videocam_outlined,
                  iconColor: DsColors.info,
                  title: 'Video Chat',
                  description:
                      'Video call your matches directly in the app. A great way to get to know someone before meeting in person.',
                ),
                const _FeatureCard(
                  icon: Icons.card_giftcard,
                  iconColor: DsColors.accent,
                  title: 'Virtual Gifts',
                  description:
                      'Send virtual gifts to show your interest and stand out. A fun way to break the ice.',
                ),

                const SizedBox(height: DsSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.badge,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: compact ? DsSpacing.md : DsSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          DsGap.mdH,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DsColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DsColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
