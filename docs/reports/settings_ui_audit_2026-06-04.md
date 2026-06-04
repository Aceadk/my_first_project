# Settings UI Audit - 2026-06-04

Scope: `SET-UI-001`–`SET-UI-003` from [`docs/TODO_SETTINGS_UI.md`](../TODO_SETTINGS_UI.md).

Surfaces reviewed: the 13 settings screens under
[`lib/features/settings/presentation/screens/`](../../lib/features/settings/presentation/screens/)
and their cubits.

## Result

Settings is broadly solid: content width and navigation already adapt, and
network-bound screens already handle loading/error. The audit found and **fixed
one real accessibility gap** — three screens rendered bare, unlabeled toggle
switches for screen-reader users.

Legend: ✅ verified · 🔧 fixed · ⚠️ tracked.

---

## SET-UI-001 - Navigation and content width on large screens

Status: ✅ verified

- **Content max width.** All 13 settings screens wrap their body in
  `ConstrainedBox(maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth))`
  (via `LayoutBuilder`), so content is centered with an intentional max width on
  iPad/tablet/desktop rather than stretching edge-to-edge. `discovery_filters`
  uses a screen-specific helper built on the same token.
- **Navigation.** Settings is reached through the adaptive app shell
  ([`home_screen.dart`](../../lib/presentation/screens/home_screen.dart),
  bottom-nav ↔ navigation-rail per `DsBreakpoints`, verified under RESP-001);
  sub-screens are standard pushed routes with centered, width-capped content.

## SET-UI-002 - Accessibility & interaction quality

Status: 🔧 toggle labeling fixed; ✅ destructive flows verified

- 🔧 **Fixed — unlabeled toggle switches.** 6 settings screens already used
  `SwitchListTile` (which associates the row label with the control for screen
  readers), but **3 used a bare `Switch` in `ListTile.trailing`** with no
  association: `privacy`, `notifications`, `account_security`. A ListTile only
  auto-merges its semantics when it is itself tappable (`onTap`); these
  switch-only rows are not, so VoiceOver/TalkBack announced the control as just
  "on/off, switch" without the setting name. Wrapped the three tile builders
  (`_PrivacyTile`, `_SettingsTile`, `_SecurityTile`) in `MergeSemantics` so the
  label, subtitle, and control collapse into one labeled, toggleable node.
  Covered by
  [`settings_toggle_semantics_test.dart`](../../test/features/settings/presentation/screens/settings_toggle_semantics_test.dart).
- ✅ **Destructive actions.** Account deletion uses a multi-step
  `AdaptiveDialog` flow with data-download choice and **type-to-confirm +
  password** re-auth; sign-out and clear-data are confirmation-gated. Tap
  targets use Material defaults (≥48dp). These are clear and appropriately
  reversible.

## SET-UI-003 - Loading, empty, and error states

Status: ✅ verified consistent

- **Network-bound screens already handle it.** `subscription`,
  `account_security`, `chat`, and `language_region` surface
  loading/error/retry (spinners + error text + retry actions).
- **Preference screens are local-first by design.** `notifications`, `privacy`,
  `discovery_filters`, and `data_storage` are backed by `SharedPreferences`
  cubits that update optimistically (`emit` → local `persist`); for the screens
  that also sync remotely (notifications), the remote push is **best-effort with
  errors intentionally swallowed** and reconciled on next hydrate
  ([`notification_preference_sync_service.dart`](../../lib/features/settings/data/preferences/notification_preference_sync_service.dart)).
  Local writes do not fail in practice, so a loading/error/retry surface is not
  applicable — this is consistent, not ad hoc.

No settings screen performs a blocking network load without a loading/error
state.

---

## Changed files

- `lib/features/settings/presentation/screens/privacy_settings_screen.dart` (a11y)
- `lib/features/settings/presentation/screens/notifications_settings_screen.dart` (a11y)
- `lib/features/settings/presentation/screens/account_security_settings_screen.dart` (a11y)
- `test/features/settings/presentation/screens/settings_toggle_semantics_test.dart` (new)

## Verification

- `flutter analyze` on changed files — clean.
- `flutter test` (new semantics test + privacy/notifications/account-security localization suites) — 5 passing, no regressions.
- ⚠️ Manual VoiceOver/TalkBack sweep of the settings toggles remains a release-gate item.
