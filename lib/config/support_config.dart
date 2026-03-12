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
      title: 'Matches & Discovery',
      description: 'Learn how matching works',
      icon: 'favorite',
      url: '$helpCenterBaseUrl/matching',
    ),
    SupportCategory(
      id: 'messaging',
      title: 'Messages & Chat',
      description: 'Messaging tips and troubleshooting',
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
      question: 'How do I get more matches?',
      answer:
          'Complete your profile with clear photos, a short bio, and updated interests. Widen distance and age filters, stay active daily, and use Super Likes on profiles you are most interested in.',
      category: 'matching',
    ),
    FaqItem(
      question: 'Why am I not seeing new profiles?',
      answer:
          'This usually happens when your discovery filters are too strict or you have already swiped through nearby profiles. Expand your filters, verify location permissions are enabled, and check back after the feed refreshes.',
      category: 'matching',
    ),
    FaqItem(
      question: 'What is a Super Like?',
      answer:
          'A Super Like lets someone know you are especially interested before you match. Free tiers have limited Super Likes, while Plus includes more depending on your tier.',
      category: 'matching',
    ),
    FaqItem(
      question: 'How do I undo a swipe?',
      answer:
          'Use Rewind in the discovery screen to undo your most recent swipe. Rewind availability depends on your current plan and daily limit.',
      category: 'matching',
    ),
    FaqItem(
      question: 'Why did I run out of likes?',
      answer:
          'Free users have a daily like limit. Your likes reset every 24 hours. Upgrade to Crush Plus for unlimited likes.',
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
      question: 'Why can\'t I send messages?',
      answer:
          'You can only send messages after a mutual match. Also confirm your internet connection is stable, your account is in good standing, and the chat has not been blocked or reported.',
      category: 'messaging',
    ),
    FaqItem(
      question: 'How do I know if someone read my message?',
      answer:
          'Read receipts show when the other person opens your message in chat. If no receipt appears, they may not have opened the conversation yet or read receipts are unavailable in your current context.',
      category: 'messaging',
    ),
    FaqItem(
      question: 'Can I unsend a message?',
      answer:
          'Yes. Long-press the message and choose the remove option. Messages can only be removed from your side if delivery or retention rules prevent full recall for both participants.',
      category: 'messaging',
    ),
    FaqItem(
      question: 'How do I report a conversation?',
      answer:
          'Open the chat, tap the menu in the top-right corner, and select Report conversation. Choose the reason and include details so the safety team can review quickly.',
      category: 'messaging',
    ),
    FaqItem(
      question: 'How does photo verification work?',
      answer:
          'We ask you to take a selfie matching a specific pose. Our system compares it to your profile photos to verify you\'re real.',
      category: 'account',
    ),
    FaqItem(
      question: 'What is Crush Plus?',
      answer:
          'Crush Plus is our premium subscription with unlimited likes, see who likes you, rewind, and more.',
      category: 'billing',
    ),
    FaqItem(
      question: 'The app keeps crashing. What should I do?',
      answer:
          'Update to the latest app version, restart your device, and clear app cache. If the issue continues, contact support with your device model and OS version.',
      category: 'technical',
    ),
    FaqItem(
      question: 'How can I contact a real support person?',
      answer:
          'Go to Help & Support > Email Us, choose your category, and send details. Our support team will reply from support@crushhour.app.',
      category: 'other',
    ),
  ];

  // ===========================================================================
  // CATEGORY ARTICLE CONTENT
  // ===========================================================================

  static const Map<String, SupportArticleContent> categoryArticles = {
    'account': SupportArticleContent(
      overview:
          'Use this guide for sign-in problems, verification, and account access recovery.',
      quickSteps: [
        'Confirm your email/phone is entered correctly and try password reset first.',
        'Check verification status in Profile > Settings > Verification.',
        'If locked out, contact support with account email and device details.',
      ],
      escalationHints: [
        'Repeated login failures after password reset.',
        'Verification is stuck for more than 24 hours.',
      ],
    ),
    'matching': SupportArticleContent(
      overview:
          'This article covers like limits, missing matches, and discovery preferences.',
      quickSteps: [
        'Review your discovery filters and expand strict preferences.',
        'Wait for daily like reset if free limit is reached.',
        'Restart app and refresh discovery feed if cards stop loading.',
      ],
      escalationHints: [
        'No new profiles appear for an extended period.',
        'Mutual matches disappear unexpectedly.',
      ],
    ),
    'messaging': SupportArticleContent(
      overview:
          'Troubleshoot delayed messages, notification gaps, and chat visibility issues.',
      quickSteps: [
        'Ensure you and the other user are matched before messaging.',
        'Check notification permissions and disable battery optimization for the app.',
        'Reconnect network and reopen chat to force message sync.',
      ],
      escalationHints: [
        'Messages remain undelivered on stable internet.',
        'Entire chat threads fail to load repeatedly.',
      ],
    ),
    'safety': SupportArticleContent(
      overview:
          'For harassment, impersonation, or urgent safety concerns, follow these steps immediately.',
      quickSteps: [
        'Block the user to stop further interaction immediately.',
        'Report the profile/chat with clear evidence and context.',
        'For emergency risk, contact local authorities first, then notify safety support.',
      ],
      escalationHints: [
        'Threats, extortion, or repeated harassment.',
        'Any risk involving minors or immediate harm.',
      ],
    ),
    'billing': SupportArticleContent(
      overview:
          'Find help for subscription renewals, cancellations, refunds, and payment failures.',
      quickSteps: [
        'Confirm your subscription status in App Store or Google Play billing settings.',
        'Cancel from the same store account used to purchase.',
        'If charged incorrectly, include purchase receipt/order ID in support email.',
      ],
      escalationHints: [
        'Duplicate or unexpected charges.',
        'Subscription active in store but features not unlocked in app.',
      ],
    ),
    'privacy': SupportArticleContent(
      overview:
          'Use this guide for data export, account deletion, and privacy controls.',
      quickSteps: [
        'Review privacy controls in account and profile settings.',
        'Submit data or deletion requests from Settings > Account actions.',
        'Allow processing time for export/deletion completion.',
      ],
      escalationHints: [
        'Data request remains pending beyond expected timeframe.',
        'Privacy settings do not save or reset unexpectedly.',
      ],
    ),
    'technical': SupportArticleContent(
      overview:
          'Resolve crashes, performance drops, and unexpected app behavior.',
      quickSteps: [
        'Update app to the latest version and restart your device.',
        'Ensure device storage is available and network is stable.',
        'Reproduce issue and capture exact steps for support.',
      ],
      escalationHints: [
        'Crash occurs on every launch.',
        'Feature fails consistently after reinstall/update.',
      ],
    ),
    'other': SupportArticleContent(
      overview:
          'For general questions, feature feedback, or requests not listed in other categories.',
      quickSteps: [
        'Check FAQ items for quick answers first.',
        'Use Email Us with clear context and expected outcome.',
        'Include screenshots when reporting confusing UX or bugs.',
      ],
      escalationHints: [
        'Business, legal, or partnership inquiry.',
        'Issue does not match any listed support category.',
      ],
    ),
  };

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
    final effectiveSubject = subject ?? 'Crush Support Request';

    final queryParams = <String, String>{'subject': effectiveSubject};
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
      switch (categoryId) {
        case 'guidelines':
          url = guidelinesUrl;
          break;
        case 'faq':
          url = faqUrl;
          break;
        default:
          final category = categoryById(categoryId);
          url = category.url;
      }
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
    buffer.writeln(
      'App Version: ${const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}',
    );
    buffer.writeln('Platform: ${defaultTargetPlatform.name}');

    return buffer.toString();
  }

  /// Resolve a support category by id with a safe fallback.
  static SupportCategory categoryById(String categoryId) {
    return categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => categories.last,
    );
  }

  /// Get FAQs for a category id, or all FAQs when no category is provided.
  static List<FaqItem> faqsForCategory([String? categoryId]) {
    if (categoryId == null) {
      return frequentlyAsked;
    }

    return frequentlyAsked.where((faq) => faq.category == categoryId).toList();
  }

  /// Get article content for a category id.
  static SupportArticleContent articleForCategory(String categoryId) {
    return categoryArticles[categoryId] ?? categoryArticles['other']!;
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
enum SupportPriority { normal, high, urgent }

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

/// Full support-article content attached to each category.
class SupportArticleContent {
  final String overview;
  final List<String> quickSteps;
  final List<String> escalationHints;

  const SupportArticleContent({
    required this.overview,
    required this.quickSteps,
    required this.escalationHints,
  });
}
