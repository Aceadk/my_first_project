# Profile Frontend Audit — 2026-05-30

## Scope

- Completed `PROF-FE-001`, `PROF-FE-002`, and `PROF-FE-003`.
- Covered Flutter profile setup/edit/view/media widgets and the web profile edit/view/preview/media components in `/Users/ace/crush-web`.
- Kept backend contracts unchanged; changes are presentation, validation, and local media UX hardening only.

## Findings and Fixes

### Adaptive Profile Surfaces

- Added Flutter `ProfileAdaptiveLayoutMetrics` so profile setup, edit, view, and media widgets share the same phone/tablet/desktop content-width and tile-sizing rules.
- Profile setup now groups intro/media fields and detail sections into a two-column tablet/desktop layout when text scale allows; large text falls back to one column.
- Profile edit now uses the same profile-specific content width and side-panel metrics instead of a hardcoded non-mobile width.
- Profile view uses the shared content-width rules so iPad/tablet/desktop views do not stretch uncontrolled.
- Web profile edit now uses a `max-w-6xl` two-column layout with completion, verification, and photos in a side rail.
- Web profile view now uses a responsive profile side rail for completion/photos and a separate detail column.
- Web profile preview now has wider responsive bounds and accessible photo navigation controls.

### Media Upload, Crop, Picker, Reorder

- Flutter `ProfileMediaPicker` now provides a first-photo empty state, adaptive media tile sizes, horizontal drag reorder, explicit move earlier/later controls, and primary-photo retention when photos move.
- Flutter iPad source selection still uses anchored presentation and Android still uses a bottom sheet.
- Web `PhotoGridReorder` now validates allowed image types (`JPG`, `PNG`, `WebP`) and size (`10 MB`) before crop/upload.
- Web reorder now has stable item IDs, visible keyboard/tap move controls, remove labels, and helper/error copy.
- Web `PhotoCropModal` now resets state per image, reports crop failures inline, uses responsive modal sizing, and exports JPEG at quality 0.9.

### Completion Guidance and Validation Copy

- Added Flutter `ProfileCompletionGuidance` to turn completeness summaries into required and recommended actions.
- Flutter profile view/edit completion cards now show concrete next actions instead of only raw missing strings.
- Added web `buildProfileCompletionState` and profile-backed adapter for consistent required/recommended copy.
- Web profile edit blocks saving a visible profile until display name, one photo, 20-character bio, three interests, and city/country are present.
- Web edit form now shows explicit bio minimum and interest count guidance.

## Verification

- `flutter test test/features/profile/presentation/widgets/profile_media_picker_test.dart test/features/profile/presentation/widgets/profile_completion_guidance_test.dart test/features/profile/presentation/widgets/profile_adaptive_layout_test.dart test/features/profile/presentation/screens/profile_media_screen_test.dart test/features/profile/presentation/screens/profile_setup_screen_keyboard_overflow_test.dart` — passing.
- `flutter analyze lib/features/profile/presentation/widgets/profile_media_picker.dart lib/features/profile/presentation/widgets/profile_adaptive_layout.dart lib/features/profile/presentation/widgets/profile_completion_guidance.dart lib/features/profile/presentation/screens/profile_setup_screen.dart lib/features/profile/presentation/screens/profile_view_screen.dart lib/features/profile/presentation/screens/profile_edit_screen.dart test/features/profile/presentation/widgets/profile_media_picker_test.dart test/features/profile/presentation/widgets/profile_completion_guidance_test.dart test/features/profile/presentation/widgets/profile_adaptive_layout_test.dart` — no issues.
- `pnpm --filter @crush/web test src/components/profile/__tests__/profile-completion.test.ts` — 3 passing.
- `pnpm --filter @crush/web typecheck` — clean.
- `pnpm --filter @crush/web lint` — 0 errors, 35 pre-existing warnings outside this slice.

## Manual Release-Gate Checks

- iOS and iPad physical picker/camera/crop smoke checks.
- Android camera/gallery picker and crop/upload smoke checks.
- Desktop Chrome/Safari/Firefox web upload/crop/reorder smoke checks.
- Large-text and screen-reader spot checks on the profile edit and setup forms.
