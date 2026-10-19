# Rating area — data

Schema `rating`, created by the scripts in `DB Changes/rating/` ([database index](../../Database/README.md)).
EF models: `PAO.EF/Rating/RatingRecords.cs`.

| Table | Created by |
|---|---|
| `rating.reviewable_bookings` | `DB Changes/rating/0001_init.sql` |
| `rating.reviews` | `DB Changes/rating/0001_init.sql` |
| `rating.aggregates` | `DB Changes/rating/0001_init.sql` |
| `rating.outbox` | `DB Changes/rating/0001_init.sql` |
| `rating.processed_events` | `DB Changes/rating/0001_init.sql` |

| Repository | Role |
|---|---|
| `RatingRepository` | reviewable bookings, a review with its aggregate upsert and event in one transaction, batched aggregates, keyset review pages, erasure |
