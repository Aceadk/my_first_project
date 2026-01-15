import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy screen required for App Store compliance.
/// Displays how user data is collected, used, and protected.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String supportEmail = 'privacy@crushhour.app';
  static const String lastUpdated = 'January 2026';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Privacy Matters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'CrushHour ("we", "our", or "us") is committed to protecting your privacy. '
            'This Privacy Policy explains how we collect, use, disclose, and safeguard '
            'your information when you use our mobile application.',
          ),
          const SizedBox(height: 24),

          // Information We Collect
          const _SectionHeader('Information We Collect'),
          const _SubHeader('Personal Information You Provide'),
          const _Bullet('Account information: name, email, phone number, date of birth'),
          const _Bullet('Profile information: photos, bio, interests, preferences'),
          const _Bullet('Verification data: ID documents for identity verification'),
          const _Bullet('Communications: messages, reports, and support requests'),
          const _Bullet('Payment information: processed securely through third-party providers'),
          const SizedBox(height: 12),
          const _SubHeader('Information Collected Automatically'),
          const _Bullet('Location data: to show you nearby users (with your permission)'),
          const _Bullet('Device information: device type, OS version, unique identifiers'),
          const _Bullet('Usage data: app interactions, features used, time spent'),
          const _Bullet('Log data: IP address, access times, crash reports'),
          const SizedBox(height: 24),

          // How We Use Your Information
          const _SectionHeader('How We Use Your Information'),
          const _Bullet('Provide and improve our matchmaking services'),
          const _Bullet('Show you relevant profiles based on your preferences'),
          const _Bullet('Process your transactions and manage your account'),
          const _Bullet('Send you service updates and promotional messages'),
          const _Bullet('Verify your identity and prevent fraud'),
          const _Bullet('Respond to your requests and provide customer support'),
          const _Bullet('Analyze usage patterns to improve user experience'),
          const _Bullet('Comply with legal obligations'),
          const SizedBox(height: 24),

          // Sharing Your Information
          const _SectionHeader('Sharing Your Information'),
          const Text(
            'We do not sell your personal information. We may share your information with:',
          ),
          const SizedBox(height: 8),
          const _Bullet('Other users: Your profile information is visible to potential matches'),
          const _Bullet('Service providers: Companies that help us operate (hosting, analytics, payments)'),
          const _Bullet('Legal authorities: When required by law or to protect our rights'),
          const _Bullet('Business transfers: In case of merger, acquisition, or sale of assets'),
          const SizedBox(height: 24),

          // Data Retention
          const _SectionHeader('Data Retention'),
          const Text(
            'We retain your personal information for as long as your account is active '
            'or as needed to provide you services. After account deletion, we retain '
            'certain information for up to 14 days for recovery purposes, after which '
            'it is permanently deleted. Some data may be retained longer for legal compliance.',
          ),
          const SizedBox(height: 24),

          // Your Rights and Choices
          const _SectionHeader('Your Rights and Choices'),
          const _Bullet('Access: Request a copy of your personal data'),
          const _Bullet('Correction: Update or correct inaccurate information'),
          const _Bullet('Deletion: Request deletion of your account and data'),
          const _Bullet('Export: Download your data in a portable format'),
          const _Bullet('Opt-out: Unsubscribe from marketing communications'),
          const _Bullet('Location: Control location sharing through device settings'),
          const SizedBox(height: 8),
          const Text(
            'To exercise these rights, go to Settings > Account > Account Actions, '
            'or contact us at the email below.',
          ),
          const SizedBox(height: 24),

          // Data Security
          const _SectionHeader('Data Security'),
          const Text(
            'We implement industry-standard security measures to protect your information, including:',
          ),
          const SizedBox(height: 8),
          const _Bullet('Encryption of data in transit and at rest'),
          const _Bullet('Secure authentication with phone/email verification'),
          const _Bullet('Regular security audits and monitoring'),
          const _Bullet('Access controls limiting employee access to user data'),
          const SizedBox(height: 8),
          const Text(
            'While we strive to protect your information, no method of transmission '
            'over the internet is 100% secure.',
          ),
          const SizedBox(height: 24),

          // Children's Privacy
          const _SectionHeader("Children's Privacy"),
          const Text(
            'CrushHour is intended for users 18 years of age and older. We do not '
            'knowingly collect information from anyone under 18. If we learn that '
            'we have collected personal information from a child under 18, we will '
            'delete that information immediately.',
          ),
          const SizedBox(height: 24),

          // International Transfers
          const _SectionHeader('International Data Transfers'),
          const Text(
            'Your information may be transferred to and processed in countries '
            'other than your own. We ensure appropriate safeguards are in place '
            'to protect your information in compliance with applicable data protection laws.',
          ),
          const SizedBox(height: 24),

          // California Privacy Rights (CCPA)
          const _SectionHeader('California Privacy Rights'),
          const Text(
            'California residents have additional rights under the CCPA, including '
            'the right to know what personal information we collect, the right to '
            'request deletion, and the right to opt-out of the sale of personal '
            'information. We do not sell personal information.',
          ),
          const SizedBox(height: 24),

          // European Privacy Rights (GDPR)
          const _SectionHeader('European Privacy Rights'),
          const Text(
            'Users in the European Economic Area (EEA) have rights under the GDPR, '
            'including access, rectification, erasure, restriction, portability, '
            'and the right to object to processing. You may also lodge a complaint '
            'with your local data protection authority.',
          ),
          const SizedBox(height: 24),

          // Changes to This Policy
          const _SectionHeader('Changes to This Policy'),
          const Text(
            'We may update this Privacy Policy from time to time. We will notify you '
            'of any material changes by posting the new policy in the app and updating '
            'the "Last updated" date. Your continued use of the app after changes '
            'constitutes acceptance of the updated policy.',
          ),
          const SizedBox(height: 24),

          // Contact Us
          const _SectionHeader('Contact Us'),
          const Text(
            'If you have questions about this Privacy Policy or our data practices, '
            'please contact us:',
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _launchEmail(context),
            child: Text(
              supportEmail,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
