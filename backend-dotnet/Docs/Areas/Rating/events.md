# Rating area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event | Fields |
|---|---|
| `rating.ReviewSubmitted` | `reviewId`, `bookingId`, `authorId`, `subjectId`, `subjectRole`, `stars`, `newAverage`, `newCount` |

Consumed by `RatingSubscriptions` (handler `rating`): `booking.BookingCompleted` (opens the
booking for review; a missing time reads as Go's zero time) and `identity.AccountDeleted`.
