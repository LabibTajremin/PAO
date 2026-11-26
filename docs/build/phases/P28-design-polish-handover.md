# P28 — Design polish and handover

**Goal:** the apps feel designed by a person: consistent, calm and professional, in both
modes and both languages.

**Read first:** `06-update-2026-11.md`; `05-screens.md`.

## Tasks

1. Walk every screen of the three apps in light/dark × en/bn and fix: spacing on the 4-pt grid,
   alignment, one primary action per screen, real empty/loading/error states, skeletons instead
   of spinners, no clipped Bangla, tap targets ≥ 48 dp, consistent icon sizes.
2. Copy pass: short, friendly English and natural Bangla (not literal translation); same words
   for the same thing everywhere.
3. Motion check: every screen uses the P27 motion tokens; nothing animates that P27 did not
   define; re-run the P27 performance test on the low-end device.
4. Update `05-screens.md`, `docs/guides/brand.md` (logo, palette, type, illustration slots and
   sizes, icon rules) and store screenshots.
5. Release builds for both apps and admin web; `docs/HANDOVER.md` updated.

## Definition of done

A screenshot set of all screens in `docs/screenshots/` with no visual defects found in review;
`./pao ci` green; release builds produced.
