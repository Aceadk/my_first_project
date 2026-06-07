# Accessibility & Responsive Validation (Phase 8 Step 17)

- Date: 2026-06-07
- Standard: **WCAG 2.1 AA**.
- Automated coverage (web): `crush-web/apps/web/e2e/`:
  - `accessibility.spec.ts` — unauthenticated structural checks (existing).
  - `a11y-authenticated.spec.ts` — **axe-core** WCAG 2.1 A/AA scan of signed-in
    surfaces (`@axe-core/playwright`), fails on serious/critical violations.
  - `a11y-interaction.spec.ts` — keyboard nav/focus order, dialog focus trap +
    Escape, `prefers-reduced-motion`, 200% zoom reflow (no horizontal scroll).
  - `responsive.spec.ts` — viewport sweep 320→1536 (no horizontal overflow) +
    nav adaptation (sidebar wide / nav landmark narrow).
  - `visual.spec.ts` — visual-regression baselines for critical screens.

## 1. Automated (web) — runs in the E2E lane

| Check | Spec | Gate |
|---|---|---|
| Authenticated axe (WCAG 2.1 AA) on discover/matches/messages/likes/profile(+edit)/settings(+notifications)/premium | `a11y-authenticated.spec.ts` | no serious/critical |
| Keyboard navigation + focus order | `a11y-interaction.spec.ts` | focus reaches ≥3 distinct controls |
| Dialog focus trap + Escape closes | `a11y-interaction.spec.ts` | focus stays inside; Escape closes |
| Reduced motion honored | `a11y-interaction.spec.ts` | media matches; page renders |
| 200% zoom reflow | `a11y-interaction.spec.ts` | no horizontal overflow at 640px effective |
| Contrast | covered by axe (`color-contrast` rule) | no serious/critical |
| Responsive 320→1536 | `responsive.spec.ts` | no horizontal overflow at any width |
| Visual regression critical screens | `visual.spec.ts` | matches committed baseline |

**Operational note:** these specs need the dev server (and emulator for auth)
and are part of the Playwright E2E lane (hand-off checklist §5). Visual baselines
must be generated once on the CI runner OS (`--update-snapshots`) and committed.

## 2. Manual device matrix (cannot be automated in-repo) 📱

Record results in the release ticket; tracked in the hand-off checklist §6.

| Check | Platform | How |
|---|---|---|
| VoiceOver | iOS (mobile) + Safari (web) | navigate onboarding→discovery→chat→settings; all controls labeled, order logical |
| TalkBack | Android (mobile) | same flows; focus order + announcements |
| External keyboard | iPad/Android tablet + desktop web | full operation without pointer; visible focus |
| Tablet / iPad | iPadOS | layout, split nav, no clipped content |
| Browser screen readers | NVDA/JAWS (Windows), VoiceOver (mac) | live-region announcements on errors (`role="alert"`) |
| Contrast in dark mode | both | verify AA in light + dark themes |

## 3. Shared accessibility guarantees (both clients)

- Single `<h1>` per page + non-skipping heading hierarchy (web spec asserts).
- Landmarks: `main` + `nav` present (web spec asserts).
- Visible focus indicator on every interactive element (`:focus-visible` ring;
  Flutter focus theme).
- Form inputs have associated labels / `aria-label`.
- Errors announced via `role="alert"` / `aria-live`.
- `prefers-reduced-motion` disables non-essential animation.
- Color is never the sole information channel (status uses icon+label).

## Done-when status (Step 17)

- ✅ Authenticated axe checks added (`@axe-core/playwright`, WCAG 2.1 AA).
- ✅ Keyboard navigation, focus order, dialog focus-trap, zoom, contrast (axe),
  and reduced-motion automated.
- ✅ Narrow-mobile→wide-desktop responsive sweep automated (320→1536).
- ⏳ VoiceOver / TalkBack / external-keyboard / tablet / iPad — **manual device
  matrix** (needs real devices/browsers); tracked as release-gate evidence in
  the infrastructure & release-evidence checklist.
