# TODO: User Profile — Frontend
**Priority:** P0-P1
**Estimated Effort:** 25-35 hours
**Dependencies:** TODO_RESPONSIVE_DESIGN.md
**Assigned:** AI + Developer

---

## PROF-FE-001: Implement Responsive Profile Layout for iPad/Tablet/Web
**Files:** `lib/features/profile/presentation/screens/profile_edit_screen.dart`, `profile_view_screen.dart`
**Description:** Profile edit and view screens have no responsive layout. On tablet, use two-column form layout (photo grid left, text fields right). On desktop, center content with max 800px.
**Acceptance Criteria:**
- [ ] iPad: Two-column layout — photos (left) + details (right)
- [ ] iPhone: Single-column scroll (current behavior)
- [ ] Max content width 800px on desktop/large iPad
- [ ] Form fields properly spaced for touch targets on all sizes
**Testing:** iPad Air portrait/landscape + iPad Pro 12.9" landscape.

---

## PROF-FE-002: Fix Photo Upload Flow on iPad
**Files:** `lib/features/profile/data/services/profile_media_service.dart`, `profile_media_screen.dart`
**Description:** Photo picker (image_picker) on iPad uses popover presentation. Verify it works correctly, doesn't crash, and handles iPad-specific presentation requirements (sourceRect for action sheets).
**Acceptance Criteria:**
- [ ] Camera picker works on iPad (front + rear cameras)
- [ ] Gallery picker works on iPad with popover presentation
- [ ] No crashes on iPad when dismissing picker
- [ ] Proper handling of iPad-only features (drag and drop from Files app)
**Testing:** Manual test on iPad Air with camera and gallery.

---

## PROF-FE-003: Implement Photo Grid with Adaptive Columns
**Files:** `lib/features/profile/presentation/screens/profile_media_screen.dart`
**Description:** Profile photo grid should adapt column count: 2 on phone, 3 on tablet, 4 on desktop. Use AdaptiveGrid from design system.
**Acceptance Criteria:**
- [ ] 2 columns on phone (<600px)
- [ ] 3 columns on tablet (600-1024px)
- [ ] 4 columns on desktop (>1024px)
- [ ] Drag-to-reorder works on all grid sizes
- [ ] Touch targets meet minimum 44x44pt
**Testing:** Visual check on iPhone, iPad portrait, iPad landscape.

---

## PROF-FE-004: Add EXIF Stripping from Uploaded Photos (CRITICAL PRIVACY)
**Files:** `lib/features/profile/data/services/profile_media_service.dart`
**Description:** Profile photos are uploaded with full EXIF metadata including GPS coordinates, device model, timestamps. This is a critical privacy vulnerability. Strip all EXIF before upload.
**Acceptance Criteria:**
- [ ] GPS coordinates stripped from all uploaded images
- [ ] Device model/software info stripped
- [ ] Camera settings stripped
- [ ] Orientation preserved (using image data, not EXIF orientation tag)
- [ ] Image quality maintained (re-encode at 85% JPEG quality)
**Testing:** Upload photo with known EXIF GPS → download from Firebase Storage → verify EXIF empty.

---

## PROF-FE-005: Profile Editing Forms — Keyboard and External Keyboard Support
**Files:** `lib/features/profile/presentation/screens/profile_edit_screen.dart`
**Description:** Profile edit form lacks proper FocusNode management, keyboard avoidance, and external keyboard support. On iPad with Magic Keyboard, Tab should move between fields.
**Acceptance Criteria:**
- [ ] Tab navigates between form fields in logical order
- [ ] Enter moves to next field (or submits on last field)
- [ ] Keyboard avoidance: form scrolls to show active field
- [ ] Keyboard dismiss on tap outside fields
- [ ] Text fields use TextFormField with validation
**Testing:** iPad with Magic Keyboard; test Tab order through all fields.

---

## PROF-FE-006: Add Image Dimension and File Size Validation
**Files:** `lib/features/profile/data/services/profile_media_service.dart`
**Description:** No validation on image dimensions or file size before upload. Users could upload 12000x9000px photos consuming storage and causing slow loads.
**Acceptance Criteria:**
- [ ] Maximum image dimensions: 4096x4096 (resize if larger)
- [ ] Maximum file size: 10MB per image (match storage rules)
- [ ] Minimum dimensions: 200x200 (reject tiny images)
- [ ] HEIC/HEIF converted to JPEG before upload
- [ ] Clear error message if validation fails
**Testing:** Unit test with oversized, tiny, and HEIC images.

---

## PROF-FE-007: Profile Completeness Meter Accessibility
**Files:** `lib/design_system/widgets/profile_completion.dart`
**Description:** Profile completeness meter needs semantic labels for screen readers. Announce completion percentage and what's missing.
**Acceptance Criteria:**
- [ ] Semantics: "Profile 75% complete. Missing: bio, 2 more photos"
- [ ] Progress bar has role: progressbar
- [ ] Completion changes announced as live region update
**Testing:** VoiceOver on iPhone.
