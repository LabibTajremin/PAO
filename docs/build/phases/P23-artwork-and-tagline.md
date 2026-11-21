# P23 — Admin-managed artwork slots and tagline

**Goal:** admins can replace any illustration and edit the tagline without a release.

**Read first:** `06-update-2026-11.md` §5, §6; ADR-0037 §2 (banners, a similar pattern);
settings and media areas in `Backend/docs/`.

## Tasks

1. **Backend: artwork.** Table `content.artwork_slots` (key, app, image media id, version,
   updated by/at). Fixed slot list from §5 with their sizes in code. Endpoints: public
   `GET /v1/artwork?app=customer|partner|admin` (keys → URL + version, cacheable, ETag); admin
   list, upload/replace, reset-to-seed. Validation exactly as §5 (format, size, ratio ±2%, SVG
   sanitising); errors name the expected size. Audited.
2. **Backend: tagline.** Setting `brand.tagline` {en, bn}, max 40 chars each, in the existing
   settings area; returned by the public app config endpoint. Seed per §6.
3. **Seed pipeline.** `migrate seed-artwork` uploads `design/illustrations/*.svg` into storage
   and fills the slots; it runs in the normal seed step and is idempotent (skips slots an admin
   has replaced).
4. **Admin UI.** New page **Appearance › Illustrations**: one card per slot with current image,
   required size and ratio, safe-area overlay, upload, preview on light/dark, reset. **Settings ›
   Brand**: tagline fields with live preview and the suggestion chips from §6.
5. **Apps.** `PaoArtwork(slot)` shows the bundled seed SVG first, then the server image when
   cached (no layout jump: fixed aspect ratio box). Versioned cache, works offline.

## Definition of done

Replacing an illustration or the tagline in admin shows in both apps after refresh, without a
release; invalid uploads are refused with a clear message. `./pao ci` green.
