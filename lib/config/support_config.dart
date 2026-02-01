import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Customer support configuration and utilities.
/// Integrates with help desk systems and provides in-app support features.
class SupportConfig {
  SupportConfig._();

  // ===========================================================================
  // CONTACT INFORMATION
  // ===========================================================================

  /// General support email
  static const String supportEmail = 'support@crushhour.app';

  /// Safety/emergency support email (faster response time)
  static const String safetyEmail = 'safety@crushhour.app';

  /// Technical support email
  static const String techSupportEmail = 'tech@crushhour.app';

  /// Billing/payment inquiries
  static const String billingEmail = 'billing@crushhour.app';

  // ===========================================================================
  // HELP CENTER URLs
  // ===========================================================================

  /// Base URL for help center
  static const String helpCenterBaseUrl = 'https://crushhour.app/help';

  /// FAQ page
  static const String faqUrl = '$helpCenterBaseUrl/faq';

  /// Account issues help
  static const String accountHelpUrl = '$helpCenterBaseUrl/account';

  /// Safety center
  static const String safetyCenterUrl = '$helpCenterBaseUrl/safety';

  /// Billing help
  static const String billingHelpUrl = '$helpCenterBaseUrl/billing';

  /// Report abuse
  static const String reportAbuseUrl = '$helpCenterBaseUrl/report';

  /// Community guidelines
  static const String guidelinesUrl = 'https://crushhour.app/guidelines';

  // ===========================================================================
  // HELP DESK INTEGRATION
  // ===========================================================================

  /// Zendesk/Freshdesk widget URL (if using embedded support)
  static const String helpDeskWidgetUrl = String.fromEnvironment(
    'HELP_DESK_WIDGET_URL',
    defaultValue: '',
  );

  /// Intercom App ID (if using Intercom)
  static const String intercomAppId = String.fromEnvironment(
    'INTERCOM_APP_ID',
    defaultValue: '',
  );

  /// Whether help desk widget is configured
  static bool get hasHelpDeskWidget => helpDeskWidgetUrl.isNotEmpty;

  /// Whether Intercom is configured
  static bool get hasIntercom => intercomAppId.isNotEmpty;

  // ===========================================================================
  // SUPPORT CATEGORIES
  // ===========================================================================

  static const List<SupportCategory> categories = [
    SupportCategory(
      id: 'account',
      title: 'Account Issues',
      description: 'Login problems, account recovery, verification',
      icon: 'account_circle',
      url: accountHelpUrl,
    ),
    SupportCategory(
      id: 'matching',
      title: 'Matching & Discovery',
      description: 'Swipe limits, match issues, discovery preferences',
      icon: 'favorite',
      url: '$helpCenterBaseUrl/matching',
    ),
    SupportCategory(
      id: 'messaging',
      title: 'Messaging',
      description: 'Chat issues, message delivery, notifications',
      icon: 'chat',
      url: '$helpCenterBaseUrl/messaging',
    ),
    SupportCategory(
      id: 'safety',
      title: 'Safety & Reporting',
      description: 'Report users, block, safety concerns',
      icon: 'shield',
      url: safetyCenterUrl,
      priority: SupportPriority.high,
    ),
    SupportCategory(
      id: 'billing',
      title: 'Billing & Subscription',
      description: 'Payment issues, cancel subscription, refunds',
      icon: 'credit_card',
      url: billingHelpUrl,
    ),
    SupportCategory(
      id: 'privacy',
      title: 'Privacy & Data',
      description: 'Data requests, account deletion, privacy settings',
      icon: 'privacy_tip',
      url: '$helpCenterBaseUrl/privacy',
    ),
    SupportCategory(
      id: 'technical',
      title: 'Technical Issues',
      description: 'App crashes, bugs, performance problems',
      icon: 'build',
      url: '$helpCenterBaseUrl/technical',
    ),
    SupportCategory(
      id: 'other',
      title: 'Other',
      description: 'General questions and feedback',
      icon: 'help',
      url: faqUrl,
    ),
  ];

  // ===========================================================================
  // FAQ ITEMS
  // ===========================================================================

  static const List<FaqItem> frequentlyAsked = [
    FaqItem(
      question: 'How do I verify my profile?',
      answer:
          'Go to your Profile > Settings > Verification. Follow the steps to take a selfie and complete photo verification.',
      category: 'account',
    ),
    FaqItem(
      question: 'Why did I run out of likes?',
      answer:
          'Free users have a daily like limit. Your likes reset every 24 hours. Upgrade to CrushHour Plus for unlimited likes.',
      category: 'matching',
    ),
    FaqItem(
      question: 'How do I cancel my subscription?',
      answer:
          'Subscriptions are managed through the App Store or Google Play. Go to your device settings to cancel.',
      category: 'billing',
    ),
    FaqItem(
      question: 'How do I delete my account?',
      answer:
          'Go to Settings > Account > Delete Account. This action is permanent and cannot be undone.',
      category: 'privacy',
    ),
    FaqItem(
      question: 'How do I report a user?',
      answer:
          'On their profile, tap the menu icon (three dots) and select "Report". Choose a reason and provide details.',
      category: 'safety',
    ),
    FaqItem(
      question: 'Why can\'t I see messages?',
      answer:
          'Messages are only available with mutual matches. If you sent a message request, wait for them to accept.',
      category: 'messaging',
    ),
    FaqItem(
      question: 'How does photo verification work?',
      answer:
          'We ask you to take a selfie matching a specific pose. Our system compares it to your profile photos to verify you\'re real.',
      category: 'account',
    ),
    FaqItem(
      question: 'What is CrushHour Plus?',
      answer:
          'CrushHour Plus is our premium subscription with unlimited likes, see who likes you, rewind, and more.',
      category: 'billing',
    ),
  ];

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Open support email composer
  static Future<void> openSupportEmail({
    String? subject,
    String? body,
    String? category,
  }) async {
    final email = category == 'safety' ? safetyEmail : supportEmail;
    final effectiveSubject = subject ?? 'CrushHour Support Request';

    final queryParams = <String, String>{
      'subject': effectiveSubject,
    };
    if (body != null) {
      queryParams['body'] = body;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: queryParams,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Open help center in browser
  static Future<void> openHelpCenter([String? categoryId]) async {
    String url = helpCenterBaseUrl;

    if (categoryId != null) {
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => categories.last,
      );
      url = category.url;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open safety center
  static Future<void> openSafetyCenter() async {
    final uri = Uri.parse(safetyCenterUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Generate support ticket email body with device info
  static String generateSupportBody({
    required String category,
    required String description,
    String? userId,
    String? deviceInfo,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('--- Support Request ---');
    buffer.writeln('Category: $category');
    buffer.writeln('');
    buffer.writeln('Description:');
    buffer.writeln(description);
    buffer.writeln('');
    buffer.writeln('--- Technical Info ---');
    if (userId != null) buffer.writeln('User ID: $userId');
    if (deviceInfo != null) buffer.writeln('Device: $deviceInfo');
    buffer.writeln('App Version: ${const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}');
    buffer.writeln('Platform: ${defaultTargetPlatform.name}');

    return buffer.toString();
  }
}

/// A support category for organizing help topics.
class SupportCategory {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String url;
  final SupportPriority priority;

  const SupportCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.url,
    this.priority = SupportPriority.normal,
  });
}

/// Priority level for support requests.
enum SupportPriority {
  normal,
  high,
  urgent,
}

/// A frequently asked question item.
class FaqItem {
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
