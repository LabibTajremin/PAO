# Database

`DB Changes/` holds goose-format SQL scripts, one folder and one Postgres schema per
module, the only schema source (ADR-0034); EF Core maps to it without migrations. The
migrator (`PAO.Migrator up`) applies pending scripts in `modules.json` order and records
versions in `goose_<module>` tables, exactly as the NestJS migrator did, so existing
databases carry over. See [migrations](migrations.md).

| Script | Purpose |
|---|---|
| `identity/0001_init.sql` | Identity: accounts, admin credentials, roles, permissions and screen permissions. |
| `identity/0002_seed_rbac.sql` | RBAC seed from docs/build/02-architecture.md §6 and docs/build/05-screens.md. |
| `identity/0003_billing_permission.sql` | `billing:manage` for support agents and super admins (ADR-0035 §4). |
| `customer/0001_init.sql` | Customer: profiles and saved addresses (C-01, C-02). |
| `customer/0002_admin.sql` | Copies kept current for the admin customer list (A-05, PRD §9.3 rule 4). |
| `provider/0001_init.sql` | Provider: enrolment profile, services offered and read-model copies used for search. |
| `provider/0002_quality.sql` | Provider cancellations after acceptance, counted over 30 days for the quality review |
| `verification/0001_init.sql` | Verification: items, documents, levels, Level 2 sessions and the NID block list. |
| `verification/0002_closures.sql` | Accounts closed by their owners: their verification records and documents stay for |
| `catalog/0001_init.sql` | Catalog: Category → Service → Sub-service with immutable price versions (PRD §4). |
| `booking/0001_init.sql` | Booking: lifecycle, snapshots, items, extras and the timeline (PRD §5). |
| `booking/0002_payment_method.sql` | `payment_method`, only `cash_on_delivery` in the first release (ADR-0035 §1). |
| `rating/0001_init.sql` | Rating: two-way reviews and incrementally updated aggregates (C-11, P-09). |
| `notification/0001_init.sql` | Notification: in-app inbox and device tokens (C-13, P-12). |
| `media/0001_init.sql` | Media: metadata for objects uploaded directly to private storage (PRD §6.6). |
| `admin/0001_init.sql` | Admin: platform settings, complaints and the dashboard read model. |
| `admin/0002_billing_settings.sql` | Settings `billing.commission_rate_bp` and `billing.due_block_amount` (ADR-0035). |
| `audit/0001_init.sql` | Audit: the append-only trail of decisions and status changes (PRD §6.4, A-08). |
| `billing/0001_init.sql` | Billing: the merchant ledger, payment submissions, outbox (ADR-0035). |
