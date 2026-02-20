import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// A glassmorphism card displaying a profile prompt.
class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    this.onTap,
    this.showEmoji = true,
    this.compact = false,
  });

  final ProfilePrompt prompt;
  final VoidCallback? onTap;
  final bool showEmoji;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
          child: Container(
            padding: compact ? DsEdgeInsets.allMd : DsEdgeInsets.allLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DsGlassColors.surfaceFor(context),
                  DsGlassColors.surfaceFor(
                    context,
                    strength: DsGlassSurfaceStrength.medium,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(DsRadius.lg),
              border: Border.all(
                color: DsGlassColors.borderFor(context),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Question header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showEmoji) ...[
                      Text(
                        prompt.emoji,
                        style: TextStyle(fontSize: compact ? 18 : 24),
                      ),
                      DsGap.smH,
                    ],
                    Expanded(
                      child: Text(
                        prompt.question,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                DsGap.sm,
                // Answer
                Text(
                  prompt.answer,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: compact ? 3 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal scrollable list of prompt cards.
class PromptCardList extends StatelessWidget {
  const PromptCardList({
    super.key,
    required this.prompts,
    this.onPromptTap,
    this.compact = false,
    this.padding,
  });

  final List<ProfilePrompt> prompts;
  final void Function(ProfilePrompt)? onPromptTap;
  final bool compact;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: compact ? 120 : 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? DsEdgeInsets.horizontalLg,
        itemCount: prompts.length,
        separatorBuilder: (context, index) => DsGap.mdH,
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return SizedBox(
            width: 280,
            child: PromptCard(
              prompt: prompt,
              compact: compact,
              onTap: onPromptTap != null ? () => onPromptTap!(prompt) : null,
            ),
          );
        },
      ),
    );
  }
}

/// A single-column vertical list of prompt cards.
class PromptCardColumn extends StatelessWidget {
  const PromptCardColumn({super.key, required this.prompts, this.onPromptTap});

  final List<ProfilePrompt> prompts;
  final void Function(ProfilePrompt)? onPromptTap;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: prompts.map((prompt) {
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 12),
          child: PromptCard(
            prompt: prompt,
            onTap: onPromptTap != null ? () => onPromptTap!(prompt) : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Empty state prompting user to add prompts.
class AddPromptsEmptyState extends StatelessWidget {
  const AddPromptsEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onAdd,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
          child: Container(
            padding: DsEdgeInsets.allLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DsColors.primary.withValues(alpha: 0.1),
                  DsColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(DsRadius.lg),
              border: Border.all(
                color: DsColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: DsEdgeInsets.allMd,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DsColors.primary, DsColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(DsRadius.md),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: DsColors.surfaceLight,
                    size: 28,
                  ),
                ),
                DsGap.md,
                Text(
                  'Add Conversation Starters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DsGap.xs,
                Text(
                  'Help others start a conversation with you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                DsGap.md,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: DsColors.primary,
                    ),
                    DsGap.xsH,
                    Text(
                      'Add up to ${PromptQuestions.maxPromptsPerProfile} prompts',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DsColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
