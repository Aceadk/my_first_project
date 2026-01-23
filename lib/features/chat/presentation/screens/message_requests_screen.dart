import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_cubit.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_state.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';

PreferredSizeWidget _buildMessageRequestsAppBar(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
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
                (isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight)
                    .withValues(alpha: 0.8),
                (isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight)
                    .withValues(alpha: 0.6),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color:
                    isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: DsSpacing.sm,
                    child: GlassIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => context.pop(),
                      size: 40,
                    ),
                  ),
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          DsGradients.chats.createShader(bounds),
                      child: Text(
                        'Message Requests',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildMessageRequestsEmptyState(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Center(
    child: Padding(
      padding: DsEdgeInsets.allXxl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: DsBlur.medium,
                sigmaY: DsBlur.medium,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DsColors.secondary.withValues(alpha: 0.2),
                      DsColors.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? DsGlassColors.borderDark
                        : DsGlassColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      DsGradients.chats.createShader(bounds),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          DsGap.xxl,
          ShaderMask(
            shaderCallback: (bounds) =>
                DsGradients.primaryHorizontal.createShader(bounds),
            child: Text(
              'No message requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),
          DsGap.sm,
          Text(
            'When someone sends you a message request,\nit will show up here for 48 hours.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view message requests.')),
      );
    }

    return BlocProvider(
      create: (context) => MessageRequestsCubit(
        chatRepository: context.read<ChatRepository>(),
        userId: userId,
      )..load(),
      child: _MessageRequestsView(currentUserId: userId),
    );
  }
}

class _MessageRequestsView extends StatelessWidget {
  final String currentUserId;

  const _MessageRequestsView({required this.currentUserId});

  Future<void> _openProfile(
    BuildContext context,
    MessageRequest request,
  ) async {
    final repo = context.read<DiscoveryRepository>();
    final otherUserId = request.otherUserIdFor(currentUserId);
    final profile = await repo.fetchProfileById(otherUserId);
    if (!context.mounted) return;
    if (profile == null) {
      showErrorSnackBar(context, 'Could not load profile.');
      return;
    }
    context.push(
      CrushRoutes.userProfile,
      extra: OtherUserProfileArgs(profile: profile, isMatch: false),
    );
  }

  String _expiresLabel(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours >= 1) {
      return '${remaining.inHours}h left';
    }
    final minutes = remaining.inMinutes.clamp(0, 59);
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageRequestsCubit, MessageRequestsState>(
      builder: (context, state) {
        return AsyncStateScaffold(
          appBar: _buildMessageRequestsAppBar(context),
          isLoading: state.isLoading && state.requests.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: state.requests.isEmpty ? _buildMessageRequestsEmptyState(context) : null,
          body: RefreshIndicator(
            onRefresh: () => context.read<MessageRequestsCubit>().refresh(),
            child: ListView.separated(
              padding: DsEdgeInsets.allLg,
              itemCount: state.requests.length,
              separatorBuilder: (_, __) => DsGap.sm,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                final otherName =
                    request.otherUserNameFor(currentUserId) ?? 'Unknown';
                final otherPhotoUrl =
                    request.otherUserPhotoUrlFor(currentUserId);
                final inbound = request.isInboundFor(currentUserId);
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(DsRadius.lg),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: DsBlur.light,
                      sigmaY: DsBlur.light,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openProfile(context, request),
                        borderRadius: BorderRadius.circular(DsRadius.lg),
                        child: Container(
                          padding: const EdgeInsets.all(DsSpacing.md),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (isDark
                                        ? DsGlassColors.surfaceDark
                                        : DsGlassColors.surfaceLight)
                                    .withValues(alpha: 0.5),
                                (isDark
                                        ? DsGlassColors.surfaceDark
                                        : DsGlassColors.surfaceLight)
                                    .withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(DsRadius.lg),
                            border: Border.all(
                              color: isDark
                                  ? DsGlassColors.borderDark
                                  : DsGlassColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CachedCircleAvatar(
                                imageUrl: otherPhotoUrl,
                                radius: 28,
                              ),
                              const SizedBox(width: DsSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            otherName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: DsSpacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: inbound
                                                ? DsColors.primary.withValues(alpha: 0.15)
                                                : DsColors.secondary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            inbound ? 'Received' : 'Sent',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: inbound
                                                      ? DsColors.primary
                                                      : DsColors.secondary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: DsSpacing.xs),
                                    Text(
                                      request.content,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: DsSpacing.xs),
                                    Row(
                                      children: [
                                        Text(
                                          'Message Request',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? DsColors.textMutedDark
                                                    : DsColors.textMutedLight,
                                              ),
                                        ),
                                        const SizedBox(width: DsSpacing.sm),
                                        Text(
                                          _expiresLabel(request.expiresAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? DsColors.textMutedDark
                                                    : DsColors.textMutedLight,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: DsSpacing.sm),
                              Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
