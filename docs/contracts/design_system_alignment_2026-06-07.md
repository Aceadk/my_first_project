# Design System Alignment (Phase 8 Step 16)

- Date: 2026-06-07
- Sources: web tokens `crush-web/apps/web/tailwind.config.ts` +
  `src/styles/globals.css`; mobile tokens `lib/design_system/tokens/{colors,
  typography}.dart` + `lib/design_system/theme/app_theme.dart`.
- Enforced by: `apps/web/src/lib/__tests__/design-token-parity.test.ts`.

## 1. Semantic color tokens (web CSS var ↔ Flutter ↔ role)

| Role | Web (`--var`) | Flutter (`DsColors`) | Notes |
|---|---|---|---|
| Brand primary | `--primary` 340 82% 46% | `primary` #FF3F7F | rose; slight hue diff (platform refresh), same role |
| Primary darken | `--primary-dark` 340 82% 40% | `primaryDark` #E0356F | **added this phase** (was undefined → dead class) |
| Secondary | `--secondary` 255 100% 65% | `secondary` #7B6CFF | plum |
| Accent/trust | `--accent` | `accent` #4DD6A7 | mint |
| Background | `--background` | `backgroundLight/Dark` | |
| Card/surface | `--card` | `surfaceLight/Dark` | |
| Muted | `--muted` / `--muted-foreground` | `ink*` scale | |
| Border/input | `--border`, `--input` | `borderLight/Dark`, `inputFill*` | |
| Focus ring | `--ring` | focus theme | see §6 focus |
| Destructive/error | `--destructive` | `error` #FF5A6E | |
| Success | `--success` | `success` #43C59E | |
| Warning | `--warning` | `warning` #F7B955 | |
| Info | `--info` | `info` #5BB3FF | |
| Action like/superlike/pass/rewind | `--action-*` | `actionLike/SuperLike/Pass/Rewind` | dating deck |
| Online/offline/busy | `--online/offline/busy` | `online/offline/busyIndicator` | presence |
| Glass surface/border | `--glass-{light,dark}-{surface,border}` | `DsGlassColors.surface*/border*` | **added this phase**; alpha baked to match Flutter |

## 2. Typography roles

| Role | Web (`fontSize`/`fontFamily`) | Flutter (`DsTypography`) |
|---|---|---|
| Display | `display` 2rem 600 / var(--font-sans) | `displayLarge/Medium/Small` (Playfair Display) |
| H1–H3 | `h1`/`h2`/`h3` | `headlineMedium`/`titleLarge`/`titleMedium` |
| Body | `body`/`body-sm` | `bodyLarge`/`bodyMedium`/`bodySmall` |
| Caption/label | `caption` | `label*` |

### Intentional font differences (decided)
- **Mobile** uses **Playfair Display** for hero/display and **Plus Jakarta Sans**
  for body — a romantic/premium tone suited to full-screen native surfaces, plus
  an explicit **CJK fallback chain** for zh/ja/ko/yue.
- **Web** uses a single performance-first **`--font-sans`** (system/Geist) stack
  for all roles (no web-font display face) to protect LCP/CLS on first paint and
  marketing pages. This divergence is **intentional**, not drift.

## 3. Spacing, radii, elevation, motion

| Scale | Web | Flutter |
|---|---|---|
| Spacing | Tailwind 4px base | DS spacing scale (`spacing_showcase`) |
| Radii | `--radius-{sm,md,lg,xl,2xl,full}` (4/6/8/12/16/9999) | DS radius tokens |
| Elevation | `boxShadow.{sm..xl}` (Linear-style) | glass/elevation in `app_theme` |
| Motion | `animation`/`keyframes` (fade/slide/scale/pulse 0.2–0.3s) | implicit anims; respects reduced-motion |
| Backdrop blur | `backdropBlur.glass` 12px (**added**) | `DsGlassColors` blur |

## 4. Breakpoints (intentional)

- **Web** (`tailwind.config.ts screens`): `xs 475 · sm 640 · md 768 · lg 1024 ·
  xl 1280 · 2xl 1536`. Sidebar appears ≥ `lg`; compact layout below `md`.
- **Mobile**: single responsive surface (no desktop breakpoints); adapts to
  device width + tablet/iPad via Flutter layout. Web's multi-breakpoint scale is
  **intentionally** richer because it spans phone→desktop in one client.

## 5. Component alignment

| Component | Web | Flutter | Variants aligned |
|---|---|---|---|
| Button | `packages/ui/button.tsx` | `glass_button` + theme | default/secondary/outline/ghost/link/glass/destructive + like/superlike/pass; sizes sm→xl + icon |
| Forms | `input.tsx`, `textarea.tsx` | DS inputs | focus ring, disabled, error |
| Card | `card.tsx` | DS cards/glass | elevation, glass surface |
| Dialog | `dialog.tsx` (radix) | bottom sheets/dialogs | focus trap, Escape |
| Navigation | `app-sidebar` | `glass_bottom_nav_bar` | platform idiom (see UX §2) |
| Feedback | `toast.tsx` (sonner), `skeleton.tsx`, `badge.tsx` | snackbars, skeletons | loading/empty/error states |
| Premium | `/premium` views | `subscription/` | plan badges, upgrade CTAs |

## 6. Focus & states

- Web global `:focus-visible { outline: 2px solid hsl(var(--ring)); offset 2px }`
  (globals.css) + component `focus-visible:ring-2 ring-ring ring-offset-2`.
- All interactive components define `disabled` (opacity 50, no pointer events)
  and `active` (scale) states; mirrored in Flutter via theme states.

## 7. Defect fixed this phase

`bg-primary-dark`, `via-primary-dark`, `bg-glass-light-surface`,
`border-glass-light-border`, and `backdrop-blur-glass` were referenced by
`packages/ui/{button,card,dialog}.tsx` but **undefined** in the Tailwind config /
CSS — so `variant="glass"` and primary-dark hovers/gradients rendered nothing.
Added the matching tokens (aligned to `DsGlassColors` alpha) and a parity test
that fails if any tailwind-referenced CSS var is undefined or these component
classes lose their backing token.

## Done-when status (Step 16)

- ✅ Semantic tokens for colors, typography, spacing, radii, elevation, motion,
  focus, and states mapped web ↔ mobile.
- ✅ Intentional font (Playfair+Jakarta vs system/Geist) and breakpoint
  (multi-breakpoint web vs single responsive mobile) differences decided +
  documented.
- ✅ Buttons/forms/cards/dialogs/navigation/feedback/premium aligned; dead glass/
  primary-dark tokens fixed; parity test added (5 assertions, green).
- ✅ Visual-regression scaffolding added (`e2e/visual.spec.ts`); baseline capture
  runs in the E2E lane (operational — see hand-off checklist §5/§6).
