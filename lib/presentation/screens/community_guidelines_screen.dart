import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community guidelines')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Text(
                  'Our promise',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'We want Crush to feel respectful, welcoming, and safe. '
                  'Please follow these guidelines so everyone can connect confidently. '
                  'Violations may lead to warnings, temporary restrictions, or removal.',
                ),
                SizedBox(height: 16),
                _Bullet('Be yourself. Use your real photos and information.'),
                _Bullet(
                  'Be kind. No harassment, hate speech, or bullying of any kind.',
                ),
                _Bullet(
                  'Keep it clean. Do not share explicit or illegal content on your profile or in messages.',
                ),
                _Bullet(
                  'Respect boundaries. Stop contacting people who ask you to stop.',
                ),
                _Bullet(
                  'Protect privacy. Never share someone else’s private info or your own sensitive data.',
                ),
                _Bullet(
                  'Report and block. If you feel unsafe or see something off, report and block the user.',
                ),
                _Bullet(
                  'No impersonation. Do not claim to be someone you are not or share altered documents.',
                ),
                SizedBox(height: 16),
                Text(
                  'Safety basics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _Bullet(
                  'Meet in public places first, share your tiers with a trusted friend, and arrange your own transportation.',
                ),
                _Bullet(
                  'Keep conversations in Crush until you feel comfortable—never send money or verification codes.',
                ),
                _Bullet(
                  'Look for verification badges on profiles and report anyone who pressures you or ignores your boundaries.',
                ),
                SizedBox(height: 16),
                Text(
                  'What happens when you report?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Our team reviews reports and may restrict or remove accounts that violate these guidelines. '
                  'Reporting is anonymous to the person you reported.',
                ),
                SizedBox(height: 16),
                Text(
                  'Need help?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'If you feel in immediate danger, contact local authorities. '
                  'For account questions, reach out to support through the Help & support section.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
