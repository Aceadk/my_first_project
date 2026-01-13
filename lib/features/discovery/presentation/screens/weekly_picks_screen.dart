import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/discovery/data/services/weekly_picks_service.dart';
import 'package:crushhour/features/discovery/data/models/weekly_picks.dart';

/// Screen displaying weekly curated picks for the user.
class WeeklyPicksScreen extends StatefulWidget {
  const WeeklyPicksScreen({super.key, required this.userId});

  final String userId;

  @override
  State<WeeklyPicksScreen> createState() => _WeeklyPicksScreenState();
}

class _WeeklyPicksScreenState extends State<WeeklyPicksScreen> {
  final _service = WeeklyPicksService.instance;
  WeeklyPicks? _picks;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPicks();
  }

  Future<void> _loadPicks() async {
    setState(() => _isLoading = true);
    try {
      final picks = await _service.loadPicks(widget.userId);
      setState(() {
        _picks = picks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Weekly Picks',
        actions: [
          if (_picks != null)
            Padding(
              padding: const EdgeInsets.only(right: DsSpacing.md),
              child: GlassChip(
                label: '${_service.unseenCount} new',
                icon: Icons.star,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
              ),
              child: const Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: DsGradients.meshRadial),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _picks == null || _picks!.picks.isEmpty
                    ? _buildEmptyState(textColor)
                    : _buildPicksContent(context, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 64, color: textColor.withValues(alpha: 0.5)),
          DsGap.md,
          Text(
            'No picks available',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          DsGap.sm,
          Text(
            'Check back next week for new picks!',
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildPicksContent(BuildContext context, Color textColor) {
    return Column(
      children: [
        // Timer until new picks
        Padding(
          padding: const EdgeInsets.all(DsSpacing.lg),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.lg,
              vertical: DsSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: DsColors.primary),
                DsGap.mdH,
                Expanded(
                  child: Text(
                    _service.getNewPicksTimeDisplay(),
                    style: TextStyle(color: textColor),
                  ),
                ),
                Text(
                  '${_picks!.picks.length} picks',
                  style: const TextStyle(
                    color: DsColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Picks carousel
        Expanded(
          child: PageView.builder(
            itemCount: _picks!.picks.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _service.markPickViewed(_picks!.picks[index].id);
            },
            itemBuilder: (context, index) {
              final pick = _picks!.picks[index];
              return _buildPickCard(pick, textColor);
            },
          ),
        ),

        // Page indicator
        Padding(
          padding: const EdgeInsets.all(DsSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_picks!.picks.length, (index) {
              final isActive = index == _currentIndex;
              final isViewed = _service.isPickViewed(_picks!.picks[index].id);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? DsColors.primary
                      : isViewed
                          ? DsColors.primary.withValues(alpha: 0.3)
                          : textColor.withValues(alpha: 0.2),
                ),
              );
            }),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.only(
            left: DsSpacing.xl,
            right: DsSpacing.xl,
            bottom: DsSpacing.xl,
          ),
          child: Row(
            children: [
              Expanded(
                child: GlassOutlinedButton(
                  onPressed: () {
                    if (_currentIndex < _picks!.picks.length - 1) {
                      setState(() => _currentIndex++);
                    }
                  },
                  child: const Text('Pass'),
                ),
              ),
              DsGap.lgH,
              Expanded(
                child: GlassPrimaryButton(
                  onPressed: () {
                    final pick = _picks!.picks[_currentIndex];
                    _service.markPickLiked(pick.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Liked ${pick.reason.displayText}!'),
                        backgroundColor: DsColors.primary,
                      ),
                    );
                    if (_currentIndex < _picks!.picks.length - 1) {
                      setState(() => _currentIndex++);
                    }
                  },
                  child: const Text('Like'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickCard(WeeklyPick pick, Color textColor) {
    final isViewed = _service.isPickViewed(pick.id);
    final isLiked = _service.isPickLiked(pick.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
      child: GlassCard(
        showGradientBorder: isLiked,
        child: Stack(
          children: [
            // Profile placeholder
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DsRadius.xl),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DsColors.primary.withValues(alpha: 0.1),
                      DsColors.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 80,
                      color: textColor.withValues(alpha: 0.3),
                    ),
                    DsGap.md,
                    Text(
                      'Profile #${pick.profileId}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pick reason badge
            Positioned(
              top: DsSpacing.lg,
              left: DsSpacing.lg,
              child: GlassChip.selected(
                label: '${pick.reason.emoji} ${pick.reason.displayText}',
              ),
            ),

            // Viewed indicator
            if (isViewed)
              Positioned(
                top: DsSpacing.lg,
                right: DsSpacing.lg,
                child: GlassStatusBadge(
                  label: isLiked ? 'Liked' : 'Viewed',
                  icon: isLiked ? Icons.favorite : Icons.visibility,
                  color: isLiked ? DsColors.primary : null,
                ),
              ),

            // Bottom info
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(DsRadius.xl),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: DsBlur.medium, sigmaY: DsBlur.medium),
                  child: Container(
                    padding: const EdgeInsets.all(DsSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DsGlassColors.surfaceHeavyDark
                          : DsGlassColors.surfaceHeavyLight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pick.matchScore != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: DsColors.primary, size: 16),
                              DsGap.xsH,
                              Text(
                                '${pick.matchScore}% Match',
                                style: const TextStyle(
                                  color: DsColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          DsGap.sm,
                        ],
                        if (pick.commonInterests.isNotEmpty) ...[
                          Text(
                            'Common interests:',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          DsGap.xs,
                          Wrap(
                            spacing: DsSpacing.xs,
                            runSpacing: DsSpacing.xs,
                            children: pick.commonInterests.take(3).map((interest) {
                              return GlassChip(label: interest, height: 28);
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
