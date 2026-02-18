import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/design_system/widgets/glass_skeleton.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';
import 'package:crushhour/presentation/widgets/plus_feature_gate.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';
import 'package:crushhour/features/chat/domain/services/ice_breaker_service.dart';
import 'package:crushhour/features/chat/presentation/bloc/match_chat_settings_cubit.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/core/services/haptic_service.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';

class ChatScreenArgs {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final String otherName;
  final String? otherPhotoUrl;
  ChatScreenArgs({
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
  });
}

class ChatScreen extends StatefulWidget {
  final ChatScreenArgs args;
  const ChatScreen({super.key, required this.args});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isRecordingVoice = false;
  bool _isPickingMedia = false; // Prevent concurrent image picker operations
  bool _hasInputText =
      false; // Track if input has text to show/hide media buttons
  List<IceBreakerSuggestion> _iceBreakerSuggestions = [];
  RemoteProfileCompleteness? _backendCompleteness;
  bool _checkingCompleteness = false;
  String? _completenessError;
  String? _lastProfileSignature;
  bool _backendBlocked = false;
  final ProfileValidationService _validationService =
      ProfileValidationService();

  // Store reference to ChatBloc to safely use in dispose()
  ChatBloc? _chatBloc;

  // ID verification banner state
  bool _showVerificationBanner = false;
  Timer? _verificationBannerTimer;
  static const String _verificationBannerCooldownKey =
      'last_verification_banner_shown';
  static const Duration _verificationBannerCooldown = Duration(hours: 3);
  static const Duration _verificationBannerDuration = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _refreshIceBreakers();
    _checkVerificationBannerVisibility();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatBloc = context.read<ChatBloc>();
        _chatBloc?.add(ChatOpened(
          widget.args.matchId,
          widget.args.currentUserId,
          widget.args.otherUserId,
          otherUserPhotoUrl: widget.args.otherPhotoUrl,
        ));
      }
    });
  }

  /// Detect when user scrolls near the top (end of reversed list) to load more messages
  void _onScroll() {
    if (!mounted) return;
    final state = _chatBloc?.state;
    if (state == null) return;

    // In a reversed ListView, the "top" (oldest messages) is at maxScrollExtent
    // Check if we're within 200px of the top to trigger load more
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        state.hasMoreMessages &&
        !state.isLoadingMore) {
      _chatBloc?.add(ChatLoadMoreMessagesRequested(widget.args.matchId));
    }
  }

  /// Check if the verification banner should be shown based on 3-hour cooldown
  Future<void> _checkVerificationBannerVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_verificationBannerCooldownKey) ?? 0;
    final lastShownTime = DateTime.fromMillisecondsSinceEpoch(lastShown);
    final now = DateTime.now();

    // Show banner if cooldown has passed (3 hours since last shown)
    if (now.difference(lastShownTime) >= _verificationBannerCooldown) {
      if (mounted) {
        setState(() {
          _showVerificationBanner = true;
        });
        _startVerificationBannerTimer();
        // Save current time as last shown
        await prefs.setInt(
            _verificationBannerCooldownKey, now.millisecondsSinceEpoch);
      }
    }
  }

  /// Start 10-second auto-dismiss timer for verification banner
  void _startVerificationBannerTimer() {
    _verificationBannerTimer?.cancel();
    _verificationBannerTimer = Timer(_verificationBannerDuration, () {
      if (mounted) {
        setState(() {
          _showVerificationBanner = false;
        });
      }
    });
  }

  /// Dismiss verification banner manually (e.g., when user taps Verify)
  void _dismissVerificationBanner() {
    _verificationBannerTimer?.cancel();
    setState(() {
      _showVerificationBanner = false;
    });
  }

  void _refreshIceBreakers() {
    setState(() {
      _iceBreakerSuggestions = IceBreakerService.getSuggestions(maxCount: 4);
    });
  }

  void _onIceBreakerTap(String text) {
    _controller.text = text;
  }

  @override
  void dispose() {
    // Use stored reference instead of context.read() which is unsafe in dispose
    _chatBloc?.add(
      ChatClosed(widget.args.matchId, widget.args.currentUserId),
    );
    _typingTimer?.cancel();
    _verificationBannerTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.select<ProfileBloc, Profile?>(
      (bloc) => bloc.state.profile ?? bloc.state.user?.profile,
    );
    final completeness = evaluateProfileCompleteness(userProfile);
    _maybeRefreshBackendCompleteness(userProfile);
    final backendMessageAllowed = _backendCompleteness?.allowsMessaging ??
        (_backendBlocked ? false : _completenessError != null);

    return BlocBuilder<SafetyCubit, SafetyState>(
      builder: (context, safetyState) {
        final safety = context.read<SafetyCubit>();
        final isBlocked =
            safetyState.blockedUsers.contains(widget.args.otherUserId);
        final messagesMuted =
            safetyState.mutedMessages.contains(widget.args.otherUserId);
        final callsMuted =
            safetyState.mutedCalls.contains(widget.args.otherUserId);
        final selfVerified = userProfile?.isVerified ?? false;

        return BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (prev, curr) =>
              prev.allMessages.length != curr.allMessages.length ||
              prev.isInitialLoading != curr.isInitialLoading ||
              prev.isUnmatched != curr.isUnmatched ||
              prev.typingUserIds != curr.typingUserIds ||
              prev.otherUserOnline != curr.otherUserOnline ||
              prev.otherUserPhotoUrl != curr.otherUserPhotoUrl,
          builder: (context, state) {
            final messages = state.allMessages;
            final showSkeleton = state.isInitialLoading && messages.isEmpty;
            final canMessage = completeness.meetsMessagingMinimum &&
                completeness.meetsRequiredFields &&
                backendMessageAllowed &&
                !isBlocked &&
                !state.isUnmatched;
            final isOtherTyping =
                state.typingUserIds.contains(widget.args.otherUserId);

            return AsyncStateScaffold(
              appBar: _buildGlassAppBar(
                context,
                state: state,
                isBlocked: isBlocked,
                messagesMuted: messagesMuted,
                callsMuted: callsMuted,
                safety: safety,
              ),
              errorMessage: state.errorMessage,
              showErrorSnackBar: true,
              showBodyOnLoading: true,
              body: Column(
                children: [
                  // ID Verification banner - shown only when:
                  // 1. User is NOT verified
                  // 2. Banner cooldown has passed (3 hours)
                  // 3. Auto-dismisses after 10 seconds
                  if (!selfVerified && _showVerificationBanner)
                    Container(
                      width: double.infinity,
                      color: DsColors.warning.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.privacy_tip_outlined,
                            color: DsColors.warning,
                          ),
                          DsGap.smH,
                          const Expanded(
                            child: Text(
                              'Verify your ID to add a trust badge to your messages and matches.',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _dismissVerificationBanner();
                              context.push(CrushRoutes.idVerification);
                            },
                            child: const Text('Verify'),
                          ),
                        ],
                      ),
                    ),
                  if (_checkingCompleteness)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'Checking your profile completeness with the server…',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: DsColors.ink300),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_completenessError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        _completenessError!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: DsColors.warning),
                      ),
                    ),
                  if (_isNetworkError(state.errorMessage))
                    Container(
                      width: double.infinity,
                      color: DsColors.error.withValues(alpha: 0.08),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: DsColors.error),
                          DsGap.smH,
                          const Expanded(
                            child: Text(
                              'Internet connection error. Messages may not send.',
                              style: TextStyle(color: DsColors.error),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _refreshChat(context),
                            icon: const Icon(Icons.refresh,
                                color: DsColors.error),
                            label: const Text(
                              'Refresh',
                              style: TextStyle(color: DsColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (state.isUnmatched)
                    Container(
                      width: double.infinity,
                      color: DsColors.ink400.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.heart_broken,
                            color: DsColors.surfaceLight.withValues(alpha: 0.7),
                          ),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'You unmatched with ${widget.args.otherName}. You can still browse history, but messaging is disabled.',
                              style: TextStyle(
                                color: DsColors.surfaceLight
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isBlocked)
                    Container(
                      width: double.infinity,
                      color: DsColors.error.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: DsColors.error),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'You blocked ${widget.args.otherName}. Unblock to chat or call.',
                              style: const TextStyle(color: DsColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleBlock(
                              context,
                              safety,
                              block: false,
                            ),
                            child: const Text('Unblock'),
                          ),
                        ],
                      ),
                    )
                  else if (!canMessage)
                    Container(
                      width: double.infinity,
                      color: DsColors.warning.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: DsColors.warning),
                          DsGap.smH,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Complete your profile to continue messaging.',
                                  style: TextStyle(color: DsColors.warning),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: _backendCompleteness?.score ??
                                      completeness.score,
                                  minHeight: 5,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Missing: ${_missingMessages(completeness).take(2).join(', ')}',
                                  style:
                                      const TextStyle(color: DsColors.warning),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _goToProfileEdit(context),
                            child: const Text('Finish'),
                          ),
                        ],
                      ),
                    )
                  else if (messagesMuted || callsMuted)
                    Container(
                      width: double.infinity,
                      color: DsColors.warning.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_off, color: DsColors.warning),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              _muteSummary(
                                messagesMuted: messagesMuted,
                                callsMuted: callsMuted,
                                name: widget.args.otherName,
                              ),
                              style: const TextStyle(color: DsColors.warning),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (messagesMuted) {
                                safety.toggleMuteMessages(
                                  widget.args.otherUserId,
                                  mute: false,
                                );
                              }
                              if (callsMuted) {
                                safety.toggleMuteCalls(
                                  widget.args.otherUserId,
                                  mute: false,
                                );
                              }
                            },
                            child: const Text('Unmute'),
                          ),
                        ],
                      ),
                    ),
                  if (!state.mediaSendingEnabled && !state.isUnmatched)
                    Container(
                      width: double.infinity,
                      color: DsColors.ink400.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.no_photography,
                            color: DsColors.surfaceLight.withValues(alpha: 0.7),
                          ),
                          DsGap.smH,
                          const Expanded(
                            child: Text(
                              'Media sending is disabled for this match. Enable it from the toolbar to share photos, videos, or audio.',
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleMedia(state),
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: showSkeleton
                        ? _buildMessageSkeletonList()
                        : messages.isEmpty
                            ? ChatEmptyState(
                                onRefresh: _refreshIceBreakers,
                                suggestions: _iceBreakerSuggestions,
                                onSuggestionTap: _onIceBreakerTap,
                                otherName: widget.args.otherName,
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(12),
                                // Add extra item for loading indicator when loading more
                                itemCount: messages.length +
                                    (state.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Show loading indicator at the end (top of reversed list)
                                  if (state.isLoadingMore &&
                                      index == messages.length) {
                                    return const _LoadMoreIndicator();
                                  }
                                  final msg =
                                      messages[messages.length - 1 - index];
                                  final isMe = msg.fromUserId ==
                                      widget.args.currentUserId;
                                  final isHeld =
                                      msg.moderationAction == 'hold' ||
                                          msg.moderationStatus == 'held';
                                  final pendingScan =
                                      msg.moderationStatus == 'pending_scan';
                                  final isFlagged = msg.isFlagged || isHeld;
                                  final text = msg.isDeletedForSender && isMe
                                      ? '(You unsent this message)'
                                      : isHeld
                                          ? 'Message held for safety review'
                                          : msg.content;
                                  final reactionCounts = _reactionCounts(msg);
                                  final alignment = isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft;

                                  // Check if we need a date separator
                                  final showDateSeparator =
                                      _shouldShowDateSeparator(
                                    messages,
                                    messages.length - 1 - index,
                                  );

                                  return Column(
                                    children: [
                                      // Date separator (shown above the message in reversed list)
                                      if (showDateSeparator)
                                        ChatDateSeparator(date: msg.sentAt),
                                      Align(
                                        alignment: alignment,
                                        child: GestureDetector(
                                          onLongPress: () =>
                                              _showMessageActions(
                                            context: context,
                                            state: state,
                                            message: msg,
                                            isMe: isMe,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: DsBlur.subtle,
                                                    sigmaY: DsBlur.subtle,
                                                  ),
                                                  child: Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        vertical: DsSpacing.xs,
                                                        horizontal:
                                                            DsSpacing.sm),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            DsSpacing.sm + 2),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: isMe
                                                            ? [
                                                                DsColors.primary
                                                                    .withValues(
                                                                        alpha:
                                                                            0.85),
                                                                DsColors
                                                                    .secondary
                                                                    .withValues(
                                                                        alpha:
                                                                            0.7),
                                                              ]
                                                            : [
                                                                DsGlassColors
                                                                        .surfaceFor(
                                                                            context)
                                                                    .withValues(
                                                                        alpha:
                                                                            0.6),
                                                                DsGlassColors
                                                                        .surfaceFor(
                                                                            context)
                                                                    .withValues(
                                                                        alpha:
                                                                            0.4),
                                                              ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18),
                                                      border: Border.all(
                                                        color: isMe
                                                            ? DsColors.primary
                                                                .withValues(
                                                                    alpha: 0.3)
                                                            : DsGlassColors
                                                                .borderFor(
                                                                    context),
                                                        width: 1,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (isMe
                                                                  ? DsColors
                                                                      .primary
                                                                  : DsColors
                                                                      .ink900)
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: _buildMessageContent(
                                                      msg,
                                                      text,
                                                      isHeld: isHeld,
                                                      pendingScan: pendingScan,
                                                      isMe: isMe,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Message status indicators
                                              if (isMe) ...[
                                                if (msg.sendStatus ==
                                                    MessageSendStatus.sending)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 12,
                                                      bottom: 2,
                                                      top: 2,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                          width: 10,
                                                          height: 10,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            valueColor:
                                                                AlwaysStoppedAnimation(
                                                              DsColors
                                                                  .surfaceLight
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Sending...',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: DsColors
                                                                .surfaceLight
                                                                .withValues(
                                                                    alpha: 0.5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else if (msg.sendStatus ==
                                                    MessageSendStatus.sent)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 12,
                                                      bottom: 2,
                                                      top: 2,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _formatTime(
                                                              msg.sentAt),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: DsColors
                                                                .surfaceLight
                                                                .withValues(
                                                                    alpha: 0.5),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        // Read status - only show "Seen" for Plus users
                                                        if (state
                                                                .canSeeReadReceipts &&
                                                            msg.isRead) ...[
                                                          const Icon(
                                                            Icons.done_all,
                                                            size: 14,
                                                            color:
                                                                DsColors.info,
                                                          ),
                                                          const SizedBox(
                                                              width: 2),
                                                          const Text(
                                                            'Seen',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  DsColors.info,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ] else ...[
                                                          // Non-Plus users just see single checkmark
                                                          Icon(
                                                            Icons.done,
                                                            size: 14,
                                                            color: DsColors
                                                                .surfaceLight
                                                                .withValues(
                                                                    alpha: 0.5),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                              if (isFlagged || pendingScan)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 12,
                                                    right: 12,
                                                    bottom: 2,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isHeld
                                                            ? Icons.shield
                                                            : Icons
                                                                .shield_outlined,
                                                        size: 14,
                                                        color: isHeld
                                                            ? DsColors.error
                                                            : DsColors.warning,
                                                      ),
                                                      DsGap.xsH,
                                                      Flexible(
                                                        child: Text(
                                                          _moderationLabel(
                                                            msg,
                                                            isHeld: isHeld,
                                                            pendingScan:
                                                                pendingScan,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: isHeld
                                                                ? DsColors.error
                                                                : DsColors
                                                                    .warning,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (reactionCounts.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 12,
                                                    right: 12,
                                                    bottom: 2,
                                                  ),
                                                  child: Wrap(
                                                    spacing: 6,
                                                    children: reactionCounts
                                                        .entries
                                                        .map(
                                                          (entry) => Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: DsColors
                                                                  .ink900
                                                                  .withValues(
                                                                      alpha:
                                                                          0.54),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              entry.value > 1
                                                                  ? '${entry.key} ${entry.value}'
                                                                  : entry.key,
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                  ),
                                                ),
                                              // Retry button for failed messages
                                              if (isMe &&
                                                  msg.sendStatus ==
                                                      MessageSendStatus.failed)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 12,
                                                    right: 12,
                                                    bottom: 4,
                                                    top: 2,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.error_outline,
                                                        size: 14,
                                                        color: DsColors.error,
                                                      ),
                                                      DsGap.xsH,
                                                      const Text(
                                                        'Failed to send',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: DsColors.error,
                                                        ),
                                                      ),
                                                      DsGap.smH,
                                                      GestureDetector(
                                                        onTap: () {
                                                          context
                                                              .read<ChatBloc>()
                                                              .add(
                                                                ChatMessageRetryRequested(
                                                                  matchId: widget
                                                                      .args
                                                                      .matchId,
                                                                  messageId:
                                                                      msg.id,
                                                                ),
                                                              );
                                                        },
                                                        child: const Text(
                                                          'Retry',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                DsColors.info,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              // Sending indicator
                                              if (isMe &&
                                                  msg.sendStatus ==
                                                      MessageSendStatus.sending)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 12,
                                                    right: 12,
                                                    bottom: 4,
                                                    top: 2,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 12,
                                                        height: 12,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 1.5,
                                                          valueColor:
                                                              AlwaysStoppedAnimation(
                                                                  DsColors
                                                                      .ink300),
                                                        ),
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Sending...',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              DsColors.ink300,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),
                  if (state.isUnsendInProgress)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (state.isUnmatching)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ChatSendStatusBar(state: state),
                  if (isOtherTyping)
                    ChatTypingIndicator(name: widget.args.otherName),
                  _buildInput(
                    state,
                    isBlocked: isBlocked,
                    canMessage: canMessage,
                    isUnmatched: state.isUnmatched,
                    completeness: completeness,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildGlassAppBar(
    BuildContext context, {
    required ChatState state,
    required bool isBlocked,
    required bool messagesMuted,
    required bool callsMuted,
    required SafetyCubit safety,
  }) {
    final baseSurface = DsGlassColors.surfaceFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 8),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsBlur.heavy,
            sigmaY: DsBlur.heavy,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseSurface.withValues(alpha: 0.85),
                  baseSurface.withValues(alpha: 0.7),
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
                height: kToolbarHeight + 8,
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // User avatar with online indicator - tappable to view profile
                    Semantics(
                      button: true,
                      label: 'View ${widget.args.otherName} profile',
                      child: GestureDetector(
                      onTap: _navigateToProfile,
                      child: Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: state.otherUserOnline
                                    ? DsColors.onlineIndicator
                                    : DsGlassColors.borderFor(context),
                                width: 2,
                              ),
                              boxShadow: state.otherUserOnline
                                  ? [
                                      BoxShadow(
                                        color: DsColors.onlineIndicator
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipOval(
                              child: state.otherUserPhotoUrl != null
                                  ? CachedImage(
                                      imageUrl: state.otherUserPhotoUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: DsGlassColors.surfaceFor(context),
                                      child: Icon(
                                        Icons.person,
                                        size: 20,
                                        color: isDark
                                            ? DsColors.surfaceLight
                                                .withValues(alpha: 0.54)
                                            : DsColors.ink900
                                                .withValues(alpha: 0.38),
                                      ),
                                    ),
                            ),
                          ),
                          if (state.otherUserOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: DsColors.onlineIndicator,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? DsColors.ink900
                                        : DsColors.surfaceLight,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DsColors.onlineIndicator
                                          .withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    // User info - tappable to view profile
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'View ${widget.args.otherName} profile',
                        child: GestureDetector(
                        onTap: _navigateToProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.args.otherName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    state.otherUserOnline
                                        ? 'Online now'
                                        : 'Offline',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: state.otherUserOnline
                                              ? DsColors.onlineIndicator
                                              : DsColors.textMutedLight,
                                          fontWeight: state.otherUserOnline
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Mute indicators
                            if (messagesMuted || callsMuted) ...[
                              const SizedBox(width: 4),
                              if (messagesMuted)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: DsColors.warning
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_off,
                                    size: 14,
                                    color: DsColors.warning,
                                  ),
                                ),
                              if (messagesMuted && callsMuted)
                                const SizedBox(width: 4),
                              if (callsMuted)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: DsColors.warning
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.call_end,
                                    size: 14,
                                    color: DsColors.warning,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      ),
                    ),
                    // Action buttons
                    GlassIconButton(
                      icon: Icons.call,
                      onPressed: (isBlocked || state.isUnmatched)
                          ? () {}
                          : _startAudioCall,
                      size: 38,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.videocam,
                      onPressed: (isBlocked || state.isUnmatched)
                          ? () {}
                          : () {
                              context.push(
                                CrushRoutes.videoCall,
                                extra: VideoCallArgs(
                                  currentUserId: widget.args.currentUserId,
                                  otherUserId: widget.args.otherUserId,
                                  otherName: widget.args.otherName,
                                ),
                              );
                            },
                      size: 38,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.lightbulb_outline,
                      onPressed: () => context.push(
                        CrushRoutes.dateIdeas,
                        extra: {'matchId': widget.args.matchId},
                      ),
                      size: 38,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    GlassIconButton(
                      icon: Icons.quiz_outlined,
                      onPressed: () => context.push(
                        CrushRoutes.compatibilityQuiz,
                        extra: {'matchId': widget.args.matchId},
                      ),
                      size: 38,
                    ),
                    PopupMenuButton<_ChatSafetyAction>(
                      onSelected: (action) => _handleSafetyAction(
                        context,
                        safety,
                        isBlocked: isBlocked,
                        messagesMuted: messagesMuted,
                        callsMuted: callsMuted,
                        action: action,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _ChatSafetyAction.viewProfile,
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 20),
                              SizedBox(width: 12),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: _ChatSafetyAction.chatSettings,
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Chat Settings'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: _ChatSafetyAction.report,
                          child: Text('Report user'),
                        ),
                        PopupMenuItem(
                          value: _ChatSafetyAction.block,
                          child:
                              Text(isBlocked ? 'Unblock user' : 'Block user'),
                        ),
                        const PopupMenuItem(
                          value: _ChatSafetyAction.unmatch,
                          child: Text('Unmatch'),
                        ),
                        PopupMenuItem(
                          value: _ChatSafetyAction.muteMessages,
                          child: Text(messagesMuted
                              ? 'Unmute messages'
                              : 'Mute messages'),
                        ),
                        PopupMenuItem(
                          value: _ChatSafetyAction.muteCalls,
                          child:
                              Text(callsMuted ? 'Unmute calls' : 'Mute calls'),
                        ),
                        const PopupMenuItem(
                          value: _ChatSafetyAction.safetyCenter,
                          child: Text('Open Safety Center'),
                        ),
                      ],
                    ),
                    const SizedBox(width: DsSpacing.xs),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActions({
    required BuildContext context,
    required ChatState state,
    required Message message,
    required bool isMe,
  }) {
    const reactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    final myReaction = message.reactions[widget.args.currentUserId];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
          child: Container(
            decoration: BoxDecoration(
              color: baseSurface.withValues(alpha: isDark ? 0.9 : 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: borderBase,
                width: 0.5,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? DsColors.surfaceLight.withValues(alpha: 0.24)
                            : DsColors.ink900.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Reaction picker with animation
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? DsColors.surfaceLight.withValues(alpha: 0.05)
                          : DsColors.ink900.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: reactions.map((emoji) {
                        final isSelected = myReaction == emoji;
                        return ChatReactionButton(
                          emoji: emoji,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            _toggleReaction(message, emoji);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  if (myReaction != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          _toggleReaction(message, myReaction);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Remove my reaction'),
                        style: TextButton.styleFrom(
                          foregroundColor: DsColors.textMutedLight,
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  if (isMe) ...[
                    // Edit option - only for text messages
                    if (message.type == MessageType.text)
                      PlusFeatureGate(
                        onAllowed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          _showEditMessageDialog(message);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit (Plus)'),
                          enabled: !state.isEditInProgress,
                        ),
                      ),
                    PlusFeatureGate(
                      onAllowed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        context.read<ChatBloc>().add(
                              ChatMessageUnsendRequested(
                                widget.args.matchId,
                                message.id,
                              ),
                            );
                      },
                      child: ListTile(
                        leading: const Icon(Icons.undo),
                        title: const Text('Unsend (Plus)'),
                        enabled: !state.isUnsendInProgress,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Delete for me'),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        context.read<ChatBloc>().add(
                              ChatMessageDeleteForMeRequested(
                                widget.args.matchId,
                                message.id,
                                widget.args.currentUserId,
                              ),
                            );
                      },
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy text'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      Clipboard.setData(
                        ClipboardData(text: message.content),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied'),
                        ),
                      );
                    },
                  ),
                  DsGap.sm,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _refreshChat(BuildContext context) {
    context.read<ChatBloc>().add(
          ChatOpened(
            widget.args.matchId,
            widget.args.currentUserId,
            widget.args.otherUserId,
          ),
        );
  }

  void _showEditMessageDialog(Message message) {
    final controller = TextEditingController(text: message.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: baseSurface.withValues(alpha: isDark ? 0.95 : 0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Enter new message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DsRadius.md),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DsRadius.md),
              borderSide: const BorderSide(color: DsColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                context.read<ChatBloc>().add(
                      ChatMessageEditRequested(
                        matchId: widget.args.matchId,
                        messageId: message.id,
                        newContent: newContent,
                      ),
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isNetworkError(String? message) {
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('internet connection') ||
        lower.contains('network') ||
        lower.contains('wifi');
  }

  void _toggleReaction(Message message, String emoji) {
    final existing = message.reactions[widget.args.currentUserId];
    final bloc = context.read<ChatBloc>();
    if (existing == emoji) {
      bloc.add(ChatReactionRemoved(
        matchId: widget.args.matchId,
        messageId: message.id,
        userId: widget.args.currentUserId,
      ));
    } else {
      bloc.add(ChatReactionAdded(
        matchId: widget.args.matchId,
        messageId: message.id,
        userId: widget.args.currentUserId,
        emoji: emoji,
      ));
    }
  }

  Future<void> _startAudioCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start audio call'),
        content: Text('Call ${widget.args.otherName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      context.push(
        CrushRoutes.call,
        extra: CallScreenArgs(
          matchId: widget.args.otherUserId,
          isVideoCall: false,
          matchName: widget.args.otherName,
          matchPhotoUrl: widget.args.otherPhotoUrl,
        ),
      );
    }
  }

  Widget _buildInput(
    ChatState state, {
    required bool isBlocked,
    required bool canMessage,
    required bool isUnmatched,
    required ProfileCompletenessSummary completeness,
  }) {
    final isSendingText = state.sendStatus == SendStatus.sendingText;
    final isUploading = state.sendStatus == SendStatus.uploadingAttachment;
    final canSendText = !isBlocked &&
        !isUnmatched &&
        canMessage &&
        !isSendingText &&
        !isUploading;
    final canSendMedia = state.mediaSendingEnabled &&
        !isBlocked &&
        !isUnmatched &&
        canMessage &&
        !isUploading;

    // Show voice recorder when in recording mode
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
            // Match the app bar gradient style (topLeft to bottomRight)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseSurface.withValues(alpha: 0.85),
                baseSurface.withValues(alpha: 0.7),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: borderBase,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.sm,
                vertical: DsSpacing.sm,
              ),
              child: Row(
                children: [
                  // Media action buttons - hide when user is typing
                  AnimatedSize(
                    duration:
                        Duration(milliseconds: (200 * motionScale).round()),
                    curve: Curves.easeInOut,
                    child: _hasInputText
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        DsColors.surfaceLight
                                            .withValues(alpha: 0.08),
                                        DsColors.surfaceLight
                                            .withValues(alpha: 0.04),
                                      ]
                                    : [
                                        DsColors.ink900.withValues(alpha: 0.04),
                                        DsColors.ink900.withValues(alpha: 0.02),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: borderBase.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Gallery button (photo/video picker)
                                _buildMediaButton(
                                  icon: Icons.photo_library_rounded,
                                  tooltip: 'Send photo or video',
                                  onPressed: canSendMedia
                                      ? () => _showMediaPickerOptions(
                                          canMessage, completeness, isDark)
                                      : null,
                                  isDark: isDark,
                                ),
                                // Voice note button
                                _buildMediaButton(
                                  icon: Icons.mic_rounded,
                                  tooltip: 'Voice note',
                                  onPressed: canSendMedia
                                      ? () => _startVoiceRecording(
                                          canMessage, completeness)
                                      : null,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Spacing between media buttons and text field
                  AnimatedSize(
                    duration:
                        Duration(milliseconds: (200 * motionScale).round()),
                    curve: Curves.easeInOut,
                    child: _hasInputText
                        ? const SizedBox.shrink()
                        : const SizedBox(width: DsSpacing.sm),
                  ),
                  // Enhanced glass text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: borderBase,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DsColors.ink900.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: canSendText,
                        onChanged: _onTextChanged,
                        minLines: 1,
                        maxLines:
                            2, // Expands to 2 lines, then scrolls internally
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
                                ? DsColors.surfaceLight.withValues(alpha: 0.38)
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
                  const SizedBox(width: DsSpacing.sm),
                  // Enhanced glass send button with glow effect
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DsColors.primary,
                          DsColors.secondary,
                        ],
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    DsColors.surfaceLight),
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: DsColors.surfaceLight),
                      onPressed: isSendingText
                          ? null
                          : () async {
                              if (isBlocked) {
                                showErrorSnackBar(
                                  context,
                                  'Unblock ${widget.args.otherName} to send messages.',
                                );
                                return;
                              }
                              if (isUnmatched) {
                                showErrorSnackBar(
                                  context,
                                  'You unmatched with ${widget.args.otherName}. Messaging is disabled.',
                                );
                                return;
                              }
                              if (!canMessage) {
                                _showMessagingIncomplete(completeness);
                                return;
                              }
                              final allowed =
                                  await _ensureBackendAllowsMessaging(
                                      completeness);
                              if (!allowed || !mounted) return;
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              HapticService.messageSent();
                              context.read<ChatBloc>().add(ChatMessageSent(
                                    matchId: widget.args.matchId,
                                    fromUserId: widget.args.currentUserId,
                                    toUserId: widget.args.otherUserId,
                                    content: text,
                                    type: MessageType.text,
                                  ));
                              _controller.clear();
                              _onTextChanged('');
                            },
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

  Widget _buildMessageSkeletonList() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isFromMe = index.isEven;
        final baseWidth = isFromMe ? 150.0 : 200.0;
        final width = baseWidth + (index % 3) * 18;
        return GlassSkeletonMessage(
          isFromMe: isFromMe,
          width: width,
        );
      },
    );
  }

  /// Helper to build styled media buttons for the input bar.
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
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: isActive
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DsColors.primary.withValues(alpha: 0.2),
                        DsColors.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Icon(
              icon,
              size: 20,
              color: isEnabled
                  ? (isActive
                      ? DsColors.primary
                      : (isDark
                          ? DsColors.surfaceLight.withValues(alpha: 0.7)
                          : DsColors.ink900.withValues(alpha: 0.54)))
                  : (isDark
                      ? DsColors.surfaceLight.withValues(alpha: 0.24)
                      : DsColors.ink900.withValues(alpha: 0.26)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    Message msg,
    String textFallback, {
    required bool isHeld,
    required bool pendingScan,
    required bool isMe,
  }) {
    if (isHeld) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, size: 16, color: DsColors.surfaceLight),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Message held for safety review',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }
    switch (msg.type) {
      case MessageType.image:
        if (pendingScan) {
          return const Text('Image pending safety scan…');
        }
        // Check if it's a local file path or a network URL
        final isLocalFile =
            msg.content.startsWith('/') || msg.content.startsWith('file://');
        return GestureDetector(
          onTap: () => isLocalFile ? null : _launchUrl(msg.content),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isLocalFile
                ? Image.file(
                    File(msg.content.replaceFirst('file://', '')),
                    width: 220,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildMediaErrorPlaceholder(
                      Icons.broken_image_outlined,
                      'Image unavailable',
                    ),
                  )
                : CachedImage(
                    imageUrl: msg.content,
                    width: 220,
                    height: 260,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                    errorWidget: _buildMediaErrorPlaceholder(
                      Icons.broken_image_outlined,
                      'Image unavailable',
                    ),
                  ),
          ),
        );
      case MessageType.video:
        final isLocalVideo =
            msg.content.startsWith('/') || msg.content.startsWith('file://');
        return ChatAttachmentTile(
          label: pendingScan ? 'Video (scan pending)' : 'Video',
          url: msg.content,
          icon: Icons.videocam,
          isLocal: isLocalVideo,
        );
      case MessageType.voice:
        final isLocalAudio =
            msg.content.startsWith('/') || msg.content.startsWith('file://');
        if (pendingScan) {
          return ChatAttachmentTile(
            label: 'Voice (scan pending)',
            url: msg.content,
            icon: Icons.mic,
            isLocal: isLocalAudio,
          );
        }
        return VoiceNotePlayer(
          audioUrl: msg.content,
          isFromCurrentUser: isMe,
          isLocal: isLocalAudio,
          compact: true,
        );
      case MessageType.text:
        return Text(textFallback);
    }
  }

  Map<String, int> _reactionCounts(Message msg) {
    final counts = <String, int>{};
    for (final emoji in msg.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  /// Check if we should show a date separator before this message.
  bool _shouldShowDateSeparator(List<Message> messages, int index) {
    if (index == 0) return true; // Always show for first message
    final currentDate = messages[index].sentAt;
    final previousDate = messages[index - 1].sentAt;
    return !_isSameDay(currentDate, previousDate);
  }

  /// Check if two dates are on the same day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Builds a styled error placeholder for media that fails to load.
  Widget _buildMediaErrorPlaceholder(IconData icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    return Container(
      width: 220,
      height: 160,
      decoration: BoxDecoration(
        color: baseSurface.withValues(alpha: isDark ? 0.6 : 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DsGlassColors.borderFor(context),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
          DsGap.sm,
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _moderationLabel(
    Message msg, {
    required bool isHeld,
    required bool pendingScan,
  }) {
    if (isHeld) {
      return msg.moderationReason ?? 'Message held for review';
    }
    if (pendingScan) return 'Pending safety scan';
    if (msg.isFlagged) return msg.moderationReason ?? 'Flagged for review';
    return 'Safety check';
  }

  void _toggleMedia(ChatState state) {
    context.read<ChatBloc>().add(
          ChatMediaToggleRequested(
            matchId: widget.args.matchId,
            requesterId: widget.args.currentUserId,
            enabled: !state.mediaSendingEnabled,
          ),
        );
  }

  void _onTextChanged(String value) {
    final shouldType = value.trim().isNotEmpty;

    // Update UI state for showing/hiding media buttons
    if (shouldType != _hasInputText) {
      setState(() {
        _hasInputText = shouldType;
      });
    }

    if (shouldType != _isTyping) {
      _isTyping = shouldType;
      context.read<ChatBloc>().add(
            ChatTypingStatusChanged(
              matchId: widget.args.matchId,
              userId: widget.args.currentUserId,
              isTyping: shouldType,
            ),
          );
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(
              ChatTypingStatusChanged(
                matchId: widget.args.matchId,
                userId: widget.args.currentUserId,
                isTyping: false,
              ),
            );
      }
    });
  }

  void _maybeRefreshBackendCompleteness(Profile? profile) {
    final signature = _profileSignature(profile);
    if (_lastProfileSignature == signature) return;
    _lastProfileSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _backendCompleteness = null;
          _completenessError = null;
          _backendBlocked = false;
        });
        return;
      }
      _refreshBackendCompleteness();
    });
  }

  Future<void> _refreshBackendCompleteness() async {
    setState(() {
      _checkingCompleteness = true;
      _completenessError = null;
    });
    try {
      final result = await _validationService.validate(minimum: 'messaging');
      if (!mounted) return;
      setState(() {
        _backendCompleteness = result;
        _completenessError = null;
        _backendBlocked = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backendCompleteness = null;
        _completenessError = _friendlyError(e);
        _backendBlocked = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingCompleteness = false;
        });
      }
    }
  }

  Future<bool> _ensureBackendAllowsMessaging(
    ProfileCompletenessSummary local,
  ) async {
    if (_backendCompleteness == null && !_checkingCompleteness) {
      await _refreshBackendCompleteness();
      if (!mounted) return false;
    }
    final backend = _backendCompleteness;
    if (backend == null) {
      if (_backendBlocked) {
        if (_completenessError != null) {
          showErrorSnackBar(context, _completenessError!);
        }
        _showMessagingIncomplete(local);
        return false;
      }
      if (_completenessError != null) {
        showErrorSnackBar(
          context,
          'Could not verify profile completeness with the server. Using local checks.',
        );
        return true;
      }
      if (_checkingCompleteness) {
        showErrorSnackBar(
          context,
          'Checking your profile with the server. Try again in a moment.',
        );
      }
      return false;
    }
    if (!backend.allowsMessaging) {
      _showMessagingIncomplete(local);
      return false;
    }
    return true;
  }

  List<String> _missingMessages(ProfileCompletenessSummary local) {
    final remoteMissing = _backendCompleteness?.missingForMessaging;
    if (remoteMissing != null && remoteMissing.isNotEmpty) {
      return remoteMissing;
    }
    if (local.requiredMissing.isNotEmpty) return local.requiredMissing;
    return local.missing;
  }

  void _showMessagingIncomplete(ProfileCompletenessSummary completeness) {
    final missing = _missingMessages(completeness);
    final message = missing.isEmpty
        ? 'Finish your profile to continue messaging.'
        : 'Finish your profile: ${missing.take(3).join(', ')}';
    showErrorSnackBar(context, message);
    _goToProfileEdit(context);
  }

  String _profileSignature(Profile? profile) {
    if (profile == null) return 'none';
    return [
      profile.id,
      profile.photoUrls.length,
      profile.profilePrompts.length,
      profile.bio.hashCode,
      profile.interests.length,
      profile.isVerified,
    ].join('|');
  }

  String _friendlyError(Object error) {
    if (error is Exception) {
      return error.toString();
    }
    return 'Could not verify profile completeness. Check your connection.';
  }

  void _showMediaPickerOptions(
    bool canMessage,
    ProfileCompletenessSummary completeness,
    bool isDark,
  ) {
    final titleColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final iconColor = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_rounded,
                  color: iconColor,
                ),
                title: Text(
                  'Photo',
                  style: TextStyle(
                    color: titleColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(canMessage, completeness);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.videocam_rounded,
                  color: iconColor,
                ),
                title: Text(
                  'Video',
                  style: TextStyle(
                    color: titleColor,
                  ),
                ),
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
      _showMessagingIncomplete(completeness);
      return;
    }
    // Prevent concurrent image picker operations
    if (_isPickingMedia) return;
    final allowed = await _ensureBackendAllowsMessaging(completeness);
    if (!allowed || !mounted) return;

    _isPickingMedia = true;
    try {
      final result = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted || result == null) return;
      HapticService.messageSent();
      context.read<ChatBloc>().add(
            ChatMediaSendRequested(
              matchId: widget.args.matchId,
              fromUserId: widget.args.currentUserId,
              toUserId: widget.args.otherUserId,
              filePath: result.path,
              type: MessageType.image,
            ),
          );
    } on PlatformException catch (e) {
      // Handle "already_active" error gracefully - picker from another screen may still be active
      AppLogger.error('Image picker error: ${e.code} - ${e.message}');
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _pickAndSendVideo(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      _showMessagingIncomplete(completeness);
      return;
    }
    // Prevent concurrent image picker operations
    if (_isPickingMedia) return;
    final allowed = await _ensureBackendAllowsMessaging(completeness);
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
              matchId: widget.args.matchId,
              fromUserId: widget.args.currentUserId,
              toUserId: widget.args.otherUserId,
              filePath: result.path,
              type: MessageType.video,
            ),
          );
    } on PlatformException catch (e) {
      // Handle "already_active" error gracefully - picker from another screen may still be active
      AppLogger.error('Video picker error: ${e.code} - ${e.message}');
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _startVoiceRecording(
    bool canMessage,
    ProfileCompletenessSummary completeness,
  ) async {
    if (!canMessage) {
      _showMessagingIncomplete(completeness);
      return;
    }
    final allowed = await _ensureBackendAllowsMessaging(completeness);
    if (!allowed || !mounted) return;

    // Enter voice recording mode
    setState(() => _isRecordingVoice = true);
  }

  void _sendVoiceNote(String filePath) {
    HapticService.messageSent();
    context.read<ChatBloc>().add(
          ChatMediaSendRequested(
            matchId: widget.args.matchId,
            fromUserId: widget.args.currentUserId,
            toUserId: widget.args.otherUserId,
            filePath: filePath,
            type: MessageType.voice,
          ),
        );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      showErrorSnackBar(context, 'Could not open attachment.');
    }
  }

  String _muteSummary({
    required bool messagesMuted,
    required bool callsMuted,
    required String name,
  }) {
    if (messagesMuted && callsMuted) {
      return 'You muted messages and calls from $name.';
    }
    if (messagesMuted) {
      return 'You muted messages from $name.';
    }
    return 'You muted calls from $name.';
  }

  void _handleSafetyAction(
    BuildContext context,
    SafetyCubit cubit, {
    required bool isBlocked,
    required bool messagesMuted,
    required bool callsMuted,
    required _ChatSafetyAction action,
  }) async {
    switch (action) {
      case _ChatSafetyAction.viewProfile:
        _navigateToProfile();
        break;
      case _ChatSafetyAction.chatSettings:
        _showMatchChatSettings(context);
        break;
      case _ChatSafetyAction.report:
        _showReportSheet(context, cubit);
        break;
      case _ChatSafetyAction.block:
        await _toggleBlock(context, cubit, block: !isBlocked);
        break;
      case _ChatSafetyAction.unmatch:
        final chatBloc = context.read<ChatBloc>();
        final messenger = ScaffoldMessenger.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Unmatch?'),
            content: Text(
              'This will remove your match with ${widget.args.otherName}. You will not be able to message unless you match again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Unmatch'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          chatBloc.add(
            ChatUnmatchRequested(
              matchId: widget.args.matchId,
              userId: widget.args.currentUserId,
            ),
          );
          messenger.showSnackBar(
            SnackBar(
              content: Text('Unmatching from ${widget.args.otherName}...'),
            ),
          );
        }
        break;
      case _ChatSafetyAction.muteMessages:
        cubit.toggleMuteMessages(
          widget.args.otherUserId,
          mute: !messagesMuted,
        );
        _showTemporaryMuteNotification(
          messagesMuted ? 'Messages unmuted' : 'Messages muted',
          messagesMuted ? Icons.notifications_active : Icons.notifications_off,
        );
        break;
      case _ChatSafetyAction.muteCalls:
        cubit.toggleMuteCalls(
          widget.args.otherUserId,
          mute: !callsMuted,
        );
        _showTemporaryMuteNotification(
          callsMuted ? 'Calls unmuted' : 'Calls muted',
          callsMuted ? Icons.call : Icons.call_end,
        );
        break;
      case _ChatSafetyAction.safetyCenter:
        if (!mounted) return;
        context.push(CrushRoutes.safety);
        break;
    }
  }

  void _navigateToProfile() async {
    // Fetch the profile for the other user
    final discoveryRepo = context.read<DiscoveryRepository>();
    final profile =
        await discoveryRepo.fetchProfileById(widget.args.otherUserId);

    if (!mounted) return;

    if (profile != null) {
      context.push(
        CrushRoutes.userProfile,
        extra: OtherUserProfileArgs(
          profile: profile,
          isMatch: true,
          matchId: widget.args.matchId,
        ),
      );
    } else {
      // If profile fetch fails, create a minimal profile from available data
      final minimalProfile = Profile(
        id: widget.args.otherUserId,
        name: widget.args.otherName,
        age: 0,
        gender: '',
        bio: '',
        photoUrls: widget.args.otherPhotoUrl != null
            ? [widget.args.otherPhotoUrl!]
            : [],
        videoUrls: const [],
        interests: const [],
        city: '',
        country: '',
        isVerified: false,
        preferences: const DiscoveryPreferences(
          minAge: 18,
          maxAge: 100,
          maxDistanceKm: 100,
          showMeGenders: [],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: '',
          city: '',
        ),
      );
      context.push(
        CrushRoutes.userProfile,
        extra: OtherUserProfileArgs(
          profile: minimalProfile,
          isMatch: true,
          matchId: widget.args.matchId,
        ),
      );
    }
  }

  void _showTemporaryMuteNotification(String message, IconData icon) {
    // Show a temporary overlay notification that fades away
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => ChatFadeNotification(
        message: message,
        icon: icon,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  Future<void> _toggleBlock(
    BuildContext context,
    SafetyCubit cubit, {
    required bool block,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await cubit.toggleBlock(
      widget.args.otherUserId,
      block: block,
      currentUserId: widget.args.currentUserId,
    );
    if (!context.mounted) return;
    final error = cubit.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          block
              ? 'Blocked ${widget.args.otherName}.'
              : 'Unblocked ${widget.args.otherName}.',
        ),
      ),
    );
  }

  void _showMatchChatSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);
    final borderBase = DsGlassColors.borderFor(context);
    // Get current user's premium status from auth
    final authState = context.read<AuthBloc>().state;
    final isPremium = authState.user?.plan.isPlus ?? false;

    // Get existing match chat settings (default to false if not set)
    // In production, you'd fetch this from Firestore via a repository
    const initialSettings = ChatSettings();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider(
        create: (_) => MatchChatSettingsCubit(
          matchId: widget.args.matchId,
          initialSettings: initialSettings,
          isPremium: isPremium,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: DsBlur.heavy, sigmaY: DsBlur.heavy),
            child: Container(
              decoration: BoxDecoration(
                color: baseSurface.withValues(alpha: isDark ? 0.95 : 0.98),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: borderBase,
                  width: 0.5,
                ),
              ),
              child: SafeArea(
                child: BlocConsumer<MatchChatSettingsCubit,
                    MatchChatSettingsState>(
                  listenWhen: (prev, curr) =>
                      prev.errorMessage != curr.errorMessage &&
                      curr.errorMessage != null,
                  listener: (ctx, state) {
                    if (state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: DsColors.error,
                        ),
                      );
                      ctx.read<MatchChatSettingsCubit>().clearError();
                    }
                  },
                  builder: (ctx, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DsColors.surfaceLight
                                      .withValues(alpha: 0.24)
                                  : DsColors.ink900.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      DsColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings_outlined,
                                  color: DsColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chat Settings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Conversation with ${widget.args.otherName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? DsColors.textMutedDark
                                                : DsColors.textMutedLight,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Close button
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close,
                                  color: isDark
                                      ? DsColors.surfaceLight
                                          .withValues(alpha: 0.54)
                                      : DsColors.ink900.withValues(alpha: 0.45),
                                  size: 22,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? DsColors.surfaceLight
                                          .withValues(alpha: 0.05)
                                      : DsColors.ink900.withValues(alpha: 0.05),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(
                            height: 1,
                            color: isDark
                                ? DsColors.surfaceLight.withValues(alpha: 0.12)
                                : DsColors.ink900.withValues(alpha: 0.12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Privacy Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PRIVACY',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: isDark
                                          ? DsColors.textMutedDark
                                          : DsColors.textMutedLight,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Message Retention Setting
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DsColors.surfaceLight
                                      .withValues(alpha: 0.05)
                                  : DsColors.ink900.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? DsColors.surfaceLight
                                        .withValues(alpha: 0.1)
                                    : DsColors.ink900.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: DsColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.timer_outlined,
                                        color: DsColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Message Retention',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Messages auto-delete after this time',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isDark
                                                      ? DsColors.textMutedDark
                                                      : DsColors.textMutedLight,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Current retention status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: DsColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: DsColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Currently: ${state.retentionDisplay}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: DsColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Toggle or Premium badge
                                if (state.isPremium) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          DsColors.warning
                                              .withValues(alpha: 0.15),
                                          DsColors.warning
                                              .withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.workspace_premium,
                                            color: DsColors.warning, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Plus: 7 days retention',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: DsColors.warning,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  // Extended retention toggle
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Extended retention (24h)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      if (state.isLoading)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      else
                                        Switch.adaptive(
                                          value:
                                              state.settings.extendedRetention,
                                          onChanged: (value) => ctx
                                              .read<MatchChatSettingsCubit>()
                                              .toggleExtendedRetention(value),
                                          activeThumbColor: DsColors.primary,
                                          activeTrackColor: DsColors.primary
                                              .withValues(alpha: 0.4),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.settings.extendedRetention
                                        ? 'Messages deleted 24 hours after being read'
                                        : 'Messages deleted 1 hour after being read',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? DsColors.textMutedDark
                                              : DsColors.textMutedLight,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context, SafetyCubit cubit) {
    const reasons = [
      'Spam or scams',
      'Harassment or hate',
      'Inappropriate content',
      'Fake profile',
      'Other',
    ];

    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Report user',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Reports are anonymous and reviewed by our team. Last match: ${widget.args.matchId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (reason == 'Other') {
                      _showCustomReportDialog(context, cubit);
                    } else {
                      await cubit.reportWithContext(
                        reporterId: widget.args.currentUserId,
                        reportedId: widget.args.otherUserId,
                        reason: reason,
                        matchId: widget.args.matchId,
                        source: 'chat',
                      );
                      if (!mounted) return;
                      final error = cubit.state.errorMessage;
                      messenger.showSnackBar(SnackBar(
                        content: Text(error ?? 'Report submitted: $reason'),
                      ));
                    }
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push(CrushRoutes.safetyGuidelines),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('View community guidelines'),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  void _showCustomReportDialog(BuildContext context, SafetyCubit cubit) {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Report details'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us what happened',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final details = controller.text.trim();
                if (details.isNotEmpty) {
                  await cubit.reportWithContext(
                    reporterId: widget.args.currentUserId,
                    reportedId: widget.args.otherUserId,
                    reason: 'Other',
                    description: details,
                    matchId: widget.args.matchId,
                    source: 'chat',
                  );
                  if (!mounted) return;
                  final error = cubit.state.errorMessage;
                  messenger.showSnackBar(
                    SnackBar(content: Text(error ?? 'Report submitted')),
                  );
                }
                navigator.pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _goToProfileEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }
}

enum _ChatSafetyAction {
  viewProfile,
  chatSettings,
  report,
  block,
  unmatch,
  muteMessages,
  muteCalls,
  safetyCenter
}

/// Loading indicator shown at the top when loading older messages.
class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Text(
              'Loading older messages...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
