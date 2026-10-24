# Billing area — data

Schema `billing`, created by the scripts in `DB Changes/billing/` ([database index](../../Database/README.md)).
EF models: `PAO.EF/Billing/BillingRecords.cs`.

| Table | Created by |
|---|---|
| `billing.ledger_entries` | `DB Changes/billing/0001_init.sql` — `kind` `commission` (with `booking_id`, unique per `(booking_id, kind)`) or `payment` (with a unique `submission_id`); amounts are never negative, the kind gives the sign |
| `billing.payment_submissions` | `DB Changes/billing/0001_init.sql` — `status` `pending`/`confirmed`/`rejected`, `reviewer_id`, `reason` (required when rejected), `created_at`, `reviewed_at` |
| `billing.outbox` | `DB Changes/billing/0001_init.sql` |
| `billing.processed_events` | `DB Changes/billing/0001_init.sql` |

Other scripts of ADR-0035:

| Script | Change |
|---|---|
| `DB Changes/booking/0002_payment_method.sql` | `booking.bookings.payment_method`, default and only value `cash_on_delivery`; shown as `paymentMethod` on booking views and receipts |
| `DB Changes/admin/0002_billing_settings.sql` | settings `billing.commission_rate_bp` = 1000 and `billing.due_block_amount` = 50000 |
| `DB Changes/identity/0003_billing_permission.sql` | permission `billing:manage` for `support_agent` and `super_admin` |
| `Seed/catalog.yaml` | the Catering and Monthly Bazar categories with services, sub-services and fixed prices |

| Repository | Role |
|---|---|
| `BillingRepository` | the due totals in one query, the idempotent commission insert, submissions, the pending-only review (`UPDATE … WHERE status = 'pending' RETURNING`), credits, keyset pages and the outbox |
