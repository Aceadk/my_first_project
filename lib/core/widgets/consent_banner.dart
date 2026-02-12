import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:crushhour/core/services/consent_service.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// A bottom sheet banner for GDPR/privacy consent on first launch.
///
/// Shows privacy policy and terms links, requires acceptance to continue.
class ConsentBanner extends StatelessWidget {
  const ConsentBanner({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (ConsentService.instance.hasConsent) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => ConsentBanner(
        onAccepted: () {
          ConsentService.instance.grantConsent();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy Matters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        'We use your data to provide matches, messaging, and '
                        'personalized recommendations. By continuing, you agree '
                        'to our ',
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: DsColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl('https://crushhour.app/privacy'),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: DsColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl('https://crushhour.app/terms'),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAccepted,
                child: const Text('I Agree'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
