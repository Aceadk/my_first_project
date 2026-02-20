import 'package:flutter/material.dart';
import 'package:crushhour/design_system/widgets/glass_text_field.dart';
import 'package:crushhour/design_system/widgets/otp_input.dart';
import '../widget_showcase.dart';

/// Showcase for input widgets.
class InputsShowcase extends StatefulWidget {
  const InputsShowcase({super.key});

  @override
  State<InputsShowcase> createState() => _InputsShowcaseState();
}

class _InputsShowcaseState extends State<InputsShowcase> {
  final _textController = TextEditingController();
  final _passwordController = TextEditingController();
  String _otpValue = '';

  @override
  void dispose() {
    _textController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShowcaseSection(
          title: 'GlassTextField',
          subtitle: 'Customizable text input field',
        ),
        WidgetShowcase(
          title: 'Basic Text Field',
          description: 'Standard text input with label and hint',
          codeExample: '''
GlassTextField(
  controller: _controller,
  label: 'Username',
  hintText: 'Enter your username',
)''',
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              controller: _textController,
              label: 'Username',
              hintText: 'Enter your username',
            ),
          ),
        ),
        WidgetShowcase(
          title: 'Password Field',
          description: 'Obscured text for sensitive input',
          codeExample: '''
GlassTextField(
  controller: _controller,
  label: 'Password',
  obscureText: true,
)''',
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              obscureText: true,
            ),
          ),
        ),
        const WidgetShowcase(
          title: 'With Helper Text',
          description: 'Additional context below the field',
          codeExample: '''
GlassTextField(
  label: 'Email',
  hintText: 'you@example.com',
  helperText: 'We\\'ll never share your email',
  keyboardType: TextInputType.emailAddress,
)''',
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              label: 'Email',
              hintText: 'you@example.com',
              helperText: "We'll never share your email",
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
        const WidgetShowcase(
          title: 'With Error',
          description: 'Shows validation error message',
          codeExample: '''
GlassTextField(
  label: 'Email',
  errorText: 'Please enter a valid email address',
)''',
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              label: 'Email',
              hintText: 'you@example.com',
              errorText: 'Please enter a valid email address',
            ),
          ),
        ),
        const WidgetShowcase(
          title: 'Multiline',
          description: 'For longer text input like bios',
          codeExample: '''
GlassTextField(
  label: 'Bio',
  hintText: 'Tell us about yourself...',
  maxLines: 4,
  minLines: 2,
)''',
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              label: 'Bio',
              hintText: 'Tell us about yourself...',
              maxLines: 4,
              minLines: 2,
            ),
          ),
        ),
        const ShowcaseSection(
          title: 'OTP Input',
          subtitle: 'Specialized input for verification codes',
        ),
        WidgetShowcase(
          title: 'OTP Input (6 digits)',
          description: 'Auto-advancing OTP/PIN entry field',
          codeExample: '''
OtpInput(
  onCompleted: (code) {
    // Verify the code
    print('Code entered: \$code');
  },
)''',
          child: Column(
            children: [
              OtpInput(
                onCompleted: (code) {
                  setState(() => _otpValue = code);
                },
              ),
              const SizedBox(height: 12),
              Text(
                _otpValue.isEmpty ? 'Enter code above' : 'Entered: $_otpValue',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'Custom Length OTP',
          description: '4-digit PIN input',
          codeExample: '''
OtpInput(
  length: 4,
  onCompleted: (code) {},
)''',
          child: OtpInput(length: 4, onCompleted: (code) {}),
        ),
      ],
    );
  }
}
