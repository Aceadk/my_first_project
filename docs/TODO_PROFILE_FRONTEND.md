# User Profile Frontend Module
Priority: P0-P1
Scope: Profile creation, editing, photo upload/management, verification, preferences, settings.

## Action Items
### PROF-FE-001: Implement responsive profile card layout for phone/tablet/web
- **Description**: Ensure profile cards adapt to iPad screens without spanning the entire 13" width. Use LayoutBuilder.
- **Affected Files**: lib/features/profile/presentation/widgets/profile_card.dart
- **Acceptance Criteria**: Constraints apply max-width of 600px, centering the profile card on wide screens.
- **Testing Requirements**: Widget test verifying width constraints. Visual test on iPad Pro simulator.