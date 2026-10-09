# P04 — Catalog, media, audit, settings

**Goal:** the fixed-price catalog the whole product depends on, safe file uploads, the
append-only audit trail and admin-editable platform settings.

**Read first:** PRD §4, §5 (business rules: pricing), §6.6, §9.2, features A-02, A-08, A-10.

## Tasks

1. **Catalog domain** — Category → Service → Sub-service (PRD §4). Service has
   `service_model` (on-demand, duration hire, listing, partner referral), BN/EN names,
   icon key, `required_level`, `search_radius_m`, `women_providers_only`,
   `requires_level_2`. Sub-service has unit (job, unit, hour, day) and a **versioned
   price**: every change inserts a new price row; old rows are immutable (PRD §4).
2. **Catalog use cases** — admin CRUD (A-02), publish/unpublish, customer browse, search
   (Postgres full-text across BN and EN names + trigram for typos), `GetPriceSnapshot`
   contract returning the current price version ID and amount. Read cache in Redis keyed
   by catalog version.
3. **Seed** — load `backend/seed/catalog.yaml` via `./pao seed` (idempotent).
4. **Media** — `CreateUploadURL(purpose, contentType, size)` with per-purpose rules
   (documents: JPEG/PNG/PDF ≤ 5 MB, private bucket; avatars: JPEG/PNG ≤ 2 MB);
   `ConfirmUpload` checks the object exists and matches; `GetViewURL` (5-minute signed
   URL) with a permission check and an audit entry for verification documents (PRD §6.6).
   Server-side encryption enabled on the bucket.
5. **Audit** — `Record(actor, action, subject, before, after, reason)`; subscribers for
   status/permission/verification events; admin query API with filters (A-08).
   Entries cannot be edited (DB trigger + no update method in the repository).
6. **Settings** — typed settings with defaults from `04-decisions.md` (accept timeouts,
   radius default, rating threshold, cancellation rules, document retention);
   `GetSetting` contract; admin update writes an audit entry and invalidates cache.

## Tests

- Unit: price versioning (a booking snapshot keeps its price after a change), service
  model rules, upload validation table, settings validation.
- Integration: catalog repository and search (Bangla and English queries), cache
  invalidation on update, signed URL expiry, document view writes an audit row, audit
  UPDATE/DELETE rejected by the database.

## Definition of done

Seeded catalog is browsable through the API; an admin can change a price and old
snapshots stay intact. `./pao ci` green; PR merged.
