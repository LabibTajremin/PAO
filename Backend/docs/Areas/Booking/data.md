# Booking area — data

Schema `booking`, created by the scripts in `database/changes/booking/` ([database index](../../Database/README.md)).
EF models: `src/PAO.EF/Booking/BookingRecords.cs` and `SubscriptionRecords.cs`.

| Table | Created by |
|---|---|
| `booking.bookings` | `database/changes/booking/0001_init.sql` |
| `booking.extras_proposals` | `database/changes/booking/0001_init.sql` |
| `booking.booking_items` | `database/changes/booking/0001_init.sql` |
| `booking.timeline` | `database/changes/booking/0001_init.sql` |
| `booking.subscriptions` | `database/changes/booking/0004_subscriptions.sql` |
| `booking.subscription_dates` | `database/changes/booking/0004_subscriptions.sql` |
| `booking.outbox` | `database/changes/booking/0001_init.sql` |
| `booking.processed_events` | `database/changes/booking/0001_init.sql` |

| Repository | Role |
|---|---|
| `BookingRepository` | create (own transaction; the idempotency key and one-open-request-per-pair constraints), change under `FOR UPDATE` and the provider's advisory lock with its events, erasure |
| `SubscriptionRepository` | subscriptions (ADR-0041): create (own transaction, idempotency key), one with its stored dates, lists without dates, a date range across subscriptions with their bookings' statuses in one query, change under `FOR UPDATE` with its events, erasure |
| `SubscriptionRows` | converts subscription rows to the stored model and back; lines as jsonb |
| `BookingQueries` | one booking in four queries, party lists, the monitor, due requests, earnings per Dhaka day and jobs, merchant stats |
