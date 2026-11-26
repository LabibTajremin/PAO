# P22 — Service icons: library, uploads, accent colour

**Goal:** every category and service has a clear icon in the accent colour; admins pick from a
library or add their own by upload or link.

**Read first:** `06-update-2026-11.md` items iv, vi, vii; `Backend/api/schemas/catalog.yaml`
(`iconKey`); `apps/customer/lib/shared/catalog_icons.dart`; admin `features/catalog/`;
media upload flow (P04).

## Tasks

1. **Library.** Draw about 40 icons as SVG on a 24 × 24 grid, 1.75 px stroke, round caps,
   single colour (`currentColor`), consistent optical size. At least: plumbing (pipe + tap +
   drop, replacing the current wrench), electrician, AC, appliance repair, cleaning, deep clean,
   pest control, painting, carpentry, gas/stove, water filter, salon, spa, men's grooming,
   driver, car wash, moving/shifting, laundry, tailoring, babysitting, elderly care, nursing,
   tutoring, homemade food (tiffin carrier), catering (handi pot), monthly bazar (jute bag),
   grocery, cook/chef, gardening, CCTV, internet/Wi-Fi, mobile repair, computer repair,
   photography, event decoration, security guard, courier, generic tools. Put them in
   `design/icons/` and `pao_ui/assets/icons/`, plus a seed list (key → file) for the backend.
2. **Backend.** Category and service gain `iconUrl` (nullable) next to `iconKey`. New admin
   endpoints: list library icons; upload an icon (SVG ≤ 100 KB sanitised, or PNG/WebP square
   ≥ 96 × 96 with transparency, ≤ 200 KB); add by link: the server downloads once, validates
   like an upload and stores it in our bucket (never hotlink). OpenAPI first, then code, audit
   entries for every change.
3. **Seed.** Every seeded category and service gets a fitting library key (plumbing →
   `plumbing`, catering → `catering`, monthly bazar → `bazar`, …).
4. **Admin UI.** On category and service edit: an icon picker (search, grid of library icons
   tinted with the current accent), "Upload" and "From link" tabs, live preview on light and dark
   tiles, with the size and format rules shown under the field.
5. **Apps.** `PaoServiceIcon` renders library SVGs or uploaded images as a single-colour mask
   (`ColorFilter.mode(accent, BlendMode.srcIn)`) inside `PaoIconTile` (`primaryTint` tile,
   `primary` glyph; dark: `elevated` tile, `soft` glyph), cached; unknown → generic tools icon.
   Replace `catalogIcon()` and Material icons in catalog places.

## Definition of done

Changing the accent recolours every service icon; an admin can pick, upload and link icons and
the apps show them after refresh. `./pao ci` green.
