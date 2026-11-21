# Rating area — data

Schema `rating`, created by the scripts in `database/changes/rating/` ([database index](../../Database/README.md)).
EF models: `src/PAO.EF/Rating/RatingRecords.cs`.

| Table | Created by |
|---|---|
| `rating.reviewable_bookings` | `database/changes/rating/0001_init.sql` |
| `rating.reviews` | `database/changes/rating/0001_init.sql` |
| `rating.aggregates` | `database/changes/rating/0001_init.sql` |
| `rating.outbox` | `database/changes/rating/0001_init.sql` |
| `rating.processed_events` | `database/changes/rating/0001_init.sql` |

| Repository | Role |
|---|---|
| `RatingRepository` | reviewable bookings, a review with its aggregate upsert and event in one transaction, batched aggregates, keyset review pages, erasure |
