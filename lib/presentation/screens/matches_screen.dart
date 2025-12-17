import 'package:flutter/material.dart';
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
import '../widgets/async_state_scaffold.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

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
      child: _MatchesView(currentUserId: userId),
    );
  }
}

class _MatchesView extends StatelessWidget {
  final String currentUserId;

  const _MatchesView({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        final emptyView = state.matches.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border, size: 72),
                      const SizedBox(height: 16),
                      const Text(
                        'No matches yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keep swiping and sending message requests.\n'
                        'When you match with someone, they will appear here.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back to deck'),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<SubscriptionBloc, SubscriptionState>(
                        builder: (context, subState) {
                          final isPlus = subState.plan == SubscriptionPlan.plus;
                          final loading = subState.isCheckoutInProgress;
                          if (isPlus) return const SizedBox.shrink();
                          return Column(
                            children: [
                              const Text(
                                'Intro offer: 50% off Plus',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'See likes first, Passport to any city, and unlimited likes to help you match faster.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () => context
                                        .read<SubscriptionBloc>()
                                        .add(PlusCheckoutRequested()),
                                child: loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Try Plus intro offer'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null;

        return AsyncStateScaffold(
          appBar: AppBar(title: const Text('Matches')),
          isLoading: state.isLoading && state.matches.isEmpty,
          errorMessage: state.errorMessage,
          showErrorSnackBar: true,
          empty: emptyView,
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final match = state.matches[index];
              final otherName =
                  (match.otherUserId.trim().isNotEmpty ? match.otherUserId : null) ??
                      'Name unavailable';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(otherName),
                subtitle: const Text('Tap to open chat'),
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
