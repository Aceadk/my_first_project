import 'package:flutter/material.dart';
import 'package:crushhour/design_system/widgets/crush_avatar.dart';
import '../widget_showcase.dart';

/// Showcase for avatar widgets.
class AvatarsShowcase extends StatelessWidget {
  const AvatarsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShowcaseSection(
          title: 'CrushAvatar',
          subtitle: 'Profile avatar with status indicators',
        ),
        WidgetVariants(
          title: 'Avatar Sizes',
          description: 'Different size options for various contexts',
          variants: [
            WidgetVariant(
              label: 'Small (32)',
              child: CrushAvatar(
                imageUrl: null,
                name: 'Jane Doe',
                size: 32,
              ),
            ),
            WidgetVariant(
              label: 'Medium (48)',
              child: CrushAvatar(
                imageUrl: null,
                name: 'Jane Doe',
                size: 48,
              ),
            ),
            WidgetVariant(
              label: 'Large (64)',
              child: CrushAvatar(
                imageUrl: null,
                name: 'Jane Doe',
                size: 64,
              ),
            ),
            WidgetVariant(
              label: 'XLarge (96)',
              child: CrushAvatar(
                imageUrl: null,
                name: 'Jane Doe',
                size: 96,
              ),
            ),
          ],
        ),
        WidgetShowcase(
          title: 'With Online Indicator',
          description: 'Shows green dot when user is online',
          codeExample: '''
CrushAvatar(
  imageUrl: user.photoUrl,
  name: user.name,
  size: 64,
  showOnlineIndicator: true,
  isOnline: user.isOnline,
)''',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrushAvatar(
                imageUrl: null,
                name: 'Online User',
                size: 64,
                showOnlineIndicator: true,
                isOnline: true,
              ),
              SizedBox(width: 24),
              CrushAvatar(
                imageUrl: null,
                name: 'Offline User',
                size: 64,
                showOnlineIndicator: true,
                isOnline: false,
              ),
            ],
          ),
        ),
        WidgetShowcase(
          title: 'With Verified Badge',
          description: 'Shows checkmark for verified users',
          codeExample: '''
CrushAvatar(
  imageUrl: user.photoUrl,
  name: user.name,
  size: 64,
  showVerifiedBadge: true,
  isVerified: true,
)''',
          child: CrushAvatar(
            imageUrl: null,
            name: 'Verified User',
            size: 64,
            showVerifiedBadge: true,
            isVerified: true,
          ),
        ),
        WidgetShowcase(
          title: 'Initials Fallback',
          description: 'Shows initials when no image is available',
          codeExample: '''
CrushAvatar(
  imageUrl: null, // No image
  name: 'John Smith', // Shows "JS"
  size: 56,
)''',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrushAvatar(imageUrl: null, name: 'John Smith', size: 56),
              SizedBox(width: 12),
              CrushAvatar(imageUrl: null, name: 'Mary Jane', size: 56),
              SizedBox(width: 12),
              CrushAvatar(imageUrl: null, name: 'Alex', size: 56),
            ],
          ),
        ),
        ShowcaseSection(
          title: 'CrushAvatarStack',
          subtitle: 'Display multiple avatars in a row',
        ),
        WidgetShowcase(
          title: 'Avatar Stack',
          description: 'Overlapping avatars with overflow count',
          codeExample: '''
CrushAvatarStack(
  imageUrls: users.map((u) => u.photoUrl).toList(),
  maxVisible: 3,
  avatarSize: 40,
)''',
          child: CrushAvatarStack(
            imageUrls: [null, null, null, null, null],
            maxVisible: 3,
            avatarSize: 40,
          ),
        ),
      ],
    );
  }
}
