import 'dart:ui';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/features/discovery/presentation/widgets/boost_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeckScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DeckScreenAppBar({
    super.key,
    required this.exploreMode,
    required this.onToggleExploreMode,
    required this.onRefresh,
    required this.canRefresh,
  });

  final bool exploreMode;
  final VoidCallback onToggleExploreMode;
  final VoidCallback onRefresh;
  final bool canRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final baseSurface = DsGlassColors.surfaceFor(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                baseSurface.withValues(alpha: 0.8),
                baseSurface.withValues(alpha: 0.6),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: DsGlassColors.borderFor(context),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          DsGradients.primaryHorizontal.createShader(
                            bounds,
                            textDirection: Directionality.of(context),
                          ),
                      child: Text(
                        'Crush',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DsColors.surfaceLight,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: DsSpacing.sm,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BoostButton(),
                        const SizedBox(width: DsSpacing.xs),
                        GlassIconButton(
                          icon: Icons.auto_awesome,
                          onPressed: () =>
                              context.push(CrushRoutes.weeklyPicks),
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    end: DsSpacing.sm,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!DsBreakpoints.isMobile(
                          MediaQuery.sizeOf(context).width,
                        ))
                          GlassIconButton(
                            icon: exploreMode
                                ? Icons.view_carousel
                                : Icons.grid_view_rounded,
                            onPressed: onToggleExploreMode,
                            size: 40,
                          ),
                        if (!DsBreakpoints.isMobile(
                          MediaQuery.sizeOf(context).width,
                        ))
                          const SizedBox(width: DsSpacing.xs),
                        GlassIconButton(
                          icon: Icons.refresh,
                          onPressed: canRefresh ? onRefresh : () {},
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
