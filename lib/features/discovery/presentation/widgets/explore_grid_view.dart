import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';

/// Grid-based explore view for browsing discovery profiles on tablet/desktop.
/// Provides an alternative to the swipe-based deck for wider screens.
class ExploreGridView extends StatelessWidget {
  const ExploreGridView({
    super.key,
    required this.profiles,
    required this.isLoading,
  });

  final List<Profile> profiles;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && profiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profiles.isEmpty) {
      return _buildEmptyState(context);
    }

    final columns = DsBreakpoints.gridColumnsOf(context).clamp(2, 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(DsSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: DsSpacing.sm,
                mainAxisSpacing: DsSpacing.sm,
                childAspectRatio: 0.7,
              ),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return _ExploreCard(
                  profile: profiles[index],
                  onTap: () => context.push(
                    CrushRoutes.userProfile,
                    extra: OtherUserProfileArgs(profile: profiles[index]),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DsColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 64,
                color: DsColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            Text(
              'No profiles to explore',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(
              'Check back later for new people in your area.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single profile card in the explore grid.
class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.displayPhotoUrl;

    return Semantics(
      label:
          '${profile.name}, ${profile.age}'
          '${profile.distanceDisplay != null ? ', ${profile.distanceDisplay}' : ''}',
      button: true,
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DsRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Profile photo
                if (photoUrl != null)
                  CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                else
                  Container(
                    color: DsColors.ink200,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: DsColors.ink400,
                    ),
                  ),

                // Gradient overlay at bottom
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      DsSpacing.sm,
                      DsSpacing.xxxl,
                      DsSpacing.sm,
                      DsSpacing.sm,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profile.name}, ${profile.age}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile.distanceDisplay != null)
                          Text(
                            profile.distanceDisplay!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ),

                // Verification badge
                if (profile.isVerified)
                  PositionedDirectional(
                    top: DsSpacing.sm,
                    end: DsSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: DsColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
