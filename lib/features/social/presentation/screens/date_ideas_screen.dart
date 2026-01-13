import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/social/data/services/date_idea_service.dart';
import 'package:crushhour/features/social/data/models/date_idea.dart';

/// Screen displaying date ideas for matches.
class DateIdeasScreen extends StatefulWidget {
  const DateIdeasScreen({super.key, this.matchId});

  final String? matchId;

  @override
  State<DateIdeasScreen> createState() => _DateIdeasScreenState();
}

class _DateIdeasScreenState extends State<DateIdeasScreen> {
  final _service = DateIdeaService.instance;
  DateCategory? _selectedCategory;
  DateCostLevel? _selectedCost;
  String _searchQuery = '';
  List<DateIdea> _filteredIdeas = [];

  @override
  void initState() {
    super.initState();
    _filteredIdeas = _service.getAllIdeas();
  }

  void _applyFilters() {
    var ideas = _service.getAllIdeas();

    if (_selectedCategory != null) {
      ideas = ideas.where((i) => i.category == _selectedCategory).toList();
    }

    if (_selectedCost != null) {
      ideas = ideas.where((i) =>
        i.estimatedCost != null && i.estimatedCost!.index <= _selectedCost!.index
      ).toList();
    }

    if (_searchQuery.isNotEmpty) {
      ideas = _service.searchIdeas(_searchQuery);
    }

    setState(() => _filteredIdeas = ideas);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Date Ideas',
        actions: [
          IconButton(
            icon: Icon(Icons.shuffle, color: textColor),
            onPressed: () {
              setState(() {
                _filteredIdeas = _service.getRandomSuggestions(5);
              });
            },
            tooltip: 'Random Ideas',
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
            child: Column(
              children: [
                // Search and filters
                Padding(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Column(
                    children: [
                      // Search bar
                      GlassTextField(
                        hintText: 'Search date ideas...',
                        prefixIcon: Icons.search,
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFilters();
                        },
                      ),
                      DsGap.md,

                      // Category filters
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected: _selectedCategory == null,
                              onTap: () {
                                _selectedCategory = null;
                                _applyFilters();
                              },
                            ),
                            ...DateCategory.values.map((category) {
                              return _buildFilterChip(
                                label: category.displayName,
                                icon: category.emoji,
                                isSelected: _selectedCategory == category,
                                onTap: () {
                                  _selectedCategory = category;
                                  _applyFilters();
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      DsGap.sm,

                      // Cost filters
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCostChip(null),
                            ...DateCostLevel.values.map((cost) => _buildCostChip(cost)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ideas list
                Expanded(
                  child: _filteredIdeas.isEmpty
                      ? _buildEmptyState(textColor)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
                          itemCount: _filteredIdeas.length,
                          itemBuilder: (context, index) {
                            return _buildIdeaCard(_filteredIdeas[index], textColor);
                          },
                        ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(right: DsSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: isSelected
            ? GlassChip.selected(label: icon != null ? '$icon $label' : label)
            : GlassChip(label: icon != null ? '$icon $label' : label),
      ),
    );
  }

  Widget _buildCostChip(DateCostLevel? cost) {
    final isSelected = _selectedCost == cost;
    final label = cost?.display ?? 'Any Budget';

    return Padding(
      padding: const EdgeInsets.only(right: DsSpacing.sm),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCost = cost);
          _applyFilters();
        },
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
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: textColor.withValues(alpha: 0.5)),
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
    final isSaved = _service.isIdeaSaved(idea.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.md),
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
                      _service.removeSavedIdea(idea.id);
                    } else {
                      _service.saveIdea(idea);
                    }
                    setState(() {});
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
                Icon(Icons.timer, size: 16, color: textColor.withValues(alpha: 0.6)),
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
                  Icon(Icons.people, size: 16, color: textColor.withValues(alpha: 0.6)),
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
  }

  void _showIdeaDetails(DateIdea idea, Color textColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IdeaDetailsSheet(
        idea: idea,
        matchId: widget.matchId,
        service: _service,
      ),
    );
  }
}

class _IdeaDetailsSheet extends StatelessWidget {
  const _IdeaDetailsSheet({
    required this.idea,
    required this.matchId,
    required this.service,
  });

  final DateIdea idea;
  final String? matchId;
  final DateIdeaService service;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DsRadius.xxl)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? DsGlassColors.surfaceHeavyDark : DsGlassColors.surfaceHeavyLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DsRadius.xxl)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: DsSpacing.md),
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
                            Text(idea.emoji, style: const TextStyle(fontSize: 48)),
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
                                      GlassChip(label: idea.category.displayName),
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
                            value: idea.bestFor.map((t) => t.displayName).join(', '),
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
                        Row(
                          children: [
                            Expanded(
                              child: GlassOutlinedButton(
                                onPressed: () {
                                  service.saveIdea(idea);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saved to your ideas!'),
                                      backgroundColor: DsColors.primary,
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bookmark, size: 18),
                                    SizedBox(width: DsSpacing.sm),
                                    Text('Save'),
                                  ],
                                ),
                              ),
                            ),
                            if (matchId != null) ...[
                              DsGap.mdH,
                              Expanded(
                                child: GlassPrimaryButton(
                                  onPressed: () async {
                                    await service.sendIdeaToMatch(
                                      matchId: matchId!,
                                      idea: idea,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Idea sent!'),
                                        backgroundColor: DsColors.primary,
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, size: 18),
                                      SizedBox(width: DsSpacing.sm),
                                      Text('Send'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
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
      padding: const EdgeInsets.only(bottom: DsSpacing.md),
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
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
