import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// Editor for managing profile prompts.
class PromptEditor extends StatelessWidget {
  const PromptEditor({
    super.key,
    required this.prompts,
    required this.onPromptsChanged,
    this.maxPrompts = 3,
  });

  final List<ProfilePrompt> prompts;
  final ValueChanged<List<ProfilePrompt>> onPromptsChanged;
  final int maxPrompts;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Conversation Starters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${prompts.length}/$maxPrompts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
            ),
          ],
        ),
        DsGap.xs,
        Text(
          'Help others start a conversation with you',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        DsGap.lg,

        // Existing prompts
        ...prompts.asMap().entries.map((entry) {
          final index = entry.key;
          final prompt = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PromptTile(
              prompt: prompt,
              onEdit: () => _showEditPromptSheet(context, prompt, index),
              onDelete: () {
                final updated = List<ProfilePrompt>.from(prompts);
                updated.removeAt(index);
                onPromptsChanged(updated);
              },
            ),
          );
        }),

        // Add prompt button
        if (prompts.length < maxPrompts)
          _AddPromptButton(
            onTap: () => _showAddPromptSheet(context),
          ),
      ],
    );
  }

  void _showAddPromptSheet(BuildContext context) {
    showModalBottomSheet<ProfilePrompt?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromptQuestionPicker(
        existingQuestionIds: prompts.map((p) => p.questionId).toSet(),
      ),
    ).then((newPrompt) {
      if (newPrompt != null) {
        final updated = List<ProfilePrompt>.from(prompts);
        updated.add(newPrompt);
        onPromptsChanged(updated);
      }
    });
  }

  void _showEditPromptSheet(BuildContext context, ProfilePrompt prompt, int index) {
    showModalBottomSheet<ProfilePrompt?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromptAnswerEditor(
        prompt: prompt,
      ),
    ).then((updatedPrompt) {
      if (updatedPrompt != null) {
        final updated = List<ProfilePrompt>.from(prompts);
        updated[index] = updatedPrompt;
        onPromptsChanged(updated);
      }
    });
  }
}

/// A tile showing an existing prompt with edit/delete actions.
class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.prompt,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfilePrompt prompt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
        child: Container(
          padding: DsEdgeInsets.allMd,
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
            children: [
              Row(
                children: [
                  Text(
                    prompt.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  DsGap.smH,
                  Expanded(
                    child: Text(
                      prompt.question,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      foregroundColor: DsColors.secondary,
                    ),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      foregroundColor: DsColors.error,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              DsGap.sm,
              Text(
                prompt.answer,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Button to add a new prompt.
class _AddPromptButton extends StatelessWidget {
  const _AddPromptButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: DsEdgeInsets.allLg,
        decoration: BoxDecoration(
          color: isDark
              ? DsColors.surfaceLight.withValues(alpha: 0.05)
              : DsColors.ink900.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DsRadius.lg),
          border: Border.all(
            color: DsColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: DsColors.primary,
              size: 24,
            ),
            DsGap.smH,
            Text(
              'Add a conversation starter',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: DsColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting a prompt question.
class _PromptQuestionPicker extends StatefulWidget {
  const _PromptQuestionPicker({
    required this.existingQuestionIds,
  });

  final Set<String> existingQuestionIds;

  @override
  State<_PromptQuestionPicker> createState() => _PromptQuestionPickerState();
}

class _PromptQuestionPickerState extends State<_PromptQuestionPicker> {
  String? _selectedCategory;
  PromptQuestion? _selectedQuestion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DsRadius.xl),
          topRight: Radius.circular(DsRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DsColors.ink300.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          DsGap.md,
          // Header
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Row(
              children: [
                if (_selectedCategory != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedQuestion = null;
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _selectedQuestion != null
                        ? 'Answer the prompt'
                        : _selectedCategory != null
                            ? PromptQuestions.getCategoryDisplayName(_selectedCategory!)
                            : 'Choose a prompt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: _selectedQuestion != null
                ? _buildAnswerInput()
                : _selectedCategory != null
                    ? _buildQuestionList()
                    : _buildCategoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      padding: DsEdgeInsets.allMd,
      itemCount: PromptQuestions.categories.length,
      itemBuilder: (context, index) {
        final category = PromptQuestions.categories[index];
        final questions = PromptQuestions.getByCategory(category);
        final availableCount = questions
            .where((q) => !widget.existingQuestionIds.contains(q.id))
            .length;

        return _CategoryTile(
          category: category,
          availableCount: availableCount,
          onTap: availableCount > 0
              ? () {
                  setState(() => _selectedCategory = category);
                }
              : null,
        );
      },
    );
  }

  Widget _buildQuestionList() {
    final questions = PromptQuestions.getByCategory(_selectedCategory!)
        .where((q) => !widget.existingQuestionIds.contains(q.id))
        .toList();

    return ListView.builder(
      padding: DsEdgeInsets.allMd,
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _QuestionTile(
          question: question,
          onTap: () {
            setState(() => _selectedQuestion = question);
          },
        );
      },
    );
  }

  Widget _buildAnswerInput() {
    return _PromptAnswerEditor(
      prompt: ProfilePrompt(
        questionId: _selectedQuestion!.id,
        answer: '',
      ),
      isNew: true,
      onSave: (prompt) => Navigator.pop(context, prompt),
    );
  }
}

/// Category tile in the question picker.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.availableCount,
    required this.onTap,
  });

  final String category;
  final int availableCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DsRadius.md),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Padding(
              padding: DsEdgeInsets.allMd,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PromptQuestions.getCategoryDisplayName(category),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DsGap.xs,
                        Text(
                          '$availableCount prompts available',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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

/// Question tile in the question picker.
class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.onTap,
  });

  final PromptQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DsRadius.md),
          child: Padding(
            padding: DsEdgeInsets.allMd,
            child: Row(
              children: [
                Text(
                  question.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                DsGap.mdH,
                Expanded(
                  child: Text(
                    question.question,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Editor for writing/editing a prompt answer.
class _PromptAnswerEditor extends StatefulWidget {
  const _PromptAnswerEditor({
    required this.prompt,
    this.isNew = false,
    this.onSave,
  });

  final ProfilePrompt prompt;
  final bool isNew;
  final ValueChanged<ProfilePrompt>? onSave;

  @override
  State<_PromptAnswerEditor> createState() => _PromptAnswerEditorState();
}

class _PromptAnswerEditorState extends State<_PromptAnswerEditor> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prompt.answer);
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = PromptQuestions.getById(widget.prompt.questionId);

    // If embedded in picker, just show the input
    if (widget.onSave != null) {
      return Padding(
        padding: DsEdgeInsets.allLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question display
            Row(
              children: [
                Text(
                  question?.emoji ?? '💭',
                  style: const TextStyle(fontSize: 28),
                ),
                DsGap.mdH,
                Expanded(
                  child: Text(
                    widget.prompt.question,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            DsGap.lg,
            // Answer input
            TextField(
              controller: _controller,
              maxLength: PromptQuestions.maxAnswerLength,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Write your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DsRadius.md),
                ),
                filled: true,
                fillColor: isDark
                    ? DsColors.surfaceLight.withValues(alpha: 0.05)
                    : DsColors.ink900.withValues(alpha: 0.03),
              ),
            ),
            DsGap.lg,
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !_hasText
                    ? null
                    : () {
                        widget.onSave!(widget.prompt.copyWith(
                          answer: _controller.text.trim(),
                          createdAt: DateTime.now(),
                        ));
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      );
    }

    // Full bottom sheet editor
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DsRadius.xl),
          topRight: Radius.circular(DsRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DsColors.ink300.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          DsGap.md,
          // Header
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: Row(
              children: [
                Text(
                  'Edit Answer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: DsEdgeInsets.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question display
                  Row(
                    children: [
                      Text(
                        question?.emoji ?? '💭',
                        style: const TextStyle(fontSize: 28),
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Text(
                          widget.prompt.question,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  DsGap.lg,
                  // Answer input
                  TextField(
                    controller: _controller,
                    maxLength: PromptQuestions.maxAnswerLength,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Write your answer...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DsRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? DsColors.surfaceLight.withValues(alpha: 0.05)
                          : DsColors.ink900.withValues(alpha: 0.03),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Save button
          Padding(
            padding: DsEdgeInsets.allLg,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !_hasText
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          widget.prompt.copyWith(
                            answer: _controller.text.trim(),
                          ),
                        );
                      },
                child: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
