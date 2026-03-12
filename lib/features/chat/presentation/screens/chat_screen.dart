import 'package:crushhour/design_system/widgets/typing_indicator.dart';
import 'dart:async';
export 'package:crushhour/features/chat/presentation/widgets/chat_report_sheet.dart'
    show
        ChatReportReasonOption,
        chatReportReasonCode,
        chatReportReasonLabelFor,
        ChatReportSheetContent;

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
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
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

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

const Key chatConversationConstraintKey = ValueKey<String>(
  'chat_conversation_constraint',
);

double chatConversationMaxWidthFor(double screenWidth) {
  return DsBreakpoints.contentMaxWidth(screenWidth);
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
    final chatBloc = _chatBloc;
    if (chatBloc != null && !chatBloc.isClosed) {
      chatBloc.add(ChatClosed(widget.args.matchId, widget.args.currentUserId));
    }
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).verifyYourIdToAdd,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _dismissVerificationBanner();
                              context.push(CrushRoutes.idVerification);
                            },
                            child: Text(AppLocalizations.of(context).verify),
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
                            child: Text(AppLocalizations.of(context).unblock),
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
                            child: Text(AppLocalizations.of(context).finish),
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
                            child: Text(AppLocalizations.of(context).unmute),
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).mediaSendingIsDisabledFor,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleMedia(state),
                            child: Text(AppLocalizations.of(context).enable),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, conversationConstraints) {
                        final maxConversationWidth =
                            chatConversationMaxWidthFor(
                              MediaQuery.sizeOf(context).width,
                            );
                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            key: chatConversationConstraintKey,
                            constraints: BoxConstraints(
                              maxWidth: maxConversationWidth,
                              maxHeight: conversationConstraints.maxHeight,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: showSkeleton
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : ChatMessageList(
                                          state: state,
                                          scrollController: _scrollController,
                                          currentUserId:
                                              widget.args.currentUserId,
                                          otherName: widget.args.otherName,
                                          matchId: widget.args.otherUserId,
                                          onRefreshIceBreakers:
                                              _refreshIceBreakers,
                                          onIceBreakerTap: _onIceBreakerTap,
                                          iceBreakerSuggestions:
                                              _iceBreakerSuggestions,
                                        ),
                                ),
                                if (state.isUnsendInProgress)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: LinearProgressIndicator(
                                      minHeight: 2,
                                    ),
                                  ),
                                if (state.isUnmatching)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: LinearProgressIndicator(
                                      minHeight: 2,
                                    ),
                                  ),
                                ChatSendStatusBar(state: state),
                                if (isOtherTyping) const TypingIndicator(),
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
                                  onEnsureMessagingAllowed:
                                      _ensureBackendAllowsMessaging,
                                  onShowMessagingIncomplete:
                                      _showMessagingIncomplete,
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
        title: Text(AppLocalizations.of(context).startAudioCall),
        content: Text('Call ${widget.args.otherName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.call),
            label: Text(AppLocalizations.of(context).call),
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
            title: Text(AppLocalizations.of(context).unmatch1),
            content: Text(
              'This will remove your match with ${widget.args.otherName}. You will not be able to message unless you match again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(AppLocalizations.of(context).unmatch),
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
    final l10n = context.l10n;
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
              ? l10n.chatSafetyBlockedUser(widget.args.otherName)
              : l10n.chatSafetyUnblockedUser(widget.args.otherName),
        ),
      ),
    );
  }

  void _showMatchChatSettings(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isPremium = authState.user?.tier.hasPremium ?? false;
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
        child: ChatMatchSettingsSheet(otherName: widget.args.otherName),
      ),
    );
  }

  void _showReportSheet(BuildContext context, SafetyCubit cubit) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ChatReportSheetContent(
            matchId: widget.args.matchId,
            onReasonSelected: (reason) async {
              Navigator.of(sheetContext).pop();
              if (reason == ChatReportReasonOption.other) {
                _showCustomReportDialog(context, cubit);
                return;
              }
              await cubit.reportWithContext(
                reporterId: widget.args.currentUserId,
                reportedId: widget.args.otherUserId,
                reason: chatReportReasonCode(reason),
                matchId: widget.args.matchId,
                source: 'chat',
              );
              if (!mounted) return;
              final error = cubit.state.errorMessage;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    error ??
                        l10n.chatReportSubmittedReason(
                          chatReportReasonLabelFor(l10n, reason),
                        ),
                  ),
                ),
              );
            },
            onViewGuidelines: () => context.push(CrushRoutes.safetyGuidelines),
          ),
        );
      },
    );
  }

  void _showCustomReportDialog(BuildContext context, SafetyCubit cubit) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.reportDetails),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: l10n.chatReportDetailsHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final details = controller.text.trim();
                if (details.isNotEmpty) {
                  await cubit.reportWithContext(
                    reporterId: widget.args.currentUserId,
                    reportedId: widget.args.otherUserId,
                    reason: chatReportReasonCode(ChatReportReasonOption.other),
                    description: details,
                    matchId: widget.args.matchId,
                    source: 'chat',
                  );
                  if (!mounted) return;
                  final error = cubit.state.errorMessage;
                  messenger.showSnackBar(
                    SnackBar(content: Text(error ?? l10n.chatReportSubmitted)),
                  );
                }
                navigator.pop();
              },
              child: Text(l10n.submit),
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
