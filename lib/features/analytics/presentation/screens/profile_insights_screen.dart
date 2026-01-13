import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';
import 'package:crushhour/features/analytics/data/models/profile_insights.dart';

/// Screen displaying profile analytics and insights.
class ProfileInsightsScreen extends StatefulWidget {
  const ProfileInsightsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ProfileInsightsScreen> createState() => _ProfileInsightsScreenState();
}

class _ProfileInsightsScreenState extends State<ProfileInsightsScreen> {
  final _service = ProfileInsightsService.instance;
  ProfileInsights? _insights;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final insights = await _service.loadInsights(widget.userId);
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load insights. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Profile Insights',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadInsights,
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
                ? _buildSkeletonLoading()
                : _errorMessage != null
                    ? _buildErrorState(textColor)
                    : _insights == null
                        ? _buildEmptyState(textColor)
                        : _buildInsightsContent(context, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return DsShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            const SkeletonBox(width: 120, height: 24),
            DsGap.md,
            // Stats cards row 1
            Row(
              children: [
                Expanded(child: _buildSkeletonStatCard()),
                DsGap.mdH,
                Expanded(child: _buildSkeletonStatCard()),
              ],
            ),
            DsGap.md,
            // Stats cards row 2
            Row(
              children: [
                Expanded(child: _buildSkeletonStatCard()),
                DsGap.mdH,
                Expanded(child: _buildSkeletonStatCard()),
              ],
            ),
            DsGap.xl,
            // Activity section skeleton
            _buildSkeletonSection(height: 160),
            DsGap.xl,
            // Best time section skeleton
            _buildSkeletonSection(height: 80),
            DsGap.xl,
            // Photo performance skeleton
            const SkeletonBox(width: 150, height: 20),
            DsGap.md,
            _buildSkeletonSection(height: 140),
            DsGap.xl,
            // Weekly trend skeleton
            const SkeletonBox(width: 120, height: 20),
            DsGap.md,
            _buildSkeletonSection(height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStatCard() {
    return Container(
      padding: const EdgeInsets.all(DsSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? DsColors.surfaceDark
            : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(DsRadius.lg),
      ),
      child: const Column(
        children: [
          SkeletonBox(width: 40, height: 40, borderRadius: DsRadius.sm),
          SizedBox(height: DsSpacing.md),
          SkeletonBox(width: 60, height: 28),
          SizedBox(height: DsSpacing.xs),
          SkeletonBox(width: 80, height: 14),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? DsColors.surfaceDark
            : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(DsRadius.lg),
      ),
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DsSpacing.lg),
              decoration: BoxDecoration(
                color: DsColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: DsColors.error.withValues(alpha: 0.8),
              ),
            ),
            DsGap.lg,
            Text(
              'Something went wrong',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            DsGap.sm,
            Text(
              _errorMessage ?? 'Unable to load insights',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            DsGap.xl,
            GlassPrimaryButton(
              onPressed: _loadInsights,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Try Again'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: textColor.withValues(alpha: 0.5)),
          DsGap.md,
          Text(
            'No insights available yet',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          DsGap.sm,
          Text(
            'Keep using the app to see your analytics',
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(BuildContext context, Color textColor) {
    return RefreshIndicator(
      onRefresh: _loadInsights,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(textColor),
            DsGap.xl,
            _buildActivitySection(textColor),
            DsGap.xl,
            _buildBestTimeSection(textColor),
            DsGap.xl,
            _buildPhotoPerformanceSection(textColor),
            DsGap.xl,
            _buildWeeklyTrendSection(textColor),
            DsGap.lg,
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        DsGap.md,
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.visibility,
                value: '${_insights!.profileViews}',
                label: 'Profile Views',
                gradient: DsGradients.discover,
              ),
            ),
            DsGap.mdH,
            Expanded(
              child: _StatCard(
                icon: Icons.favorite,
                value: '${_insights!.likesReceived}',
                label: 'Likes Received',
                gradient: DsGradients.matches,
              ),
            ),
          ],
        ),
        DsGap.md,
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.star,
                value: '${_insights!.superLikesReceived}',
                label: 'Super Likes',
                gradient: DsGradients.chats,
              ),
            ),
            DsGap.mdH,
            Expanded(
              child: _StatCard(
                icon: Icons.percent,
                value: '${(_insights!.matchRate * 100).toStringAsFixed(0)}%',
                label: 'Match Rate',
                gradient: DsGradients.profile,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitySection(Color textColor) {
    return GlassCard(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          DsGap.md,
          _buildActivityRow(
            icon: Icons.send,
            label: 'Likes Sent',
            value: '${_insights!.likesSent}',
            textColor: textColor,
          ),
          DsGap.sm,
          _buildActivityRow(
            icon: Icons.chat_bubble,
            label: 'Response Rate',
            value: '${(_insights!.responseRate * 100).toStringAsFixed(0)}%',
            textColor: textColor,
          ),
          DsGap.sm,
          _buildActivityRow(
            icon: Icons.timer,
            label: 'Avg Response Time',
            value: _formatDuration(_insights!.averageResponseTime),
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DsColors.primary),
        DsGap.smH,
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: textColor.withValues(alpha: 0.8)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBestTimeSection(Color textColor) {
    return GlassCardAccent(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DsSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DsRadius.md),
            ),
            child: const Icon(Icons.access_time, color: Colors.white, size: 28),
          ),
          DsGap.lgH,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Time to Be Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DsGap.xs,
                Text(
                  _service.getBestTimeToBeActive(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPerformanceSection(Color textColor) {
    final photos = _service.getPhotoPerformance();
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Performance',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        DsGap.md,
        GlassCard(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: Column(
            children: photos.take(3).map((photo) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DsRadius.sm),
                      ),
                      child: Center(
                        child: Text(
                          '#${photo.photoIndex + 1}',
                          style: const TextStyle(
                            color: DsColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DsGap.mdH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photo ${photo.photoIndex + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${photo.views} views • ${photo.likes} likes',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.sm,
                        vertical: DsSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DsRadius.round),
                      ),
                      child: Text(
                        '${(photo.likeRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: DsColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendSection(Color textColor) {
    final trend = _insights?.weeklyTrend ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Trend',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        DsGap.md,
        GlassCard(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((metric) {
                final maxViews = trend.map((m) => m.views).reduce((a, b) => a > b ? a : b);
                final height = maxViews > 0 ? (metric.views / maxViews) * 80 : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: height.clamp(8.0, 80.0),
                      decoration: BoxDecoration(
                        gradient: DsGradients.primaryVertical,
                        borderRadius: BorderRadius.circular(DsRadius.sm),
                      ),
                    ),
                    DsGap.xs,
                    Text(
                      _getDayLabel(metric.date),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final minutes = duration.inMinutes;
    if (minutes < 60) return '${minutes}m';
    return '${duration.inHours}h ${minutes % 60}m';
  }

  String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  final IconData icon;
  final String value;
  final String label;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DsSpacing.sm),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(DsRadius.sm),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          DsGap.md,
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          DsGap.xs,
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? DsColors.textMutedDark
                  : DsColors.textMutedLight,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
