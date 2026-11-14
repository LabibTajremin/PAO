# Database

`DB Changes/` holds goose-format SQL scripts, one folder and one Postgres schema per
module, the only schema source (ADR-0034); EF Core maps to it without migrations. The
migrator (`PAO.Migrator up`) applies pending scripts in `modules.json` order and records
versions in `goose_<module>` tables, exactly as goose does, so existing
databases carry over.

| Page or file | Use it to |
|---|---|
| [schema](schema.md) | look up a table, column, key or index per module, why each index exists, and the queries to find a person, booking, ledger, … |
| [migrations](migrations.md) | add a script: format, versioning, how `migrate up` applies it |
| [`bundle/schema.sql`](../../DB%20Changes/bundle/schema.sql), [`bundle/seed.sql`](../../DB%20Changes/bundle/seed.sql) | set a database up by hand in one paste (below) |

## Which one to use

- **A deployed environment with the image:** `/app/migrate up`, then `/app/migrate seed`
  (`docs/guides/deployment.md` §3.5). This stays the normal path.
- **No place to run the image yet, or a quick look in Neon:** paste `bundle/schema.sql`,
  then `bundle/seed.sql`, into Neon's SQL editor (or `psql -v ON_ERROR_STOP=1 -f`). The
  result is the same database `migrate up` + `migrate seed` produce, version rows included,
  so switching to the image later is seamless: `migrate up` finds nothing pending.
- **Reading or querying:** [schema](schema.md).

## Single-file scripts (bundle)

`DB Changes/bundle/` holds two generated files; never edit them by hand.

- `schema.sql`: every migration in `modules.json` order. Each runs in its own `DO` block
  only when its version is missing from `goose_<module>`, then records it there, so the
  script is idempotent (empty, partly migrated or fully migrated database alike) and
  refuses out-of-order scripts as the migrator does. It holds the migrator's advisory lock
  while it runs. Scripts marked `NO TRANSACTION` cannot run in a `DO` block; the generator
  refuses them, so such a script must be applied with `migrate up`.
- `seed.sql`: the catalog `migrate seed` loads from `Seed/catalog.yaml` (categories incl.
  Catering and Monthly Bazar, services, sub-services, prices), the same ids, upserts and
  price rule, in one transaction; like `migrate seed` each run bumps the catalog version and
  writes a `catalog.CatalogChanged` event. The demo admins are not included; create the first
  admin with `/app/migrate create-admin`.

Regenerate both after changing a migration or the seed file, and commit them:

```sh
Backend/scripts/gen-db-bundle.sh      # or: ./pao gen; or: dotnet run --project Backend/PAO.Migrator -- bundle
```

`scripts/gen-db-bundle.sh --check` (run by `scripts/ci.sh spec` and `./pao gen --check`)
fails when they are stale, and the integration test `DatabaseBundleTests` applies both to
an empty database and compares schema, version rows and catalog with `migrate up` and
`migrate seed`.

## Scripts

| Script | Purpose |
|---|---|
| `identity/0001_init.sql` | Identity: accounts, admin credentials, roles, permissions and screen permissions. |
| `identity/0002_seed_rbac.sql` | RBAC seed from docs/build/02-architecture.md §6 and docs/build/05-screens.md. |
| `identity/0003_billing_permission.sql` | `billing:manage` for support agents and super admins (ADR-0035 §4). |
| `identity/0004_admin_email_index.sql` | `accounts_email_lower_idx`: admin sign-in by `lower(email)` without a full scan. |
| `customer/0001_init.sql` | Customer: profiles and saved addresses (C-01, C-02). |
| `customer/0002_admin.sql` | Copies kept current for the admin customer list (A-05, PRD §9.3 rule 4). |
| `provider/0001_init.sql` | Provider: enrolment profile, services offered and read-model copies used for search. |
| `provider/0002_quality.sql` | Provider cancellations after acceptance, counted over 30 days for the quality review |
| `verification/0001_init.sql` | Verification: items, documents, levels, Level 2 sessions and the NID block list. |
| `verification/0002_closures.sql` | Accounts closed by their owners: their verification records and documents stay for |
| `catalog/0001_init.sql` | Catalog: Category → Service → Sub-service with immutable price versions (PRD §4). |
| `catalog/0002_banners.sql` | Home banners managed in the admin panel, with one seeded demo banner (ADR-0037 §2). |
| `booking/0001_init.sql` | Booking: lifecycle, snapshots, items, extras and the timeline (PRD §5). |
| `booking/0002_payment_method.sql` | `payment_method`, only `cash_on_delivery` in the first release (ADR-0035 §1). |
| `booking/0003_lookup_indexes.sql` | Indexes for the expiry sweep, the admin monitor and proposals by booking ([schema](schema.md#index-review)). |
| `rating/0001_init.sql` | Rating: two-way reviews and incrementally updated aggregates (C-11, P-09). |
| `notification/0001_init.sql` | Notification: in-app inbox and device tokens (C-13, P-12). |
| `media/0001_init.sql` | Media: metadata for objects uploaded directly to private storage (PRD §6.6). |
| `admin/0001_init.sql` | Admin: platform settings, complaints and the dashboard read model. |
| `admin/0002_billing_settings.sql` | Settings `billing.commission_rate_bp` and `billing.due_block_amount` (ADR-0035). |
| `admin/0003_complaints_against_index.sql` | `complaints_against_all_idx`: every complaint against a person, for the admin person view. |
| `audit/0001_init.sql` | Audit: the append-only trail of decisions and status changes (PRD §6.4, A-08). |
| `billing/0001_init.sql` | Billing: the merchant ledger, payment submissions, outbox (ADR-0035). |
| `bundle/schema.sql` | Generated: every script above in one idempotent file (`migrate bundle`). |
| `bundle/seed.sql` | Generated: the `migrate seed` catalog in one idempotent file (`migrate bundle`). |
