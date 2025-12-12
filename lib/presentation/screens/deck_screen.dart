import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/discovery/discovery_bloc.dart';
import '../../logic/discovery/discovery_event.dart';
import '../../logic/discovery/discovery_state.dart';
import '../../data/services/prematch_service.dart';
import '../../core/ui/snackbar_utils.dart';
import '../widgets/swipe_card.dart';
import '../widgets/plus_feature_gate.dart';
import 'settings_screen.dart';

class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preMatchService = PreMatchService();
    final userId = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );

    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        }
      },
      builder: (context, state) {
        _requestDeckIfNeeded(context, userId, state);

        if (state.isLoading && state.deck.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.deck.isEmpty || state.currentIndex >= state.deck.length) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('CrushHour'),
              centerTitle: true,
            ),
            body: _buildOutOfPeople(context),
          );
        }

        final currentProfile = state.deck[state.currentIndex];

        return Scaffold(
          appBar: AppBar(
            title: const Text('CrushHour'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: SwipeCard(profile: currentProfile),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _circleButton(
                    icon: Icons.clear,
                    color: Colors.grey.shade300,
                    onTap: () {
                      if (userId == null) return;
                      context.read<DiscoveryBloc>().add(
                            DiscoverySwipedLeft(
                              userId: userId,
                              targetUserId: currentProfile.id,
                            ),
                          );
                    },
                  ),
                  _circleButton(
                    icon: Icons.message,
                    color: Colors.blueAccent,
                    onTap: () async {
                      if (userId == null) return;
                      await _showPreMatchDialog(
                        context: context,
                        preMatchService: preMatchService,
                        targetUserId: currentProfile.id,
                      );
                    },
                  ),
                  _circleButton(
                    icon: Icons.favorite,
                    color: Colors.pinkAccent,
                    onTap: () {
                      if (userId == null) return;
                      context.read<DiscoveryBloc>().add(
                            DiscoverySwipedRight(
                              userId: userId,
                              targetUserId: currentProfile.id,
                            ),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _requestDeckIfNeeded(
    BuildContext context,
    String? userId,
    DiscoveryState state,
  ) {
    if (userId == null) return;
    if (state.isLoading) return;
    if (state.deck.isNotEmpty) return;
    if (state.errorMessage != null) return;
    context.read<DiscoveryBloc>().add(DiscoveryDeckRequested(userId));
  }

  Widget _buildOutOfPeople(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 72),
            const SizedBox(height: 16),
            const Text(
              'You’re all caught up!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no more people nearby right now.\n'
              'You can adjust your filters or explore with Passport.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              child: const Text('Change filters'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: PlusFeatureGate(
                      onAllowed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Passport is coming soon in this build.'),
                          ),
                        );
                      },
                      child: const ListTile(
                        leading: Icon(Icons.flight_takeoff),
                        title: Text('Try Passport'),
                        subtitle: Text('Explore anywhere with CrushHour Plus'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Try Passport with Plus'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: CircleAvatar(
        backgroundColor: color,
        radius: 28,
        child: Icon(icon, color: Colors.black),
      ),
    );
  }

  Future<void> _showPreMatchDialog({
    required BuildContext context,
    required PreMatchService preMatchService,
    required String targetUserId,
  }) async {
    final controller = TextEditingController();

    final content = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send message request'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Say something nice…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (content == null || content.isEmpty) return;

    try {
      await preMatchService.sendPreMatchMessageRequest(
        targetUserId: targetUserId,
        content: content,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message request sent')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send message request. Try again.'),
        ),
      );
    }
  }
}
