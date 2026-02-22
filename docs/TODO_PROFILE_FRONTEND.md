# User Profile Frontend Module
Priority: P0-P1
Scope: Profile creation, editing, photo upload/management, verification, preferences, settings.

## Action Items
### PROF-FE-001: Implement responsive profile card layout for phone/tablet/web
- **Description**: Ensure profile cards adapt to iPad screens without spanning the entire 13" width. Use LayoutBuilder.
- **Affected Files**: lib/features/profile/presentation/widgets/profile_card.dart
- **Acceptance Criteria**: Constraints apply max-width of 600px, centering the profile card on wide screens.
- **Testing Requirements**: Widget test verifying width constraints. Visual test on iPad Pro simulator.

### PROF-FE-002: Audit and fix photo upload flow on all platforms (including iPad camera/gallery picker)
- **Description**: image_picker must provide a source rect on iPad to prevent popover crashes.
- **Affected Files**: lib/features/profile/presentation/widgets/profile_media_picker.dart
- **Acceptance Criteria**: Tapping Upload Photo on iPad opens a properly anchored popover or modal.
- **Testing Requirements**: Manual test uploading photos on iPad simulator.

### PROF-FE-003: Implement proper photo grid with adaptive columns
- **Description**: The photo grid displays 2 columns on phones, but should dynamically switch to 3-4 on iPads.
- **Affected Files**: lib/features/profile/presentation/screens/profile_media_screen.dart
- **Acceptance Criteria**: Use SliverGridDelegateWithMaxCrossAxisExtent or MediaQuery to define columns based on width.
- **Testing Requirements**: Golden tests for phone, small tablet, and large tablet.

### PROF-FE-004: Add EXIF stripping from uploaded photos for privacy
- **Description**: Uploaded JPEGs must have location metadata stripped prior to network transmission.
- **Affected Files**: lib/core/utils/image_utils.dart or similar.
- **Acceptance Criteria**: Processed images contain no GPS or device identifying data.
- **Testing Requirements**: Test image upload with a fabricated image containing EXIF data and assert it is removed.