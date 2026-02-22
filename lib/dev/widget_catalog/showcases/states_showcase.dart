import 'package:crushhour/design_system/widgets/empty_state.dart';
import 'package:flutter/material.dart';

import 'package:crushhour/design_system/widgets/loading_overlay.dart';
import 'package:crushhour/design_system/widgets/error_banner.dart';
import '../widget_showcase.dart';

/// Showcase for state widgets (loading, empty, error).
class StatesShowcase extends StatefulWidget {
  const StatesShowcase({super.key});

  @override
  State<StatesShowcase> createState() => _StatesShowcaseState();
}

class _StatesShowcaseState extends State<StatesShowcase> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(title: 'DsEmptyState'),
        WidgetShowcase(
          title: 'No Matches',
          description: 'Shown when user has no matches yet',
          codeExample: '''
EmptyStateNoMatches(
  onRefresh: () {},
)''',
          child: SizedBox(
            height: 280,
            child: EmptyStateNoMatches(onRefresh: () {}),
          ),
        ),
        WidgetShowcase(
          title: 'No Messages',
          description: 'Shown when chat list is empty',
          codeExample: '''
EmptyStateNoMessages(otherName: 'Someone')''',
          child: SizedBox(
            height: 250,
            child: EmptyStateNoMessages(otherName: 'Someone', onSendHi: () {}),
          ),
        ),
        WidgetShowcase(
          title: 'Connection Error',
          description: 'Shown when network request fails',
          codeExample: '''
EmptyStateError(
  onRetry: () => reload(),
)''',
          child: SizedBox(height: 250, child: EmptyStateError(onRetry: () {})),
        ),
        WidgetShowcase(
          title: 'Custom Empty State',
          description: 'Build your own empty state',
          codeExample: '''
DsEmptyState( 
  icon: Icons.star_border,
  title: 'Custom Title',
  actionLabel: 'Primary Action',
  onAction: () {},
)''',
          child: SizedBox(
            height: 250,
            child: DsEmptyState(
              icon: Icons.star_border,
              title: 'Custom Title',

              actionLabel: 'Primary Action',
              onAction: () {},
            ),
          ),
        ),
        const ShowcaseSection(title: 'LoadingOverlay'),
        WidgetShowcase(
          title: 'Loading Overlay',
          description: 'Tap to toggle loading state',
          codeExample: '''
LoadingOverlay(
  isLoading: state.isLoading,
  child: YourContent(),
)''',
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: () {
                setState(() => _isLoading = !_isLoading);
              },
              child: SizedBox(
                height: 200,
                child: LoadingOverlay(
                  isLoading: _isLoading,
                  child: Card(
                    child: Center(
                      child: Text(
                        _isLoading
                            ? 'Tap to hide loading'
                            : 'Tap to show loading',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const ShowcaseSection(title: 'ErrorBanner'),
        WidgetShowcase(
          title: 'Error Banner',
          description: 'Shows error message with optional dismiss',
          codeExample: '''
ErrorBanner(
  message: 'Something went wrong.',
  onDismiss: () => clearError(),
)''',
          child: ErrorBanner(
            message: 'Something went wrong. Please try again.',
            onDismiss: () {},
          ),
        ),
        const WidgetShowcase(
          title: 'Error Banner (No Dismiss)',
          description: 'Error banner without dismiss button',
          codeExample: '''
ErrorBanner(
  message: 'Unable to load data right now.',
)''',
          child: ErrorBanner(message: 'Unable to load data right now.'),
        ),
        const ShowcaseSection(title: 'Progress Indicators'),
        const WidgetVariants(
          title: 'Loading Indicators',
          description: 'Different loading indicator styles',
          variants: [
            WidgetVariant(
              label: 'Circular',
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
            ),
            WidgetVariant(
              label: 'Linear',
              child: SizedBox(width: 120, child: LinearProgressIndicator()),
            ),
            WidgetVariant(
              label: 'Adaptive',
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
