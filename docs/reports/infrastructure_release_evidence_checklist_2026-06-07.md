# Infrastructure & Release-Evidence Checklist (Hand-off)

- Date: 2026-06-07
- Purpose: every **operational / infrastructure / device** item deferred across
  the web-mobile alignment work (Phases 0–7) in one actionable place. All the
  CODE for these is built, tested, and pushed; what remains needs credentials,
  cloud/provider consoles, a deployed staging app, or real devices — i.e. things
  that can't be done from the repos.
- Canonical decisions already made: production domain **crush.app**; web deploy
  **Vercel**; streaks/boost/promo/entitlement **server-owned**; chat/match V2
  **flag-gated** (`NEXT_PUBLIC_USE_V2_CHAT`, default OFF).
- Owner: ___  · Target release: ___

Legend: ☐ todo · 🔑 needs credentials/console · 🌐 needs deployed staging · 📱 needs devices/browsers.

---

## 0. Environment variables (set per environment)

Set in Vercel (web) and Firebase Functions params (backend). See
`.env.example` (crush-web) + `domain_environment_matrix_2026-06-05.md`.

| Var | dev | staging | production |
|---|---|---|---|
| `NEXT_PUBLIC_APP_ENV` | development | staging | production |
| `NEXT_PUBLIC_APP_URL` | http://localhost:3000 | https://staging.crush.app | https://crush.app |
| `NEXT_PUBLIC_API_ORIGIN` | (empty) | https://api.staging.crush.app | https://api.crush.app |
| `NEXT_PUBLIC_FIREBASE_*` (apiKey, projectId, authDomain, appId, …) | ✓ | ✓ | ✓ |
| `NEXT_PUBLIC_FIREBASE_APPCHECK_RECAPTCHA_KEY` | optional | **required** | **required** |
| `NEXT_PUBLIC_FIREBASE_APPCHECK_PROVIDER` | recaptcha-enterprise | recaptcha-enterprise | recaptcha-enterprise |
| `NEXT_PUBLIC_FIREBASE_APPCHECK_DEBUG_TOKEN` | (dev only) | — | — |
| `NEXT_PUBLIC_FIREBASE_VAPID_KEY` | ✓ | ✓ | ✓ |
| `NEXT_PUBLIC_USE_V2_CHAT` | true (to test) | true (after migration) | true (after rollout) |
| Backend `CORS_ALLOWED_ORIGINS` | localhost | staging origins | crush.app origins |
| Backend `EMAIL_FROM` | dev | staging | `Crush <no-reply@crush.app>` (after sender verify) |
| Backend `STRIPE_*`, `APPLE_*`, `GOOGLE_PLAY_*`, `AGORA_*`, `OTP_SECRET`, `RESEND_API_KEY` | ✓ | ✓ | ✓ |

☐ 🔑 All required vars set in Vercel + Functions params for each environment.

---

## 1. App Check + CSP (Phase 2)

- ☐ 🔑 Register a **reCAPTCHA Enterprise** key for crush.app in Google Cloud +
  enable Apple/Google/web App Check in the Firebase console.
- ☐ 🔑 Register an App Check **debug token** for local/CI (dev only).
- ☐ 🌐 Confirm `connect-src`/`script-src`/`frame-src` permit every backend call
  (CSP is in `apps/web/src/shared/lib/csp.ts`; covered by `csp.test.ts`).
- ☐ 🌐 **Evidence:** in staging, every web callable + discovery REST succeeds
  WITH valid App Check and fails predictably WITHOUT it; browser console shows
  **zero CSP violations**.

## 2. Firestore rules (Phase 3) — mostly done

- ✅ Rules-emulator suite (77 tests) runs locally and in CI (`firestore_rules` job).
- ☐ 🔑 Ensure CI runners have Java (added) and the suite is green on the PR.
- ✅ `firestore.rules` ≡ `functions/firestore.rules` (parity guard).

## 3. Data migrations (Phases 4–5) — scripts built, run pending

Auth: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json` (per env).

### 3a. Legacy flat-profile → canonical `profile.*` (Phase 4 Step 5)
- ☐ 🔑🌐 `cd crush-web/apps/web && pnpm migrate:flat-profile --project crush-265f7-staging` (dry run) → `:execute` → verify in console.
- ☐ 🔑 Repeat on production after staging sign-off.

### 3b. Chat/match cutover (Phase 5 Steps 8–9) — runbook: `chat_match_cutover_runbook_2026-06-07.md`
- ☐ 🔑 **Backup** first: `gcloud firestore export gs://<project>-firestore-backups/pre-chat-cutover-$(date +%F) --collection-ids=conversations,matches,swipes,typing_indicators`.
- ☐ 🔑🌐 `pnpm inventory:chat --project <staging>` (record counts).
- ☐ 🔑🌐 `pnpm migrate:conversations --project <staging>` (dry-run) → `:execute` → `pnpm inventory:chat:verify` (0 unmigrated, 0 mismatches).
- ☐ 🌐 Manually validate 3–5 representative conversations.
- ☐ 🌐 Set `NEXT_PUBLIC_USE_V2_CHAT=true` in staging; run the **test matrix**
  (match create/list, chat load/send/read/edit/unsend/reactions/typing/pin,
  block, report) — see §6.
- ☐ 🔑 Production: backup → migrate → verify → enable flag → observe (rollback
  criteria in the runbook).
- ☐ After the observation window: remove the flag + legacy services per
  `legacy_chat_match_removal_manifest_2026-06-07.md`; drop legacy collections.

## 4. Domain / email / deep-link migration off crushhour.app (Phase 6)

Decision + checklist: `domain_deployment_decision_2026-06-07.md`. **Infra FIRST,
then flip code.**
- ☐ 🔑 DNS + SSL for `crush.app`, `api.crush.app`, `staging.crush.app`.
- ☐ 🔑 Firebase Auth → add `crush.app` to authorized domains.
- ☐ 🔑 Apple Universal Links: host `apple-app-site-association` at
  `https://crush.app/.well-known/`; update iOS associated-domains.
- ☐ 🔑 Android App Links: host `assetlinks.json` at `https://crush.app/.well-known/`.
- ☐ 🔑📱 Certificate pinning: ship a mobile release pinning BOTH crushhour.app +
  crush.app, then drop crushhour.app after cutover.
- ☐ 🔑 Email: verify `crush.app` / `no-reply@crush.app` sender, THEN set backend
  `EMAIL_FROM`.
- ☐ 🔑 Stripe dashboard: add crush.app success/cancel + webhook URLs.
- ☐ 🔑 Map custom API domain `api.crush.app` → Cloud Functions; set
  `NEXT_PUBLIC_API_ORIGIN`.
- ☐ Then flip code defaults (mobile deep-link host, cert pins, `EMAIL_FROM`,
  Stripe defaults) and retire crushhour.app (web guard already enforces it).

## 5. CI/CD release lanes (Phases 0/3/6)

- ✅ Web CI: lint + typecheck + test + build + deprecated-domain guard.
- ✅ Functions CI + rules-emulator job.
- ☐ 🌐 Add **Playwright authenticated E2E** lane (Firestore emulator) — plan in
  `web_ci_upgrade_plan_2026-06-05.md`. Now also runs the Phase 8 a11y/responsive/
  visual specs (`@axe-core/playwright` dep added).
- ☐ Add cross-repo **contract fixture** validation lane (shared fixture exists:
  `canonical_user_document.fixture.json`).
- ☐ 🔑 Confirm Vercel project envs + production deploy; record deploy evidence.

## 6. Release-evidence test matrix (Phases 5/7) 🌐📱

Run on staging against the deployed app; record results in the release ticket.

### Account lifecycle (Phase 7 Step 12)
- ☐ 🌐 onboarding redirect, session idle-timeout, account-deletion grace period,
  cancelled deletion, data export — web + mobile.

### Subscription / entitlement (Phase 7 Step 13)
- ☐ 🔑 Provider reconciliation in sandboxes: Stripe + Apple + Google purchase →
  renewal → cancel → expire → restore; promo→paid handoff. Confirm canonical
  `plan`/`subscriptionExpiresAt`/`subscriptionLifecycle` consistent across web +
  mobile.

### Notifications (Phase 7 Step 14)
- ☐ 📱 Web push register + revoke across supported browsers (Chrome/Edge/Firefox/
  Safari) with the VAPID key.
- ☐ 📱 Each category (matches/messages/likes/calls/profileViews/promotions/
  subscriptions/safetyAlerts) delivers and routes to the correct page
  (route targets already validated by `route-existence`/`notification-route-parity`).

### Chat/match (Phase 5 Step 9)
- ☐ 🌐 Two browsers + two devices on one match (realtime sync); offline send →
  reconnect → no duplicate messages.

### UX / accessibility / responsive (Phase 8 / re-audit Gate 3)
- ✅ Web automation **built** (`apps/web/e2e/{a11y-authenticated,a11y-interaction,
  responsive,visual}.spec.ts`): authenticated axe (WCAG 2.1 AA), keyboard/focus/
  focus-trap, zoom/contrast, reduced-motion, 320→1536 responsive sweep, visual
  regression. Contract: `accessibility_responsive_validation_2026-06-07.md`.
- ☐ 🌐 Run those specs in the Playwright E2E lane; generate + commit visual
  baselines on the CI runner OS (`pnpm test:e2e visual.spec.ts --update-snapshots`).
- ☐ 📱 Manual device matrix: VoiceOver (iOS/Safari) · TalkBack (Android) ·
  external keyboard · tablet/iPad · NVDA/JAWS live-region announcements ·
  dark-mode contrast (see §2 of the a11y/responsive contract).

### Calls (P2 #11 / blocked)
- ☐ 📱 Calls device matrix — **blocked**: no web WebRTC yet (product decision to
  build or defer web calling).

## 7. Apple Sign-In on web (Phase 7 Step 12) — optional

Currently **excluded** (decision documented). To add:
- ☐ 🔑 Apple Services ID + Sign-in key + verified domain + return URL
  (`https://crush.app/__/auth/handler`); enable Apple provider in Firebase.
- ☐ Then add `signInWithApple()` to `auth.ts` + a login button (code path noted
  in `auth_method_support_matrix_2026-06-07.md`).

## 8. Repo hygiene CI guard (Phase 0)

- ✅ Tracked node_modules/build artifacts removed.
- ☐ Add a CI guard that fails if generated/dependency artifacts reappear.

---

## Definition of done (release-aligned)

- [ ] All required env vars set per environment (§0).
- [ ] App Check enforced; staging proves callable/REST succeed with it, fail
      without it; no CSP violations (§1).
- [ ] Flat-profile + chat/match migrations executed + verified; V2 enabled in
      production; legacy services removed (§3).
- [ ] Mobile/email/Stripe migrated to crush.app; deprecated-domain guard green
      across both repos (§4).
- [ ] CI green incl. E2E + contract lanes; production deploy recorded (§5).
- [ ] Release-evidence matrix passed + recorded (§6).
- [ ] Apple-on-web added or its exclusion re-confirmed (§7).

## Reference docs

- Contracts: `docs/contracts/{domain_deployment_decision,device_trust_decision,streak_decision,entitlement_model,auth_method_support_matrix,notification_preferences_schema,canonical_user_document.fixture}*`
- Reports: `docs/reports/{shared_backend_contract_matrix,domain_environment_matrix,route_manifest,web_chat_match_migration_plan,chat_match_cutover_runbook,legacy_chat_match_removal_manifest,web_ci_upgrade_plan,phase4_web_data_security_status}*`
- Rules tests: `firestore-tests/README.md`
- Web workflow: `crush-web/AGENTS.md`
