# Booking area — data

Schema `booking`, created by the scripts in `database/changes/booking/` ([database index](../../Database/README.md)).
EF models: `src/PAO.EF/Booking/BookingRecords.cs`.

| Table | Created by |
|---|---|
| `booking.bookings` | `database/changes/booking/0001_init.sql` |
| `booking.extras_proposals` | `database/changes/booking/0001_init.sql` |
| `booking.booking_items` | `database/changes/booking/0001_init.sql` |
| `booking.timeline` | `database/changes/booking/0001_init.sql` |
| `booking.outbox` | `database/changes/booking/0001_init.sql` |
| `booking.processed_events` | `database/changes/booking/0001_init.sql` |

| Repository | Role |
|---|---|
| `BookingRepository` | create (own transaction; the idempotency key and one-open-request-per-pair constraints), change under `FOR UPDATE` and the provider's advisory lock with its events, erasure |
| `BookingQueries` | one booking in four queries, party lists, the monitor, due requests, earnings per Dhaka day and jobs, merchant stats |
