# Crush Design System (2026 Refresh)

This document defines the visual system for Crush across Flutter and web. It mirrors the token values in `lib/design_system/tokens` and the theme config in `lib/design_system/theme/app_theme.dart`.

## 1) Brand Foundations

### Brand tone
- Romantic, safe, premium, and friendly.
- Soft contrast, warm surfaces, and confident accents.
- High legibility, low visual noise.

### Color palette (core)
- Primary (Rose): `#FF3F7F`
- Primary Dark: `#E0356F`
- Secondary (Plum): `#7B6CFF`
- Accent (Mint): `#4DD6A7`

### Theme presets
- **Light**
- **Dark**
- **System default** (follows device)
- **Dark Luxury (Royal)** (premium theme)
- **Dark Luxury (Modern)** (premium theme)

### Neutral ink scale
- Ink 900: `#0B0B10`
- Ink 800: `#14141B`
- Ink 700: `#1E1E28`
- Ink 600: `#2A2A36`
- Ink 500: `#3A3A4A`
- Ink 400: `#4A4A5E`
- Ink 300: `#6D6D86`
- Ink 200: `#A0A0B8`
- Ink 100: `#D6D6E6`
- Ink 50: `#F5F5FA`

### Surface + background
- Light background: `#F8F7FB`
- Light surface: `#FFFFFF`
- Light elevated surface: `#FDFDFF`
- Dark background: `#0D0E12`
- Dark surface: `#14141B`
- Dark elevated surface: `#1E1E28`

### Status colors
- Success: `#43C59E`
- Warning: `#F7B955`
- Error: `#FF5A6E`
- Info: `#5BB3FF`

### Glassmorphism tokens
- Glass light: `#B8FFFFFF` (surface), `#40FFFFFF` (border)
- Glass dark: `#B314141B` (surface), `#26FFFFFF` (border)
- Frost light: `#D9FFFFFF`
- Frost dark: `#B3000000`

### Dark Luxury palettes (premium)
Token prefixes: `color.luxury` (Royal) and `color.luxuryModern` (Modern).
**Royal (Classic Gold)**
- Background: `#000000`
- Surface: `#0D0D0D`
- Surface Elevated: `#141414`
- Gold Primary: `#D4AF37`
- Gold Soft: `#F1D27A`
- Gold Dark: `#9E7C19`
- Text Primary: `#F5F5F5`
- Text Secondary: `#B3B3B3`
- Text Muted: `#7A7A7A`
- Text On Gold: `#1A1A1A`
- Border: `#2A2A2A`
- Border Gold: `#6B5A1E`
- Glass: `#CC0D0D0D`
- Glass Border: `#406B5A1E`
- Glow: `#33D4AF37`
- Shimmer: `#66F1D27A`

**Modern (Cool Gold)**
- Background: `#050505`
- Surface: `#101010`
- Surface Elevated: `#181818`
- Gold Primary: `#E6C77D`
- Gold Soft: `#F5E6B0`
- Gold Dark: `#B89B4F`
- Text Primary: `#F2F2F2`
- Text Secondary: `#B0B0B0`
- Text Muted: `#808080`
- Text On Gold: `#121212`
- Border: `#262626`
- Border Gold: `#7D6A33`
- Glass: `#CC101010`
- Glass Border: `#407D6A33`
- Glow: `#2AE6C77D`
- Shimmer: `#55F5E6B0`

## 2) Typography

### Font families
- Body: **Plus Jakarta Sans**
- Display: **Playfair Display**

### Type scale (Flutter `DsTypography`)
- Display Large: 34 / 600 / 1.12 / -0.4
- Display Medium: 28 / 600 / 1.21 / -0.3
- Display Small: 22 / 600 / 1.27 / -0.2
- Title Large: 18 / 600 / 1.33
- Title Medium: 16 / 600 / 1.38
- Body Large: 16 / 400 / 1.50
- Body Medium: 14 / 400 / 1.55
- Body Small: 12 / 400 / 1.50 (muted)
- Label Large: 14 / 600 / 1.30
- Label Medium: 12 / 600 / 1.30
- Label Small: 10 / 600 / 1.30

## 3) Spacing

Use an 8-based system with micro steps.

- xs: 4
- sm: 8
- md: 12
- lg: 16
- xl: 20
- xxl: 24
- xxxl: 32
- huge: 40

## 4) Radius

- sm: 10
- md: 14
- lg: 20
- xl: 24
- xxl: 32
- card: 20
- cardSm: 16
- input: 14
- chip: 12
- round: 1000

## 5) Elevation

- low: 0
- mid: 2
- high: 6

## 6) Blur (Glass)

- subtle: 2
- light: 4
- medium: 6
- heavy: 10
- extreme: 16

## 7) Gradients

Primary gradients are rose → plum. Use these for hero moments, tabs, and major CTAs.

- Primary Vertical: `primary → secondary`
- Primary Horizontal: `primary → secondary`
- Primary Diagonal: `primary → secondary`
- Soft Rose: `#FF6F86 → #FFA3B1`

## 7.1) Theme Effects

The theme extension `CrushThemeEffects` adds:
- `glowColor` (used for luxury glow/shadows)
- `glassSurface` and `glassBorder`
- `shadowOpacity`
- `motionScale` (luxury motion is slightly slower)
- `primaryGradient` (theme-aware CTA gradient)

## 7.2) Dark Luxury usage

- **Buttons**: Primary = gold background + `textOnGold`. Secondary = black surface + gold border + gold text.
- **Cards**: Luxury surfaces with thin gold border or subtle gold glow on premium sections.
- **Navigation bar**: True-black background, active icon in gold, inactive in muted gray.
- **Premium badges**: Gradient from goldDark → goldPrimary → goldSoft.
- **Motion**: Slower easing (`easeOutCubic`), gold shimmer on premium CTAs, soft glow on active tabs, gentle fade+scale transitions.

## 8) Component Guidelines (high level)

- **Buttons**: Primary uses solid `primary` or `primaryDiagonal` gradients. Secondary uses glass surfaces with `DsGlassColors`.
- **Cards**: Use `DsRadius.card`, light shadows, and muted borders (`borderLight`/`borderDark`).
- **Input fields**: Use `DsColors.inputFillLight/Dark`, `DsRadius.input`, and standard label styles.
- **Nav bar**: Glass surface with subtle border and gradient accent for active tab.
- **Empty states**: Use muted ink text and a single accent icon color.

## 9) Accessibility

- Always ensure body text contrasts at least AA.
- Default text color uses `textPrimaryLight` or `textPrimaryDark`.
- Muted copy uses `textMutedLight` or `textMutedDark`.

## 10) Figma Token Export

A Figma-ready token export is provided here:
- `docs/design_tokens.json`

This file follows the W3C design token format and can be imported into token tools (e.g., Tokens Studio).
It now includes Dark Luxury (Royal + Modern) colors, gradients, and motion scale tokens.
