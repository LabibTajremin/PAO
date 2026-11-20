# P21 — Logo, app icons and receipt watermark

**Goal:** the new PAO logo is used everywhere, the inverse version in dark mode, and the
installed apps show the new icon on every platform.

**Read first:** `06-update-2026-11.md` §4; `design/brand/`.

## Tasks

1. **Logo widget.** `PaoLogo` in `pao_ui` with `tile` and `wordmark` variants, rendered from
   the SVGs (`flutter_svg`), choosing light or inverse assets from the theme brightness.
   Replace every old logo use (splash, sign-in, app bars, admin sidebar, emails if any).
2. **Launcher icons** for `customer` and `partner` (`flutter_launcher_icons`, config committed):
   iOS light, dark (iOS 18) and tinted variants in `AppIcon.appiconset`; Android adaptive icon
   (foreground PNG, background `#0B0B0C`, monochrome layer), legacy icons for all densities.
   Admin web: favicon, PWA icons, maskable icon, `manifest.json` theme colours.
3. **Splash:** `flutter_native_splash`, light `#F6F4EC` with the ink tile, dark `#0E1322` with
   the inverse tile, Android 12 splash API included.
4. **Receipts:** customer receipt (C64, PDF share) and partner `receipt_sheet`: logo tile in the
   header, `receipt/watermark.svg` centred behind the line items, tagline in the footer (from
   P23 once present; fixed text until then).
5. **Tests:** widget tests for `PaoLogo` in both brightnesses; a PDF test asserting the
   watermark layer exists.

## Definition of done

Installed builds on Android (light, dark, themed icons) and iOS (light, dark, tinted) show
the new icon. Screenshots in `docs/guides/brand.md`. `./pao ci` green.
