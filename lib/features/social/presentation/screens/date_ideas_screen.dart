import 'dart:ui';

import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/social/domain/models/date_idea.dart';
import 'package:crushhour/features/social/presentation/bloc/date_ideas_cubit.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen displaying date ideas for matches.
const Key dateIdeasContentConstraintKey = ValueKey<String>(
  'date_ideas_content_constraint',
);

double dateIdeasContentMaxWidthFor(double screenWidth) {
  return DsBreakpoints.contentMaxWidth(screenWidth);
}

class DateIdeasScreen extends StatefulWidget {
  const DateIdeasScreen({super.key, this.matchId});

  final String? matchId;

  @override
  State<DateIdeasScreen> createState() => _DateIdeasScreenState();
}

class _DateIdeasScreenState extends State<DateIdeasScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DateIdeasCubit>().loadIdeas();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Date Ideas',
        actions: [
          BlocBuilder<DateIdeasCubit, DateIdeasState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.shuffle, color: textColor),
                onPressed: () {
                  final cubit = context.read<DateIdeasCubit>();
                  // Clear filters and show random suggestions
                  cubit.clearFilters();
                  cubit.getPersonalizedSuggestions(count: 5);
                },
                tooltip: 'Random Ideas',
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? DsColors.backgroundDark
                    : DsColors.backgroundLight,
              ),
              child: const Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DsGradients.meshRadial,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxContentWidth = dateIdeasContentMaxWidthFor(
                  constraints.maxWidth,
                );
                return Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    key: dateIdeasContentConstraintKey,
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        // Search and filters
                        Padding(
                          padding: const EdgeInsets.all(DsSpacing.lg),
                          child: Column(
                            children: [
                              // Search bar
                              BlocBuilder<DateIdeasCubit, DateIdeasState>(
                                buildWhen: (previous, current) =>
                                    previous.searchQuery != current.searchQuery,
                                builder: (context, state) {
                                  return GlassTextField(
                                    hintText: 'Search date ideas...',
                                    prefixIcon: Icons.search,
                                    onChanged: (value) {
                                      context.read<DateIdeasCubit>().search(
                                        value,
                                      );
                                    },
                                  );
                                },
                              ),
                              DsGap.md,

                              // Category filters
                              BlocBuilder<DateIdeasCubit, DateIdeasState>(
                                buildWhen: (previous, current) =>
                                    previous.selectedCategory !=
                                    current.selectedCategory,
                                builder: (context, state) {
                                  const categories = DateCategory.values;
                                  return SizedBox(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return _buildFilterChip(
                                            label: 'All',
                                            isSelected:
                                                state.selectedCategory == null,
                                            onTap: () {
                                              context
                                                  .read<DateIdeasCubit>()
                                                  .filterByCategory(null);
                                            },
                                          );
                                        }

                                        final category = categories[index - 1];
                                        return _buildFilterChip(
                                          label: category.displayName,
                                          icon: category.emoji,
                                          isSelected:
                                              state.selectedCategory ==
                                              category,
                                          onTap: () {
                                            context
                                                .read<DateIdeasCubit>()
                                                .filterByCategory(category);
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              DsGap.sm,

                              // Cost filters
                              BlocBuilder<DateIdeasCubit, DateIdeasState>(
                                buildWhen: (previous, current) =>
                                    previous.selectedCostLevel !=
                                    current.selectedCostLevel,
                                builder: (context, state) {
                                  const costs = DateCostLevel.values;
                                  return SizedBox(
                                    height: 32,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: costs.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return _buildCostChip(
                                            cost: null,
                                            isSelected:
                                                state.selectedCostLevel == null,
                                            onTap: () {
                                              context
                                                  .read<DateIdeasCubit>()
                                                  .filterByCostLevel(null);
                                            },
                                          );
                                        }

                                        final cost = costs[index - 1];
                                        return _buildCostChip(
                                          cost: cost,
                                          isSelected:
                                              state.selectedCostLevel == cost,
                                          onTap: () {
                                            context
                                                .read<DateIdeasCubit>()
                                                .filterByCostLevel(cost);
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Ideas list
                        Expanded(
                          child: BlocBuilder<DateIdeasCubit, DateIdeasState>(
                            builder: (context, state) {
                              if (state.isLoading) {
                                return _buildLoadingState();
                              }

                              if (state.errorMessage != null) {
                                return _buildErrorState(
                                  textColor,
                                  state.errorMessage!,
                                );
                              }

                              if (state.filteredIdeas.isEmpty) {
                                return _buildEmptyState(textColor);
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DsSpacing.lg,
                                ),
                                itemCount: state.filteredIdeas.length,
                                itemBuilder: (context, index) {
                                  return _buildIdeaCard(
                                    state.filteredIdeas[index],
                                    textColor,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(Color textColor, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          DsGap.md,
          Text(
            'Something went wrong',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          DsGap.sm,
          Text(
            message,
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
          DsGap.lg,
          GlassOutlinedButton(
            onPressed: () {
              context.read<DateIdeasCubit>().loadIdeas();
            },
            child: Text(AppLocalizations.of(context).tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: DsSpacing.sm),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: isSelected
              ? GlassChip.selected(label: icon != null ? '$icon $label' : label)
              : GlassChip(label: icon != null ? '$icon $label' : label),
        ),
      ),
    );
  }

  Widget _buildCostChip({
    required DateCostLevel? cost,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final label = cost?.display ?? 'Any Budget';

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: DsSpacing.sm),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: DsSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? DsColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DsRadius.round),
              border: Border.all(
                color: isSelected ? DsColors.primary : DsColors.textMutedLight,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? DsColors.primary : null,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          DsGap.md,
          Text(
            'No ideas found',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          DsGap.sm,
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaCard(DateIdea idea, Color textColor) {
    return BlocBuilder<DateIdeasCubit, DateIdeasState>(
      buildWhen: (previous, current) =>
          previous.savedIdeas != current.savedIdeas,
      builder: (context, state) {
        final cubit = context.read<DateIdeasCubit>();
        final isSaved = cubit.isIdeaSaved(idea.id);

        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: DsSpacing.md),
          child: GlassCard(
            onTap: () => _showIdeaDetails(idea, textColor),
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(idea.emoji, style: const TextStyle(fontSize: 32)),
                    DsGap.mdH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idea.title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DsGap.xs,
                          Row(
                            children: [
                              GlassChip(
                                label: idea.category.displayName,
                                height: 24,
                              ),
                              DsGap.smH,
                              if (idea.estimatedCost != null)
                                Text(
                                  idea.costDisplay,
                                  style: const TextStyle(
                                    color: DsColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: isSaved ? DsColors.primary : textColor,
                      ),
                      onPressed: () {
                        if (isSaved) {
                          cubit.removeSavedIdea(idea.id);
                        } else {
                          cubit.saveIdea(idea);
                        }
                      },
                    ),
                  ],
                ),
                DsGap.md,
                Text(
                  idea.description,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                DsGap.md,
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    DsGap.xsH,
                    Text(
                      idea.durationDisplay,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    DsGap.lgH,
                    if (idea.bestFor.isNotEmpty) ...[
                      Icon(
                        Icons.people,
                        size: 16,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      DsGap.xsH,
                      Text(
                        idea.bestFor.first.displayName,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIdeaDetails(DateIdea idea, Color textColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _IdeaDetailsSheet(idea: idea, matchId: widget.matchId),
    );
  }
}

class _IdeaDetailsSheet extends StatelessWidget {
  const _IdeaDetailsSheet({required this.idea, required this.matchId});

  final DateIdea idea;
  final String? matchId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DsRadius.xxl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            decoration: BoxDecoration(
              color: DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.heavy,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DsRadius.xxl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsetsDirectional.only(top: DsSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DsSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(
                              idea.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                            DsGap.lgH,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    idea.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  DsGap.xs,
                                  Row(
                                    children: [
                                      GlassChip(
                                        label: idea.category.displayName,
                                      ),
                                      DsGap.smH,
                                      if (idea.estimatedCost != null)
                                        GlassChip(label: idea.costDisplay),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        DsGap.xl,

                        // Description
                        Text(
                          idea.description,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        DsGap.xl,

                        // Details
                        _buildDetailRow(
                          icon: Icons.timer,
                          label: 'Duration',
                          value: idea.durationDisplay,
                          textColor: textColor,
                        ),
                        if (idea.estimatedCost != null)
                          _buildDetailRow(
                            icon: Icons.attach_money,
                            label: 'Cost',
                            value: idea.estimatedCost!.description,
                            textColor: textColor,
                          ),
                        if (idea.bestFor.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.favorite,
                            label: 'Best For',
                            value: idea.bestFor
                                .map((t) => t.displayName)
                                .join(', '),
                            textColor: textColor,
                          ),
                        if (idea.requirements.isNotEmpty) ...[
                          DsGap.lg,
                          Text(
                            'What You\'ll Need',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DsGap.sm,
                          Wrap(
                            spacing: DsSpacing.sm,
                            runSpacing: DsSpacing.sm,
                            children: idea.requirements.map((req) {
                              return GlassChip.icon(
                                icon: Icons.check_circle,
                                label: req,
                              );
                            }).toList(),
                          ),
                        ],
                        if (idea.tags.isNotEmpty) ...[
                          DsGap.lg,
                          Wrap(
                            spacing: DsSpacing.sm,
                            runSpacing: DsSpacing.sm,
                            children: idea.tags.map((tag) {
                              return GlassChip(label: '#$tag');
                            }).toList(),
                          ),
                        ],
                        DsGap.xl,

                        // Action buttons
                        BlocBuilder<DateIdeasCubit, DateIdeasState>(
                          builder: (context, state) {
                            final cubit = context.read<DateIdeasCubit>();

                            return Row(
                              children: [
                                Expanded(
                                  child: GlassOutlinedButton(
                                    onPressed: () {
                                      cubit.saveIdea(idea);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).savedToYourIdeas,
                                          ),
                                          backgroundColor: DsColors.primary,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.bookmark, size: 18),
                                        const SizedBox(width: DsSpacing.sm),
                                        Text(AppLocalizations.of(context).save),
                                      ],
                                    ),
                                  ),
                                ),
                                if (matchId != null) ...[
                                  DsGap.mdH,
                                  Expanded(
                                    child: GlassPrimaryButton(
                                      onPressed: () async {
                                        await cubit.sendIdeaToMatch(
                                          matchId: matchId!,
                                          idea: idea,
                                        );
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(
                                                context,
                                              ).ideaSent,
                                            ),
                                            backgroundColor: DsColors.primary,
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.send, size: 18),
                                          const SizedBox(width: DsSpacing.sm),
                                          Text(
                                            AppLocalizations.of(context).send,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        DsGap.lg,
                      ],
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: DsSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DsColors.primary),
          DsGap.mdH,
          Text(
            label,
            style: TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
