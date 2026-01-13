import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/presentation/widgets/cached_network_image.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

class SwipeCard extends StatelessWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.displayPhotoUrl;
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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileMediaScreen(profile: profile),
          ),
        );
      },
      child: Container(
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
              // Profile image
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: _placeholder(),
                  errorWidget: _placeholder(),
                )
              else
                _placeholder(),

              // Gradient overlay for readability
              Container(
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

              // Verification badge (top right)
              Positioned(
                top: DsSpacing.md,
                right: DsSpacing.md,
                child: _GlassVerificationPill(isVerified: profile.isVerified),
              ),

              // Frosted glass info panel (bottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
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
            ],
          ),
        ),
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
