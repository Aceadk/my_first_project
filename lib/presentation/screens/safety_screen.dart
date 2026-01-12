import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & blocking')),
      body: BlocConsumer<SafetyCubit, SafetyState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) {
            showErrorSnackBar(context, error);
          }
        },
        builder: (context, state) {
          final cubit = context.read<SafetyCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SafetyEducationCard(),
              const SizedBox(height: 16),
              _Section(
                title: 'Blocked users',
                emptyText:
                    'People you block can’t see your profile, message, or call you.',
                items: state.blockedUsers.toList(),
                onRemove: (userId) => _unblock(
                  context,
                  cubit,
                  currentUserId,
                  userId,
                ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need to report someone?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Open their profile or chat, choose Report, and pick a reason. '
                    'We review reports to keep the community safe.',
                      ),
                      TextButton.icon(
                        onPressed: () {
                          context.push(CrushRoutes.safetyGuidelines);
                        },
                        icon: const Icon(Icons.policy),
                        label: const Text('Read community guidelines'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: currentUserId == null
                            ? null
                            : () => _showAppealDialog(
                                  context,
                                  cubit,
                                  currentUserId,
                                ),
                        icon: const Icon(Icons.gavel_outlined),
                        label: const Text('Submit an appeal'),
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

  Future<void> _unblock(
    BuildContext context,
    SafetyCubit cubit,
    String? currentUserId,
    String userId,
  ) async {
    if (currentUserId == null) {
      showErrorSnackBar(context, 'Sign in again to manage safety actions.');
      return;
    }
    await cubit.toggleBlock(
      userId,
      block: false,
      currentUserId: currentUserId,
    );
  }

  Future<void> _showAppealDialog(
    BuildContext context,
    SafetyCubit cubit,
    String currentUserId,
  ) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appeal a safety action'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Share why you are appealing'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (submitted == true) {
      final reason = controller.text.trim();
      if (reason.isEmpty) {
        showErrorSnackBar(context, 'Please add details for your appeal.');
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      await cubit.submitAppeal(
        userId: currentUserId,
        reason: reason,
        targetType: 'account',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Appeal submitted')),
      );
    }
  }
}

class _SafetyEducationCard extends StatelessWidget {
  const _SafetyEducationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Stay safe while you connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _SafetyTip(
              icon: Icons.place_outlined,
              text: 'Plan first meetups in busy public places and share details with a friend.',
            ),
            const _SafetyTip(
              icon: Icons.lock_outline,
              text: 'Keep chats in CrushHour until you trust someone. Never send money or codes.',
            ),
            const _SafetyTip(
              icon: Icons.verified_user_outlined,
              text: 'Look for verification badges and report profiles that feel fake or pushy.',
            ),
            const _SafetyTip(
              icon: Icons.flag_outlined,
              text:
                  'Use block or report if anyone crosses a boundary. We act on reports to protect the community.',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.push(CrushRoutes.safetyGuidelines);
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Review safety & community guidelines'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
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
