# ADR-0040: Artwork slots, the tagline and one public app config

- Status: Accepted
- Date: 2026-11-22
- Source: the owner's 2026-11 update note (items viii, xiii, xv, xvii), `06-update-2026-11.md`
  §5–6, phase P23. Builds on ADR-0039 (public bucket).

## Decision

1. **Owner.** The Admin area owns artwork and the tagline, next to the other settings. The
   slots live in `admin.artwork_slots` (key, url, seed_url, content type, version, replaced),
   not in a new `content` module: the Admin area already has an outbox for audit events, and a
   module for one table would add a schema, a registration and docs for nothing.
2. **Slots.** The slot list and sizes are code (`ArtworkSlots`), as §5 lists them. A slot with
   no row shows the illustration the app bundles.
3. **Files.** Artwork is stored in the public bucket under `artwork/<slot>/`, readable without
   signing like `catalog-icons/` (the bucket policy covers both folders). SVG up to 300 KB is
   sanitised by the same code as icons (moved to `PAO.Infrastructure/Images`) and its view box
   must match the slot's ratio within 2%; PNG and WebP must be exactly the slot's size, with
   alpha, up to 800 KB. A refused size names the expected one (`details.expected`).
4. **Seeding.** `migrate seed` uploads `database/seed/artwork/<slot>.svg` (copied from
   `design/illustrations/`) under its content hash and records it as `seed_url`. A slot an admin
   replaced keeps its image; reset puts `seed_url` back. Seeding twice changes nothing.
5. **Tagline.** Setting `brand.tagline` of a new type `tagline`: JSON `{en, bn}`, each 1–40
   characters. Edited and audited like every setting.
6. **One public endpoint.** `GET /v1/app-config?app=customer|partner|admin` returns the tagline
   and the app's artwork (key, url, version), anonymous, with a strong ETag and
   `Cache-Control: no-cache`; a matching `If-None-Match` gets 304. The phase named a separate
   `/v1/artwork`; one call per launch is cheaper on slow networks and the per-IP rate limit.

## Consequences

- Apps call app-config at start and when they return to the foreground, cache the answer with
  its ETag and show the bundled seed until a server image is cached (no layout jump: the slot's
  ratio is fixed).
- The `database/seed/artwork/` copies must match `design/illustrations/`; a unit test checks it.
