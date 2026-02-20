import 'package:crushhour/design_system/widgets/typing_indicator.dart';
import 'dart:async';
import 'dart:ui';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/features/chat/domain/services/ice_breaker_service.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/bloc/match_chat_settings_cubit.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_header.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  List<IceBreakerSuggestion> _iceBreakerSuggestions = [];
  RemoteProfileCompleteness? _backendCompleteness;
  bool _checkingCompleteness = false;
  String? _completenessError;
  String? _lastProfileSignature;
  bool _backendBlocked = false;
  late final ProfileValidationRepository _validationService = context
      .read<ProfileValidationRepository>();

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
        _chatBloc?.add(
          ChatOpened(
            widget.args.matchId,
            widget.args.currentUserId,
            widget.args.otherUserId,
            otherUserPhotoUrl: widget.args.otherPhotoUrl,
          ),
        );
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
          _verificationBannerCooldownKey,
          now.millisecondsSinceEpoch,
        );
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
    context.read<ChatBloc>().add(
      ChatMessageSent(
        matchId: widget.args.matchId,
        content: text,
        type: MessageType.text,
        fromUserId: widget.args.currentUserId,
        toUserId: widget.args.otherUserId,
      ),
    );
  }

  @override
  void dispose() {
    // Use stored reference instead of context.read() which is unsafe in dispose
    _chatBloc?.add(ChatClosed(widget.args.matchId, widget.args.currentUserId));
    _typingTimer?.cancel();
    _verificationBannerTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.select<ProfileBloc, Profile?>(
      (bloc) => bloc.state.profile ?? bloc.state.user?.profile,
    );
    final completeness = evaluateProfileCompleteness(userProfile);
    _maybeRefreshBackendCompleteness(userProfile);
    final backendMessageAllowed =
        _backendCompleteness?.allowsMessaging ??
        (_backendBlocked ? false : _completenessError != null);

    return BlocBuilder<SafetyCubit, SafetyState>(
      builder: (context, safetyState) {
        final safety = context.read<SafetyCubit>();
        final isBlocked = safetyState.blockedUsers.contains(
          widget.args.otherUserId,
        );
        final messagesMuted = safetyState.mutedMessages.contains(
          widget.args.otherUserId,
        );
        final callsMuted = safetyState.mutedCalls.contains(
          widget.args.otherUserId,
        );
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
            final canMessage =
                completeness.meetsMessagingMinimum &&
                completeness.meetsRequiredFields &&
                backendMessageAllowed &&
                !isBlocked &&
                !state.isUnmatched;
            final isOtherTyping = state.typingUserIds.contains(
              widget.args.otherUserId,
            );

            return AsyncStateScaffold(
              appBar: ChatHeader(
                state: state,
                isBlocked: isBlocked,
                messagesMuted: messagesMuted,
                callsMuted: callsMuted,
                otherName: widget.args.otherName,
                currentUserId: widget.args.currentUserId,
                otherUserId: widget.args.otherUserId,
                matchId: widget.args.matchId,
                onNavigateToProfile: _navigateToProfile,
                onStartAudioCall: _startAudioCall,
                onSafetyAction: (action) => _handleSafetyAction(
                  context,
                  safety,
                  isBlocked: isBlocked,
                  messagesMuted: messagesMuted,
                  callsMuted: callsMuted,
                  action: action,
                ),
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
                              style: Theme.of(context).textTheme.bodySmall
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DsColors.warning,
                        ),
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
                            icon: const Icon(
                              Icons.refresh,
                              color: DsColors.error,
                            ),
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
                                color: DsColors.surfaceLight.withValues(
                                  alpha: 0.7,
                                ),
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
                            onPressed: () =>
                                _toggleBlock(context, safety, block: false),
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
                          const Icon(
                            Icons.info_outline,
                            color: DsColors.warning,
                          ),
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
                                  value:
                                      _backendCompleteness?.score ??
                                      completeness.score,
                                  minHeight: 5,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Missing: ${_missingMessages(completeness).take(2).join(', ')}',
                                  style: const TextStyle(
                                    color: DsColors.warning,
                                  ),
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
                        ? const Center(child: CircularProgressIndicator())
                        : ChatMessageList(
                            state: state,
                            scrollController: _scrollController,
                            currentUserId: widget.args.currentUserId,
                            otherName: widget.args.otherName,
                            matchId: widget.args.otherUserId,
                            onRefreshIceBreakers: _refreshIceBreakers,
                            onIceBreakerTap: _onIceBreakerTap,
                            iceBreakerSuggestions: _iceBreakerSuggestions,
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
                    const TypingIndicator(),
                  ChatInputBar(
                    state: state,
                    isBlocked: isBlocked,
                    canMessage: canMessage,
                    isUnmatched: state.isUnmatched,
                    completeness: completeness,
                    currentUserId: widget.args.currentUserId,
                    otherUserId: widget.args.otherUserId,
                    otherName: widget.args.otherName,
                    matchId: widget.args.matchId,
                    onEnsureMessagingAllowed: _ensureBackendAllowsMessaging,
                    onShowMessagingIncomplete: _showMessagingIncomplete,
                  ),
                ],
              ),
            );
          },
        );
      },
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

  bool _isNetworkError(String? message) {
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('internet connection') ||
        lower.contains('network') ||
        lower.contains('wifi');
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

  /// Helper to build styled media buttons for the input bar.

  void _toggleMedia(ChatState state) {
    context.read<ChatBloc>().add(
      ChatMediaToggleRequested(
        matchId: widget.args.matchId,
        requesterId: widget.args.currentUserId,
        enabled: !state.mediaSendingEnabled,
      ),
    );
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
    required ChatSafetyAction action,
  }) async {
    switch (action) {
      case ChatSafetyAction.viewProfile:
        _navigateToProfile();
        break;
      case ChatSafetyAction.chatSettings:
        _showMatchChatSettings(context);
        break;
      case ChatSafetyAction.report:
        _showReportSheet(context, cubit);
        break;
      case ChatSafetyAction.block:
        await _toggleBlock(context, cubit, block: !isBlocked);
        break;
      case ChatSafetyAction.unmatch:
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
      case ChatSafetyAction.muteMessages:
        cubit.toggleMuteMessages(widget.args.otherUserId, mute: !messagesMuted);
        _showTemporaryMuteNotification(
          messagesMuted ? 'Messages unmuted' : 'Messages muted',
          messagesMuted ? Icons.notifications_active : Icons.notifications_off,
        );
        break;
      case ChatSafetyAction.muteCalls:
        cubit.toggleMuteCalls(widget.args.otherUserId, mute: !callsMuted);
        _showTemporaryMuteNotification(
          callsMuted ? 'Calls unmuted' : 'Calls muted',
          callsMuted ? Icons.call : Icons.call_end,
        );
        break;
      case ChatSafetyAction.safetyCenter:
        if (!mounted) return;
        context.push(CrushRoutes.safety);
        break;
    }
  }

  void _navigateToProfile() async {
    // Fetch the profile for the other user
    final discoveryRepo = context.read<DiscoveryRepository>();
    final profile = await discoveryRepo.fetchProfileById(
      widget.args.otherUserId,
    );

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
            filter: ImageFilter.blur(
              sigmaX: DsBlur.heavy,
              sigmaY: DsBlur.heavy,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: baseSurface.withValues(alpha: isDark ? 0.95 : 0.98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: borderBase, width: 0.5),
              ),
              child: SafeArea(
                child: BlocConsumer<MatchChatSettingsCubit, MatchChatSettingsState>(
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
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.24,
                                    )
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
                                  color: DsColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
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
                                      ? DsColors.surfaceLight.withValues(
                                          alpha: 0.54,
                                        )
                                      : DsColors.ink900.withValues(alpha: 0.45),
                                  size: 22,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? DsColors.surfaceLight.withValues(
                                          alpha: 0.05,
                                        )
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
                                style: Theme.of(context).textTheme.labelSmall
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
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.05,
                                    )
                                  : DsColors.ink900.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? DsColors.surfaceLight.withValues(
                                        alpha: 0.1,
                                      )
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
                                        color: DsColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
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
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DsColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
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
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          DsColors.warning.withValues(
                                            alpha: 0.15,
                                          ),
                                          DsColors.warning.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.workspace_premium,
                                          color: DsColors.warning,
                                          size: 18,
                                        ),
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
                                            strokeWidth: 2,
                                          ),
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
                                    style: Theme.of(context).textTheme.bodySmall
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
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Report submitted: $reason'),
                        ),
                      );
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
  }
}
