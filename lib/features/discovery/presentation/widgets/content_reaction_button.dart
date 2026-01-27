import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/blur.dart';

/// A floating reaction button that appears on photos/prompts.
class ContentReactionButton extends StatefulWidget {
  const ContentReactionButton({
    super.key,
    required this.onReaction,
    required this.onComment,
    this.reactions = QuickReaction.photoReactions,
    this.compact = false,
    this.showCommentButton = true,
  });

  /// Called when a reaction is selected.
  final ValueChanged<String> onReaction;

  /// Called when user wants to add a comment.
  final VoidCallback onComment;

  /// Available quick reactions.
  final List<QuickReaction> reactions;

  /// Compact mode for smaller display.
  final bool compact;

  /// Whether to show the comment button.
  final bool showCommentButton;

  @override
  State<ContentReactionButton> createState() => _ContentReactionButtonState();
}

class _ContentReactionButtonState extends State<ContentReactionButton>
    with SingleTickerProviderStateMixin {
  bool _showReactions = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleReactions() {
    HapticFeedback.lightImpact();
    setState(() {
      _showReactions = !_showReactions;
      if (_showReactions) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectReaction(String type) {
    HapticFeedback.mediumImpact();
    widget.onReaction(type);
    _toggleReactions();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.compact ? 40.0 : 48.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main button
        GestureDetector(
          onTap: _toggleReactions,
          child: _GlassIconButton(
            icon: Icons.add_reaction_outlined,
            size: buttonSize,
            isActive: _showReactions,
          ),
        ),

        // Expanded reaction picker
        if (_showReactions)
          Positioned(
            bottom: buttonSize + 8,
            left: -(widget.reactions.length * 24.0),
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomCenter,
              child: _ReactionPicker(
                reactions: widget.reactions,
                onSelect: _selectReaction,
                onComment: widget.showCommentButton ? widget.onComment : null,
                compact: widget.compact,
              ),
            ),
          ),
      ],
    );
  }
}

/// Glass-styled icon button.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    this.size = 48,
    this.isActive = false,
  });

  final IconData icon;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [DsColors.primary, DsColors.secondary],
                  )
                : null,
            color: isActive ? null : DsColors.ink900.withValues(alpha: 0.4),
            border: Border.all(
              color: isActive
                  ? DsColors.surfaceLight.withValues(alpha: 0.5)
                  : DsColors.surfaceLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: DsColors.surfaceLight,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Reaction picker popup.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({
    required this.reactions,
    required this.onSelect,
    this.onComment,
    this.compact = false,
  });

  final List<QuickReaction> reactions;
  final ValueChanged<String> onSelect;
  final VoidCallback? onComment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final itemSize = compact ? 40.0 : 48.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.medium,
          sigmaY: DsBlur.medium,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? DsSpacing.sm : DsSpacing.md,
            vertical: compact ? DsSpacing.xs : DsSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DsColors.surfaceLight.withValues(alpha: 0.2),
                DsColors.surfaceLight.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(DsRadius.xl),
            border: Border.all(
              color: DsColors.surfaceLight.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DsColors.ink900.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji reactions
              ...reactions.map((reaction) => _ReactionItem(
                    reaction: reaction,
                    size: itemSize,
                    onTap: () => onSelect(reaction.type),
                  )),

              // Divider and comment button
              if (onComment != null) ...[
                Container(
                  width: 1,
                  height: itemSize * 0.6,
                  margin: const EdgeInsets.symmetric(horizontal: DsSpacing.xs),
                  color: DsColors.surfaceLight.withValues(alpha: 0.3),
                ),
                _CommentButton(
                  size: itemSize,
                  onTap: onComment!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual reaction item with animation.
class _ReactionItem extends StatefulWidget {
  const _ReactionItem({
    required this.reaction,
    required this.size,
    required this.onTap,
  });

  final QuickReaction reaction;
  final double size;
  final VoidCallback onTap;

  @override
  State<_ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<_ReactionItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          child: Text(
            widget.reaction.emoji,
            style: TextStyle(fontSize: widget.size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Comment button in reaction picker.
class _CommentButton extends StatelessWidget {
  const _CommentButton({
    required this.size,
    required this.onTap,
  });

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: DsColors.surfaceLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(size / 2.0),
        ),
        child: Icon(
          Icons.chat_bubble_outline,
          color: DsColors.surfaceLight,
          size: size * 0.45,
        ),
      ),
    );
  }
}

/// A floating reaction indicator showing the sent reaction.
class SentReactionIndicator extends StatefulWidget {
  const SentReactionIndicator({
    super.key,
    required this.emoji,
    this.onAnimationComplete,
  });

  final String emoji;
  final VoidCallback? onAnimationComplete;

  @override
  State<SentReactionIndicator> createState() => _SentReactionIndicatorState();
}

class _SentReactionIndicatorState extends State<SentReactionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Comment input dialog for adding a message with a reaction.
class ReactionCommentDialog extends StatefulWidget {
  const ReactionCommentDialog({
    super.key,
    required this.contentPreview,
    required this.contentType,
    this.initialReaction = 'like',
  });

  final String contentPreview;
  final ReactionContentType contentType;
  final String initialReaction;

  @override
  State<ReactionCommentDialog> createState() => _ReactionCommentDialogState();
}

class _ReactionCommentDialogState extends State<ReactionCommentDialog> {
  final _commentController = TextEditingController();
  late String _selectedReaction;

  @override
  void initState() {
    super.initState();
    _selectedReaction = widget.initialReaction;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = widget.contentType == ReactionContentType.prompt
        ? QuickReaction.promptReactions
        : QuickReaction.photoReactions;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsBlur.heavy,
            sigmaY: DsBlur.heavy,
          ),
          child: Container(
            padding: const EdgeInsets.all(DsSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? DsColors.surfaceDark.withValues(alpha: 0.85)
                  : DsColors.surfaceLight.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(DsRadius.xl),
              border: Border.all(
                color: DsColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  widget.contentType == ReactionContentType.prompt
                      ? 'React to this answer'
                      : 'React to this photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DsSpacing.lg),

                // Content preview
                Container(
                  padding: const EdgeInsets.all(DsSpacing.md),
                  decoration: BoxDecoration(
                    color: DsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DsRadius.md),
                  ),
                  child: Text(
                    widget.contentPreview,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: DsSpacing.lg),

                // Reaction selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: reactions.map((reaction) {
                    final isSelected = _selectedReaction == reaction.type;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedReaction = reaction.type);
                        HapticFeedback.lightImpact();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DsColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(DsRadius.md),
                          border: Border.all(
                            color: isSelected
                                ? DsColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            reaction.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: DsSpacing.lg),

                // Comment input
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment (optional)...',
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? DsColors.inputFillDark
                        : DsColors.inputFillLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DsRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DsRadius.md),
                      borderSide: const BorderSide(
                        color: DsColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: DsSpacing.md),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: DsSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'reaction': _selectedReaction,
                            'comment': _commentController.text.trim(),
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DsColors.primary,
                          foregroundColor: DsColors.surfaceLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DsRadius.md),
                          ),
                        ),
                        child: const Text('Send'),
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
