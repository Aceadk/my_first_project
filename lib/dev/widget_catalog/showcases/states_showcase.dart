import 'package:flutter/material.dart';
import 'package:crushhour/design_system/widgets/crush_empty_state.dart';
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
        const ShowcaseSection(
          title: 'CrushEmptyState',
          subtitle: 'Empty state displays for various scenarios',
        ),
        WidgetShowcase(
          title: 'No Matches',
          description: 'Shown when user has no matches yet',
          codeExample: '''
CrushEmptyState.noMatches(
  onKeepSwiping: () => navigateToDeck(),
)''',
          child: SizedBox(
            height: 280,
            child: CrushEmptyState.noMatches(
              onKeepSwiping: () {},
            ),
          ),
        ),
        WidgetShowcase(
          title: 'No Messages',
          description: 'Shown when chat list is empty',
          codeExample: '''
CrushEmptyState.noMessages(
  onFindMatches: () => navigateToDeck(),
)''',
          child: SizedBox(
            height: 250,
            child: CrushEmptyState.noMessages(
              onFindMatches: () {},
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Connection Error',
          description: 'Shown when network request fails',
          codeExample: '''
CrushEmptyState.connectionError(
  onRetry: () => reload(),
  message: 'Custom error message',
)''',
          child: SizedBox(
            height: 250,
            child: CrushEmptyState.connectionError(
              onRetry: () {},
              message: 'Check your connection and try again.',
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Custom Empty State',
          description: 'Build your own empty state',
          codeExample: '''
CrushEmptyState(
  icon: Icons.star_border,
  title: 'Custom Title',
  subtitle: 'Your custom message here.',
  actionLabel: 'Primary Action',
  onAction: () {},
)''',
          child: SizedBox(
            height: 250,
            child: CrushEmptyState(
              icon: Icons.star_border,
              title: 'Custom Title',
              subtitle: 'You can customize icon, title, subtitle, and actions.',
              actionLabel: 'Primary Action',
              onAction: () {},
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'LoadingOverlay',
          subtitle: 'Overlay loading indicator on content',
        ),
        WidgetShowcase(
          title: 'Loading Overlay',
          description: 'Tap to toggle loading state',
          codeExample: '''
LoadingOverlay(
  isLoading: state.isLoading,
  message: 'Saving...',
  child: YourContent(),
)''',
          child: GestureDetector(
            onTap: () {
              setState(() => _isLoading = !_isLoading);
            },
            child: SizedBox(
              height: 200,
              child: LoadingOverlay(
                isLoading: _isLoading,
                message: 'Loading...',
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
        const ShowcaseSection(
          title: 'ErrorBanner',
          subtitle: 'Dismissible error message banner',
        ),
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
  message: 'Persistent error message.',
)''',
          child: ErrorBanner(
            message: 'This error cannot be dismissed.',
          ),
        ),
        const ShowcaseSection(
          title: 'Progress Indicators',
          subtitle: 'Standard Flutter loading indicators',
        ),
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
              child: SizedBox(
                width: 120,
                child: LinearProgressIndicator(),
              ),
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
