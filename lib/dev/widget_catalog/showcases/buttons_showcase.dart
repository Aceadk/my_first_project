import 'package:flutter/material.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import '../widget_showcase.dart';

/// Showcase for button widgets.
class ButtonsShowcase extends StatefulWidget {
  const ButtonsShowcase({super.key});

  @override
  State<ButtonsShowcase> createState() => _ButtonsShowcaseState();
}

class _ButtonsShowcaseState extends State<ButtonsShowcase> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(
          title: 'Primary Button',
          subtitle: 'Main action button with loading state support',
        ),
        WidgetShowcase(
          title: 'Default',
          description: 'Standard primary button for main actions',
          codeExample: '''
PrimaryButton(
  label: 'Continue',
  onPressed: () {
    // Handle action
  },
)''',
          child: PrimaryButton(
            label: 'Continue',
            onPressed: () {},
          ),
        ),
        WidgetShowcase(
          title: 'Loading State',
          description: 'Shows loading indicator while processing',
          codeExample: '''
PrimaryButton(
  label: 'Submit',
  loading: true,
  onPressed: () {},
)''',
          child: Column(
            children: [
              PrimaryButton(
                label: 'Submit',
                loading: _isLoading,
                onPressed: () {
                  setState(() => _isLoading = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _isLoading = false);
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to see loading state',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const WidgetShowcase(
          title: 'Disabled',
          description: 'Disabled state when action is not available',
          codeExample: '''
PrimaryButton(
  label: 'Disabled',
  onPressed: null, // Disabled when null
)''',
          child: PrimaryButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
        WidgetVariants(
          title: 'Button States',
          description: 'All button states at a glance',
          horizontal: false,
          variants: [
            WidgetVariant(
              label: 'Normal',
              child: PrimaryButton(label: 'Normal', onPressed: () {}),
            ),
            WidgetVariant(
              label: 'Loading',
              child: PrimaryButton(
                  label: 'Loading', loading: true, onPressed: () {}),
            ),
            const WidgetVariant(
              label: 'Disabled',
              child: PrimaryButton(label: 'Disabled', onPressed: null),
            ),
          ],
        ),
        const ShowcaseSection(
          title: 'Standard Flutter Buttons',
          subtitle: 'Built-in Material buttons for reference',
        ),
        WidgetVariants(
          title: 'Material Buttons',
          description: 'Standard button types available in Flutter',
          variants: [
            WidgetVariant(
              label: 'Elevated',
              child: ElevatedButton(
                  onPressed: () {}, child: const Text('Elevated')),
            ),
            WidgetVariant(
              label: 'Filled',
              child:
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
            ),
            WidgetVariant(
              label: 'Outlined',
              child: OutlinedButton(
                  onPressed: () {}, child: const Text('Outlined')),
            ),
            WidgetVariant(
              label: 'Text',
              child: TextButton(onPressed: () {}, child: const Text('Text')),
            ),
          ],
        ),
        WidgetVariants(
          title: 'Icon Buttons',
          description: 'Buttons with icons',
          variants: [
            WidgetVariant(
              label: 'Icon Only',
              child: IconButton(
                  onPressed: () {}, icon: const Icon(Icons.favorite)),
            ),
            WidgetVariant(
              label: 'With Label',
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ),
            WidgetVariant(
              label: 'FAB',
              child: FloatingActionButton.small(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
