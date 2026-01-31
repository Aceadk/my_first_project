import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crushhour/config/legal_config.dart';
import 'package:crushhour/design_system/design_system.dart';

/// Terms of Service screen required for App Store compliance.
/// Displays the legal terms and conditions for using the app.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const String supportEmail = LegalConfig.legalEmail;
  static const String lastUpdated = LegalConfig.termsOfServiceLastUpdated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(DsSpacing.lg),
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
          const SizedBox(height: DsSpacing.lg),
          Text(
            'Terms of Service',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            'Welcome to CrushHour! These Terms of Service ("Terms") govern your use '
            'of the CrushHour mobile application ("App" or "Service") operated by '
            'CrushHour Inc. ("we", "us", or "our"). By accessing or using our App, '
            'you agree to be bound by these Terms.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: DsSpacing.xxl),

          // Eligibility
          const _SectionHeader('1. Eligibility'),
          const Text(
            'To use CrushHour, you must:',
          ),
          const SizedBox(height: DsSpacing.sm),
          const _Bullet('Be at least 18 years of age'),
          const _Bullet(
              'Be legally permitted to use the Service under applicable laws'),
          const _Bullet(
              'Not be prohibited from receiving services under applicable laws'),
          const _Bullet('Not have been previously banned from the Service'),
          const _Bullet('Not be a registered sex offender'),
          const SizedBox(height: DsSpacing.sm),
          Text(
            'By creating an account, you represent and warrant that you meet all '
            'eligibility requirements.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: DsSpacing.xxl),

          // Account Registration
          const _SectionHeader('2. Account Registration'),
          const Text(
            'To use certain features, you must register for an account. You agree to:',
          ),
          const SizedBox(height: DsSpacing.sm),
          const _Bullet('Provide accurate, current, and complete information'),
          const _Bullet(
              'Maintain and update your information to keep it accurate'),
          const _Bullet('Keep your login credentials secure and confidential'),
          const _Bullet(
              'Notify us immediately of any unauthorized account access'),
          const _Bullet('Be responsible for all activities under your account'),
          const SizedBox(height: DsSpacing.xxl),

          // Community Guidelines
          const _SectionHeader('3. Community Guidelines'),
          const Text(
            'You agree to follow our Community Guidelines and not to:',
          ),
          const SizedBox(height: DsSpacing.sm),
          const _Bullet('Post false, misleading, or deceptive content'),
          const _Bullet('Harass, bully, stalk, or intimidate any person'),
          const _Bullet('Use hate speech or discriminatory language'),
          const _Bullet('Share explicit, obscene, or illegal content'),
          const _Bullet('Spam, solicit, or advertise without permission'),
          const _Bullet(
              'Impersonate another person or misrepresent your identity'),
          const _Bullet('Share others\' private information without consent'),
          const _Bullet('Use the Service for illegal purposes'),
          const _Bullet('Attempt to hack, disrupt, or damage the Service'),
          const _Bullet('Create multiple accounts or evade bans'),
          const SizedBox(height: DsSpacing.xxl),

          // Content Ownership
          const _SectionHeader('4. Content Ownership'),
          const _SubHeader('Your Content'),
          const Text(
            'You retain ownership of content you submit ("User Content"). By posting '
            'User Content, you grant us a non-exclusive, worldwide, royalty-free license '
            'to use, display, reproduce, and distribute your content in connection with '
            'the Service.',
          ),
          const SizedBox(height: DsSpacing.md),
          const _SubHeader('Our Content'),
          const Text(
            'All other content on the Service, including text, graphics, logos, '
            'and software, is owned by us or our licensors and protected by '
            'intellectual property laws. You may not copy, modify, or distribute '
            'our content without permission.',
          ),
          const SizedBox(height: DsSpacing.xxl),

          // Subscriptions and Payments
          const _SectionHeader('5. Subscriptions and Payments'),
          const Text(
            'CrushHour offers free and premium subscription options:',
          ),
          const SizedBox(height: DsSpacing.sm),
          const _Bullet('Subscriptions automatically renew unless cancelled'),
          const _Bullet(
              'Cancel at least 24 hours before renewal to avoid charges'),
          const _Bullet('Manage subscriptions through your app store account'),
          const _Bullet('Refunds are subject to app store policies'),
          const _Bullet('We may change pricing with reasonable notice'),
          const SizedBox(height: 8),
          const Text(
            'In-app purchases are processed by Apple App Store or Google Play Store. '
            'Please review their terms for payment and refund policies.',
          ),
          const SizedBox(height: 24),

          // Safety and Interactions
          const _SectionHeader('6. Safety and Interactions'),
          const Text(
            'CrushHour is a platform for connecting people. We do not:',
          ),
          const SizedBox(height: 8),
          const _Bullet('Conduct background checks on users'),
          const _Bullet('Verify all information provided by users'),
          const _Bullet('Guarantee the behavior of any user'),
          const _Bullet('Bear responsibility for user interactions offline'),
          const SizedBox(height: 8),
          const Text(
            'You are solely responsible for your interactions with other users. '
            'Exercise caution and use common sense when meeting people in person.',
          ),
          const SizedBox(height: 24),

          // Disclaimer of Warranties
          const _SectionHeader('7. Disclaimer of Warranties'),
          const Text(
            'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES '
            'OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE SERVICE '
            'WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE, OR THAT DEFECTS WILL '
            'BE CORRECTED. YOUR USE OF THE SERVICE IS AT YOUR OWN RISK.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Limitation of Liability
          const _SectionHeader('8. Limitation of Liability'),
          const Text(
            'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR '
            'ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, '
            'INCLUDING LOSS OF PROFITS, DATA, OR GOODWILL, ARISING FROM YOUR USE '
            'OF THE SERVICE. OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU '
            'PAID US IN THE PAST 12 MONTHS.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Indemnification
          const _SectionHeader('9. Indemnification'),
          const Text(
            'You agree to indemnify and hold harmless CrushHour and its officers, '
            'directors, employees, and agents from any claims, damages, losses, '
            'or expenses arising from your use of the Service, violation of these '
            'Terms, or infringement of any third-party rights.',
          ),
          const SizedBox(height: 24),

          // Termination
          const _SectionHeader('10. Termination'),
          const Text(
            'We may suspend or terminate your account at any time, with or without '
            'cause or notice. You may delete your account at any time through the '
            'app settings. Upon termination:',
          ),
          const SizedBox(height: 8),
          const _Bullet('Your right to use the Service immediately ceases'),
          const _Bullet(
              'We may delete your account data after the retention period'),
          const _Bullet(
              'Provisions that should survive termination will remain in effect'),
          const SizedBox(height: 24),

          // Dispute Resolution
          const _SectionHeader('11. Dispute Resolution'),
          const Text(
            'Any disputes arising from these Terms or your use of the Service will '
            'be resolved through binding arbitration, except that either party may '
            'seek injunctive relief in court. You waive any right to participate in '
            'a class action lawsuit or class-wide arbitration.',
          ),
          const SizedBox(height: 24),

          // Governing Law
          const _SectionHeader('12. Governing Law'),
          const Text(
            'These Terms are governed by the laws of the State of California, USA, '
            'without regard to conflict of law principles. Any legal proceedings '
            'must be brought in the courts located in San Francisco, California.',
          ),
          const SizedBox(height: 24),

          // Changes to Terms
          const _SectionHeader('13. Changes to Terms'),
          const Text(
            'We may modify these Terms at any time. We will notify you of material '
            'changes through the app or by email. Your continued use of the Service '
            'after changes take effect constitutes acceptance of the new Terms.',
          ),
          const SizedBox(height: 24),

          // Severability
          const _SectionHeader('14. Severability'),
          const Text(
            'If any provision of these Terms is found to be unenforceable, the '
            'remaining provisions will continue in full force and effect.',
          ),
          const SizedBox(height: 24),

          // Contact Us
          const _SectionHeader('15. Contact Us'),
          const Text(
            'If you have questions about these Terms of Service, please contact us:',
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
          const SizedBox(height: 16),
          const Text(
            'By using CrushHour, you acknowledge that you have read, understood, '
            'and agree to be bound by these Terms of Service.',
            style: TextStyle(fontWeight: FontWeight.w500),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleLarge,
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xs, top: DsSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleMedium,
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
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
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
