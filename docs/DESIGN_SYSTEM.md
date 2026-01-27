# Crush Design System (2026 Refresh)

This document defines the visual system for Crush across Flutter and web. It mirrors the token values in `lib/design_system/tokens` and the theme config in `lib/design_system/theme/app_theme.dart`.

## 1) Brand Foundations

### Brand tone
- Romantic, safe, premium, and friendly.
- Soft contrast, warm surfaces, and confident accents.
- High legibility, low visual noise.

### Color palette (core)
- Primary (Rose): `#FF4D6D`
- Primary Dark: `#E03B5F`
- Secondary (Plum): `#7B6CFF`
- Accent (Mint): `#4DD6A7`

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
