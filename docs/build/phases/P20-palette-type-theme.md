# P20 — Palette, type and light-first theme

**Goal:** the apps and admin panel use the enhanced Navy trust palette and neutral system
type, open in light mode, and look premium in light and dark.

**Read first:** `06-update-2026-11.md` §2, §3, items ii, ix, x, xvi; ADR-0033, ADR-0037;
`Frontend/packages/pao_ui/lib/src/tokens/`, `theme.dart`, `theme_parts.dart`;
`pao_core/lib/src/device/theme_mode.dart`.

## Tasks

1. **Tokens.** Replace the light and dark values in `PaoColors` with §2 (add `sunken`,
   `elevated`, `primaryTint`, `actionStrong`, card shadow). Add `AccentPreset.navy` and make it
   the default everywhere a default accent is chosen (app, admin, seed settings).
2. **Type.** iOS uses the system font; Android and web bundle Inter + Noto Sans Bengali. Remove
   Fraunces and Plus Jakarta Sans files and references. One type scale (display 28/34, title 22,
   headline 18, body 16, label 14, caption 12; Bangla through `PaoBanglaScale`).
3. **Light by default.** `ThemeMode` defaults to light (not system) on first launch and for
   existing users who never chose. Appearance (Light / Dark / Match phone) moves from the
   language page to **Account › Settings › Appearance** in the customer app and
   **Profile › Settings › Appearance** in the partner app: one level deep, not on the first
   screen, not in onboarding. Admin web: a toggle in the user menu.
4. **Premium surfaces.** Cards white on `canvas` with the navy-tinted shadow; section bands on
   `sunken`; 16 px card radius, 24 px sheet radius, 12 px inputs; consistent 4-pt spacing.
   Dark mode uses the navy-ink surfaces, never pure black or grey.
5. **Update the gallery** (`gallery.dart`) and golden tests for both modes, both languages.
6. ADR-0038 records the palette, type and default-mode decisions.

## Definition of done

Goldens for every `pao_ui` widget in light/dark × en/bn; axe/contrast checks pass; a fresh
install opens light. `./pao ci` green.
