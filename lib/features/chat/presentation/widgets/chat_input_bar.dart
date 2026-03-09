import 'dart:async';
import 'dart:ui';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/services/haptic_service.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/widgets/voice_note_recorder.dart';
import 'package:crushhour/shared/dto/message.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputBar extends StatefulWidget {
  final ChatState state;
  final bool isBlocked;
  final bool canMessage;
  final bool isUnmatched;
  final ProfileCompletenessSummary completeness;
  final String currentUserId;
  final String otherUserId;
  final String otherName;
  final String matchId;
  final Future<bool> Function(ProfileCompletenessSummary)
  onEnsureMessagingAllowed;
  final void Function(ProfileCompletenessSummary) onShowMessagingIncomplete;

  const ChatInputBar({
    super.key,
    required this.state,
    required this.isBlocked,
    required this.canMessage,
    required this.isUnmatched,
    required this.completeness,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
    required this.matchId,
    required this.onEnsureMessagingAllowed,
    required this.onShowMessagingIncomplete,
  });

  @override
  State<ChatInputBar> createState() => ChatInputBarState();
}

class ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _picker = ImagePicker();

  bool _hasInputText = false;
  bool _isRecordingVoice = false;
  bool _isPickingMedia = false;
  Timer? _typingDebounceTimer;
  bool _isTypingSent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _inputFocusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_hasInputText != hasText) {
      setState(() => _hasInputText = hasText);
    }

    // Cancel the existing timer
    _typingDebounceTimer?.cancel();

    if (hasText) {
      if (!_isTypingSent) {
        // Only send typing=true if we haven't already
        _isTypingSent = true;
        context.read<ChatBloc>().add(
          ChatTypingStatusChanged(
            isTyping: true,
            matchId: widget.matchId,
            userId: widget.currentUserId,
          ),
        );
      }

      // Debounce: wait 2.5 seconds after last keystroke to send typing=false
      _typingDebounceTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _isTypingSent = false;
          context.read<ChatBloc>().add(
            ChatTypingStatusChanged(
              isTyping: false,
              matchId: widget.matchId,
              userId: widget.currentUserId,
            ),
          );
        }
      });
    } else {
      // If the field is cleared immediately, tell the backend and clear the flag
      if (_isTypingSent) {
        _isTypingSent = false;
        context.read<ChatBloc>().add(
          ChatTypingStatusChanged(
            isTyping: false,
            matchId: widget.matchId,
            userId: widget.currentUserId,
          ),
        );
      }
    }
  }

  void insertText(String text) {
    _controller.text = text;
    _onTextChanged();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
        if (!isShiftPressed) {
          _sendMessage();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _sendMessage() async {
    if (widget.isBlocked) {
      showErrorSnackBar(
        context,
        'Unblock ${widget.otherName} to send messages.',
      );
      return;
    }
    if (widget.isUnmatched) {
      showErrorSnackBar(
        context,
        'You unmatched with ${widget.otherName}. Messaging is disabled.',
      );
      return;
    }
    if (!widget.canMessage) {
      widget.onShowMessagingIncomplete(widget.completeness);
      return;
    }
    final allowed = await widget.onEnsureMessagingAllowed(widget.completeness);
    if (!allowed || !mounted) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticService.messageSent();
    context.read<ChatBloc>().add(
      ChatMessageSent(
        matchId: widget.matchId,
        fromUserId: widget.currentUserId,
        toUserId: widget.otherUserId,
        content: text,
        type: MessageType.text,
      ),
    );

    // Immediately clear typing state when message is sent
    _typingDebounceTimer?.cancel();
    _isTypingSent = false;

    _controller.clear();
    _onTextChanged();
  }

  void _showMediaPickerOptions(
    bool canMessage,
    ProfileCompletenessSummary completeness,
    bool isDark,
  ) {
    final titleColor = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;
    final iconColor = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DsSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_rounded, color: iconColor),
                title: Text('Photo', style: TextStyle(color: titleColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(canMessage, completeness);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam_rounded, color: iconColor),
                title: Text('Video', style: TextStyle(color: titleColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendVideo(canMessage, completeness);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      widget.onShowMessagingIncomplete(completeness);
      return;
    }
    // Prevent concurrent image picker operations
    if (_isPickingMedia) return;
    final allowed = await widget.onEnsureMessagingAllowed(completeness);
    if (!allowed || !mounted) return;

    _isPickingMedia = true;
    try {
      final result = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted || result == null) return;
      HapticService.messageSent();
      context.read<ChatBloc>().add(
        ChatMediaSendRequested(
          matchId: widget.matchId,
          fromUserId: widget.currentUserId,
          toUserId: widget.otherUserId,
          filePath: result.path,
          type: MessageType.image,
        ),
      );
    } on PlatformException catch (e) {
      AppLogger.error('Image picker error: ${e.code} - ${e.message}');
    } finally {
      if (mounted) {
        _isPickingMedia = false;
      }
    }
  }

  Future<void> _pickAndSendVideo(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      widget.onShowMessagingIncomplete(completeness);
      return;
    }
    // Prevent concurrent image picker operations
    if (_isPickingMedia) return;
    final allowed = await widget.onEnsureMessagingAllowed(completeness);
    if (!allowed || !mounted) return;

    _isPickingMedia = true;
    try {
      final result = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );
      if (!mounted || result == null) return;
      HapticService.messageSent();
      context.read<ChatBloc>().add(
        ChatMediaSendRequested(
          matchId: widget.matchId,
          fromUserId: widget.currentUserId,
          toUserId: widget.otherUserId,
          filePath: result.path,
          type: MessageType.video,
        ),
      );
    } on PlatformException catch (e) {
      AppLogger.error('Video picker error: ${e.code} - ${e.message}');
    } finally {
      if (mounted) {
        _isPickingMedia = false;
      }
    }
  }

  Future<void> _startVoiceRecording(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      widget.onShowMessagingIncomplete(completeness);
      return;
    }
    final allowed = await widget.onEnsureMessagingAllowed(completeness);
    if (!allowed || !mounted) return;

    setState(() => _isRecordingVoice = true);
  }

  void _sendVoiceNote(String filePath) {
    HapticService.messageSent();
    context.read<ChatBloc>().add(
      ChatMediaSendRequested(
        matchId: widget.matchId,
        fromUserId: widget.currentUserId,
        toUserId: widget.otherUserId,
        filePath: filePath,
        type: MessageType.voice,
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool isDark,
    bool isActive = false,
  }) {
    final isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DsRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.xs,
              vertical: DsSpacing.xs,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isEnabled
                  ? (isActive
                        ? DsColors.primary
                        : isDark
                        ? DsColors.surfaceLight.withValues(alpha: 0.7)
                        : DsColors.ink900.withValues(alpha: 0.54))
                  : isDark
                  ? DsColors.surfaceLight.withValues(alpha: 0.2)
                  : DsColors.ink900.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSendingText = widget.state.sendStatus == SendStatus.sendingText;
    final isUploading =
        widget.state.sendStatus == SendStatus.uploadingAttachment;
    final canSendText =
        !widget.isBlocked &&
        !widget.isUnmatched &&
        widget.canMessage &&
        !isSendingText &&
        !isUploading;
    final canSendMedia =
        widget.state.mediaSendingEnabled &&
        !widget.isBlocked &&
        !widget.isUnmatched &&
        widget.canMessage &&
        !isUploading;

    if (_isRecordingVoice) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.xs,
          ),
          child: VoiceNoteRecorder(
            onRecordingComplete: (filePath) {
              setState(() => _isRecordingVoice = false);
              _sendVoiceNote(filePath);
            },
            onCancel: () {
              setState(() => _isRecordingVoice = false);
            },
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);
    final motionScale =
        Theme.of(context).extension<CrushThemeEffects>()?.motionScale ?? 1.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                baseSurface.withValues(alpha: 0.85),
                baseSurface.withValues(alpha: 0.7),
              ],
            ),
            border: Border(top: BorderSide(color: borderBase, width: 0.5)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.sm,
                vertical: DsSpacing.sm,
              ),
              child: Row(
                children: [
                  AnimatedSize(
                    duration: Duration(
                      milliseconds: (200 * motionScale).round(),
                    ),
                    curve: Curves.easeInOut,
                    child: _hasInputText
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                                colors: isDark
                                    ? [
                                        DsColors.surfaceLight.withValues(
                                          alpha: 0.08,
                                        ),
                                        DsColors.surfaceLight.withValues(
                                          alpha: 0.04,
                                        ),
                                      ]
                                    : [
                                        DsColors.ink900.withValues(alpha: 0.04),
                                        DsColors.ink900.withValues(alpha: 0.02),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(DsRadius.xl),
                              border: Border.all(
                                color: borderBase.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMediaButton(
                                  icon: Icons.photo_library_rounded,
                                  tooltip: 'Send photo or video',
                                  onPressed: canSendMedia
                                      ? () => _showMediaPickerOptions(
                                          widget.canMessage,
                                          widget.completeness,
                                          isDark,
                                        )
                                      : null,
                                  isDark: isDark,
                                ),
                                _buildMediaButton(
                                  icon: Icons.mic_rounded,
                                  tooltip: 'Voice note',
                                  onPressed: canSendMedia
                                      ? () => _startVoiceRecording(
                                          widget.canMessage,
                                          widget.completeness,
                                        )
                                      : null,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                  ),
                  AnimatedSize(
                    duration: Duration(
                      milliseconds: (200 * motionScale).round(),
                    ),
                    curve: Curves.easeInOut,
                    child: _hasInputText
                        ? const SizedBox.shrink()
                        : const SizedBox(width: DsSpacing.sm),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: isDark
                              ? [
                                  DsColors.surfaceLight.withValues(alpha: 0.1),
                                  DsColors.surfaceLight.withValues(alpha: 0.05),
                                ]
                              : [
                                  DsColors.ink900.withValues(alpha: 0.05),
                                  DsColors.ink900.withValues(alpha: 0.02),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(DsRadius.xl),
                        border: Border.all(color: borderBase, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: DsColors.ink900.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Semantics(
                        textField: true,
                        label: 'Type a message to ${widget.otherName}',
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocusNode,
                          enabled: canSendText,
                          minLines: 1,
                          maxLines: 2,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(
                            color: isDark
                                ? DsColors.surfaceLight
                                : DsColors.ink900.withValues(alpha: 0.87),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.38,
                                    )
                                  : DsColors.ink900.withValues(alpha: 0.38),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Semantics(
                    button: true,
                    label: 'Send message',
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [DsColors.primary, DsColors.secondary],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DsColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: DsColors.secondary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: isSendingText
                            ? const SizedBox(
                                width: DsSizes.iconMd,
                                height: DsSizes.iconMd,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    DsColors.surfaceLight,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: DsColors.surfaceLight,
                              ),
                        onPressed: isSendingText ? null : () => _sendMessage(),
                      ),
                    ),
                  ),
                  DsGap.xsH,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
