# backend/seed

Seed data loaded by `migrate seed` (`./pao seed`):

- `catalog.yaml` — the MVP categories, services, sub-services and prices (D2), plus the
  demo admins for dev and staging, whose password comes from `SEED_ADMIN_PASSWORD`.

Loading is idempotent: `key` values derive stable ids, so editing a price and reseeding
inserts a new price version instead of changing history.
