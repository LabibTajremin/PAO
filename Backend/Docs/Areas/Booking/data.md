# Booking area — data

Schema `booking`, created by the scripts in `DB Changes/booking/` ([database index](../../Database/README.md)).
EF models: `PAO.EF/Booking/BookingRecords.cs`.

| Table | Created by |
|---|---|
| `booking.bookings` | `DB Changes/booking/0001_init.sql` |
| `booking.extras_proposals` | `DB Changes/booking/0001_init.sql` |
| `booking.booking_items` | `DB Changes/booking/0001_init.sql` |
| `booking.timeline` | `DB Changes/booking/0001_init.sql` |
| `booking.outbox` | `DB Changes/booking/0001_init.sql` |
| `booking.processed_events` | `DB Changes/booking/0001_init.sql` |

| Repository | Role |
|---|---|
| `BookingRepository` | create (own transaction; the idempotency key and one-open-request-per-pair constraints), change under `FOR UPDATE` and the provider's advisory lock with its events, erasure |
| `BookingQueries` | one booking in four queries, party lists, the monitor, due requests, earnings per Dhaka day and jobs, merchant stats |
