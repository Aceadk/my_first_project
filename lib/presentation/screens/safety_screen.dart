import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/safety/safety_cubit.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & blocking')),
      body: BlocBuilder<SafetyCubit, SafetyState>(
        builder: (context, state) {
          final cubit = context.read<SafetyCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Blocked users',
                emptyText:
                    'People you block can’t see your profile, message, or call you.',
                items: state.blockedUsers.toList(),
                onRemove: (userId) => cubit.toggleBlock(userId, block: false),
                removeLabel: 'Unblock',
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Muted messages',
                emptyText:
                    'Mute message alerts for someone without blocking them.',
                items: state.mutedMessages.toList(),
                onRemove: (userId) =>
                    cubit.toggleMuteMessages(userId, mute: false),
                removeLabel: 'Unmute messages',
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Muted calls',
                emptyText: 'Silence call alerts from selected people.',
                items: state.mutedCalls.toList(),
                onRemove: (userId) => cubit.toggleMuteCalls(userId, mute: false),
                removeLabel: 'Unmute calls',
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need to report someone?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Open their profile or chat, choose Report, and pick a reason. '
                        'We review reports to keep the community safe.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.onRemove,
    required this.removeLabel,
  });

  final String title;
  final String emptyText;
  final List<String> items;
  final ValueChanged<String> onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                emptyText,
                style: const TextStyle(color: Colors.grey),
              )
            else
              ...items.map(
                (id) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(id),
                  trailing: TextButton(
                    onPressed: () => onRemove(id),
                    child: Text(removeLabel),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
