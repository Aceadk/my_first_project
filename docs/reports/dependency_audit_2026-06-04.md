# Dependency Audit - 2026-06-04

Scope: `CLEAN-DEP-001`–`CLEAN-DEP-003` from
[`docs/TODO_CLEANUP_DEPENDENCIES.md`](../TODO_CLEANUP_DEPENDENCIES.md).

Manifests: [`pubspec.yaml`](../../pubspec.yaml) (mobile, 52 deps / 21 dev),
[`functions/package.json`](../../functions/package.json) (Cloud Functions,
12 deps / 11 dev), and `/Users/ace/crush-web/package.json` (Next.js web,
workspace root: 0 prod / 11 dev).

Tools run: `flutter pub outdated`, `npm outdated`, `npm audit`. **No dependency
was mutated** — this is an inventory + triage deliverable; upgrades are planned,
not applied (see the safety note under CLEAN-DEP-003).

Legend: ✅ ok · ⬆️ upgrade candidate · ⚠️ risk/blocker.

---

## CLEAN-DEP-001 - Inventory (purpose, owner, risk)

### Mobile (`pubspec.yaml`) — owner: app team

| Group | Packages | Purpose | Risk |
|------|----------|---------|------|
| State/util | flutter_bloc, equatable, intl, uuid, path, crypto, cryptography, json_annotation | BLoC state, value equality, i18n, ids, hashing, DTO codegen | ✅ low |
| Firebase | firebase_core/auth/messaging/firestore/functions/storage/analytics/remote_config/performance/crashlytics/database/app_check | Backend platform | ⬆️ all 1 minor behind |
| Networking | http, web_socket_channel, cached_network_image | REST, realtime, image cache | ✅ low |
| Media | image_picker, video_player, image, lottie, record, just_audio, share_plus | Photos/video/audio/animation/share | ⚠️ several majors behind (just_audio, record, share_plus) |
| Auth/identity | google_sign_in, sign_in_with_apple, local_auth, flutter_secure_storage | Social login, biometrics, secure storage | ✅ low |
| Payments | in_app_purchase (+_android/_storekit) | StoreKit/Play billing | ⬆️ minor/major behind |
| Location | geolocator, geocoding | Discovery location | ⬆️ app_links major behind (6→7) |
| Misc | url_launcher, app_links, package_info_plus, flutter_local_notifications, mailer, in_app_review, google_fonts | Deep links, notifications, email, reviews, fonts | ⬆️ package_info_plus 8→10, mailer 6→7, FLN 20→21 |

- ✅ **No `dependency_overrides`** (no pinned-fork risk).
- ⚠️ **Dev `any`-pinned platform-interface deps** (`firebase_analytics_platform_interface: any`, `cloud_functions_platform_interface: any`, `geocoding/geolocator_platform_interface: any`, `plugin_platform_interface: any`, `firebase_database_platform_interface: any`): unconstrained versions are a reproducibility risk — pin to a caret range.

### Cloud Functions (`functions/package.json`) — owner: backend

express, cors, multer, firebase-admin, firebase-functions, stripe,
@google-cloud/bigquery, @google-cloud/vision, agora-access-token, bcryptjs,
file-type, @dataconnect/admin-generated (local). Purpose: REST API, auth/billing,
moderation (Vision), analytics (BigQuery), RTC tokens. Risks under CLEAN-DEP-002/003.

### Web (`crush-web`) — owner: web team

Next.js 16 monorepo (turbo); prod deps live in workspace packages. Dev toolchain
on `eslint ^8.57` (v8 EOL) — ⬆️ upgrade to eslint 9.

## CLEAN-DEP-002 - Stale / deprecated packages

**Mobile** — within-constraint minor bumps are safe (`flutter pub upgrade`):
go_router 17.1→17.3, firebase_* +1 minor, image_picker, uuid, mockito 5.6→5.7,
shared_preferences, etc. **Major-version candidates (need compatibility work, do
separately with smoke tests):** app_links 6→7, package_info_plus 8→10,
share_plus 10→13, record 6→7, mailer 6→7, just_audio 0.9→0.10,
flutter_local_notifications 20→21, and the dev firebase `*_platform_interface`
5→6/7→8 set. ⚠️ `image` is held at 4.8.0 (resolvable) vs 4.9.1 (latest) by a
transitive constraint — blocker to note.

**Functions** — ⚠️ **`multer ^1.4.5-lts` is deprecated** (v1 is end-of-life;
v2.1.1 is current) → prioritized replacement (breaking: API changes).
Other majors behind: `stripe` 16→22, `express` 4→5, `file-type` 16→22,
`@google-cloud/bigquery` 7→8 (all breaking — plan individually). Safe minors:
`firebase-admin` 13.6.1→13.10.0, `firebase-functions` 7.0.5→7.2.5.
⚠️ `agora-access-token` is superseded by `agora-token` — track migration.

## CLEAN-DEP-003 - Licenses & vulnerability posture

### Vulnerabilities (Functions: `npm audit`)

**29 vulnerabilities — 1 critical, 8 high, 19 moderate, 1 low.** All are
**transitive** through the `@google-cloud/*` / `firebase-admin` /
`firebase-functions` / `google-gax` chain (none in first-party code):

- 🔴 **critical:** `protobufjs (<=7.5.7)`
- 🟠 **high:** `node-forge`, `lodash`, `path-to-regexp (<0.1.13)`,
  `fast-xml-parser`, `serialize-javascript`, `minimatch`, `flatted`, `picomatch`

**Recommended remediation (owner: backend), in order:**
1. Bump `firebase-admin`→13.10.0 and `firebase-functions`→7.2.5 (within-major
   minors) and re-run `npm audit` — these pull patched `@google-cloud`/`gaxios`
   transitives and should clear most/all of the chain.
2. ⚠️ **Do NOT run `npm audit fix`.** Its `--dry-run` here proposed *adding*
   unfamiliar packages (`xml-naming`, `path-expression-matcher`,
   `fast-xml-builder`, `@nodable/entities`) that are not the expected upstream
   deps — remediate by pinning known-patched versions in the manifest and
   reviewing the lockfile diff, not via automated fix.
3. Replace deprecated `multer` v1 → v2.

Dart/pub has no built-in vulnerability database; the mobile stack is mainstream
Flutter/Firebase with no known active advisories, but should be re-checked
manually on each Firebase bump.

### Licenses

The mobile (Flutter/Firebase) and functions (google-cloud/express) stacks are
overwhelmingly permissive (BSD-3-Clause / MIT / Apache-2.0); no copyleft (GPL/AGPL)
package was identified in the direct manifests, so commercial distribution is
compatible. ⚠️ Follow-up (owner: release): run an automated license scan
(`flutter pub deps` + a license checker; `npx license-checker` for npm) to produce
a signed-off SBOM before store submission — recorded here as the tracked action.

---

## Summary of follow-up actions (prioritized)

1. 🔴 Clear the functions vuln chain via firebase-admin/functions minor bumps + re-audit (manual, not `audit fix`).
2. ⚠️ Replace deprecated `multer` v1 → v2 and `agora-access-token` → `agora-token`.
3. ⬆️ Apply safe within-constraint pub/npm minors; schedule major bumps individually with smoke tests.
4. ⚠️ Pin the `any`-versioned dev platform-interface deps.
5. 📋 Generate a license SBOM for store sign-off.

## Verification

- `flutter pub outdated`, `npm outdated`, `npm audit` run and captured above.
- No manifests or lockfiles modified.
