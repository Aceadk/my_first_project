import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/chat/chat_bloc.dart';
import '../../logic/matches/matches_bloc.dart';
import '../../logic/matches/matches_event.dart';
import '../../logic/matches/matches_state.dart';
import '../../logic/subscription/subscription_bloc.dart';
import '../../logic/subscription/subscription_event.dart';
import '../../logic/subscription/subscription_state.dart';
import '../../core/router.dart';
import '../../data/models/subscription.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing_widgets.dart';
import '../widgets/async_state_scaffold.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, this.onBackToDeck});

  final VoidCallback? onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final userId =
        context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in to view your matches.'),
        ),
      );
    }

    return BlocProvider(
      create: (context) => MatchesBloc(
        chatRepository: context.read<ChatRepository>(),
        userId: userId,
      )..add(const MatchesLoadRequested()),
      child: _MatchesView(currentUserId: userId, onBackToDeck: onBackToDeck),
    );
  }
}

class _MatchesView extends StatelessWidget {
  final String currentUserId;
  final VoidCallback? onBackToDeck;

  const _MatchesView({required this.currentUserId, this.onBackToDeck});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        final emptyView = state.matches.isEmpty
            ? Center(
                child: Padding(
                  padding: DsEdgeInsets.allXxl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DsColors.primary.withValues(alpha: 0.1),
                              DsColors.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 56,
                          color: DsColors.primary,
                        ),
                      ),
                      DsGap.xxl,
                      Text(
                        'No matches yet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DsGap.sm,
                      Text(
                        'Keep swiping and sending message requests.\nWhen you match with someone, they will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DsColors.textMutedLight,
                        ),
                      ),
                      DsGap.xxl,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onBackToDeck,
                          icon: const Icon(Icons.style_outlined),
                          label: const Text('Back to deck'),
                        ),
                      ),
                      DsGap.lg,
                      BlocBuilder<SubscriptionBloc, SubscriptionState>(
                        builder: (context, subState) {
                          final isPlus = subState.plan == SubscriptionPlan.plus;
                          final loading = subState.isCheckoutInProgress;
                          if (isPlus) return const SizedBox.shrink();
                          return _PlusOfferCard(
                            loading: loading,
                            onTap: () => context
                                .read<SubscriptionBloc>()
                                .add(PlusCheckoutRequested()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null;

        return AsyncStateScaffold(
          appBar: AppBar(
            title: const Text('Matches'),
            actions: [
              IconButton(
                icon: const Icon(Icons.shield_outlined),
                tooltip: 'Safety Center',
                onPressed: () =>
                    context.push(CrushRoutes.safety),
              ),
            ],
          ),
          isLoading: state.isLoading && state.matches.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: emptyView,
          body: ListView.separated(
            padding: DsEdgeInsets.allLg,
            itemCount: state.matches.length,
            separatorBuilder: (_, __) => DsGap.sm,
            itemBuilder: (context, index) {
              final match = state.matches[index];
              final otherName = match.otherUserName ??
                  (match.otherUserId.trim().isNotEmpty ? match.otherUserId : null) ??
                  'Name unavailable';

              return _MatchTile(
                name: otherName,
                photoUrl: match.otherUserPhotoUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<ChatBloc>(),
                        child: ChatScreen(
                          args: ChatScreenArgs(
                            matchId: match.id,
                            currentUserId: currentUserId,
                            otherUserId: match.otherUserId,
                            otherName: otherName,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.name,
    required this.onTap,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: DsEdgeInsets.listItemPadding,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DsColors.skeletonLight,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, color: DsColors.textMutedLight)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: DsColors.onlineIndicator,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              DsGap.lgH,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    DsGap.xs,
                    Text(
                      'Tap to open chat',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DsColors.textMutedLight,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DsColors.textMutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusOfferCard extends StatelessWidget {
  const _PlusOfferCard({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: DsEdgeInsets.allLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DsColors.secondary.withValues(alpha: 0.1),
            DsColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DsColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                color: DsColors.primary,
                size: 20,
              ),
              DsGap.smH,
              Text(
                'Intro offer: 50% off Plus',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DsColors.primary,
                    ),
              ),
            ],
          ),
          DsGap.sm,
          Text(
            'See likes first, Passport to any city, and unlimited likes to help you match faster.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DsColors.textMutedLight,
                ),
          ),
          DsGap.md,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: loading ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DsColors.primary),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Try Plus intro offer'),
            ),
          ),
        ],
      ),
    );
  }
}
