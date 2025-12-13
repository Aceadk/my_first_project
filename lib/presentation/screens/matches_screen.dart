import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/chat/chat_bloc.dart';
import '../../logic/matches/matches_bloc.dart';
import '../../logic/matches/matches_event.dart';
import '../../logic/matches/matches_state.dart';
import '../../core/ui/snackbar_utils.dart';
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
    return BlocConsumer<MatchesBloc, MatchesState>(
      listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.matches.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Matches')),
            body: Center(
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
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Matches')),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final match = state.matches[index];
              final otherName =
                  (match.otherUserId.isNotEmpty ? match.otherUserId : null) ??
                      'Unknown';

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
