import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A glassmorphism-styled search bar for messages.
class MessageSearchBar extends StatefulWidget {
  const MessageSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search messages...',
    this.autofocus = false,
  });

  /// Called when search text changes.
  final void Function(String query) onSearch;

  /// Called when search is cleared.
  final VoidCallback? onClear;

  /// Placeholder text.
  final String hintText;

  /// Whether to autofocus the search field.
  final bool autofocus;

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onSearch(_controller.text);
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: DsGlassColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(color: DsGlassColors.borderFor(context)),
          ),
          child: Row(
            children: [
              const SizedBox(width: DsSpacing.md),
              Icon(
                Icons.search,
                size: 20,
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  style: TextStyle(
                    color: isDark
                        ? DsColors.textPrimaryDark
                        : DsColors.textPrimaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (_hasText)
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: _clear,
                    child: Padding(
                      padding: const EdgeInsets.all(DsSpacing.sm),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: DsSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// A search result item for messages.
class MessageSearchResult extends StatelessWidget {
  const MessageSearchResult({
    super.key,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.query,
    this.avatarUrl,
    this.onTap,
  });

  final String senderName;
  final String message;
  final DateTime timestamp;
  final String query;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: DsGlassColors.borderFor(context),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: DsGlassColors.surfaceFor(
                  context,
                  strength: DsGlassSurfaceStrength.medium,
                ),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null
                    ? Icon(
                        Icons.person,
                        color: isDark ? Colors.white54 : Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: DsSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name and time
                    Row(
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DsColors.textPrimaryDark
                                : DsColors.textPrimaryLight,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateTimeFormatter.formatSearchResultTime(
                            timestamp,
                            l10n: context.l10n,
                            locale: Localizations.localeOf(context).toString(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Highlighted message
                    _HighlightedText(
                      text: message,
                      query: query,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                      highlightStyle: TextStyle(
                        fontSize: 14,
                        color: DsColors.primary,
                        fontWeight: FontWeight.w600,
                        backgroundColor: DsColors.primary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
  });

  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A full message search screen/overlay.
class MessageSearchOverlay extends StatefulWidget {
  const MessageSearchOverlay({
    super.key,
    required this.messages,
    required this.onMessageTap,
    this.onClose,
  });

  /// List of searchable messages.
  final List<SearchableMessage> messages;

  /// Called when a message result is tapped.
  final void Function(SearchableMessage message) onMessageTap;

  /// Called when the overlay is closed.
  final VoidCallback? onClose;

  @override
  State<MessageSearchOverlay> createState() => _MessageSearchOverlayState();
}

class _MessageSearchOverlayState extends State<MessageSearchOverlay> {
  String _query = '';
  List<SearchableMessage> _results = [];

  void _onSearch(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _results = [];
      } else {
        _results = widget.messages
            .where(
              (m) =>
                  m.content.toLowerCase().contains(query.toLowerCase()) ||
                  m.senderName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: MessageSearchBar(
                      onSearch: _onSearch,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: _query.isEmpty
                  ? _EmptySearchState()
                  : _results.isEmpty
                  ? _NoResultsState(query: _query)
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final message = _results[index];
                        return MessageSearchResult(
                          senderName: message.senderName,
                          message: message.content,
                          timestamp: message.timestamp,
                          query: _query,
                          avatarUrl: message.avatarUrl,
                          onTap: () => widget.onMessageTap(message),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
          const SizedBox(height: DsSpacing.md),
          Text(
            'Search your messages',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
          const SizedBox(height: DsSpacing.md),
          Text(
            'No results for "$query"',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// A searchable message model.
class SearchableMessage {
  final String id;
  final String chatId;
  final String senderName;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? avatarUrl;

  const SearchableMessage({
    required this.id,
    required this.chatId,
    required this.senderName,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.avatarUrl,
  });
}
