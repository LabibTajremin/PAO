# Admin area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event | Fields |
|---|---|
| `admin.ComplaintCreated` | `complaintId`, `ticketNumber`, `bookingId`, `reporterId`, `reporterRole`, `againstId` |
| `admin.ComplaintResolved` | the above with `verified`, `actorId` |
| `admin.SettingChanged` | `key`, `before`, `after`, `actorId` |

Consumed by `AdminStatsSubscriptions` (handler name = event name), each once per event:
`identity.AccountCreated`, `identity.AccountStatusChanged`, `identity.AccountDeleted`,
`verification.ProviderLevelChanged`, `booking.BookingRequested`, `booking.BookingCompleted`.
A payload missing a needed field fails, so the relay retries it.
