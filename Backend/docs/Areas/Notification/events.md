# Notification area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| — |

| Consumed event | Effect |
|---|---|
| every `booking.*` event of `BookingNotes` | inbox and push to the customer, the provider or both |
| `verification.ProviderLevelChanged`, `DocumentRejected`, `DocumentExpired`, `DocumentExpiring`, `Level2SessionScheduled` | inbox and push to the provider |
| `admin.ComplaintResolved` | inbox and push to the reporter |
| `identity.AccountDeleted` | erases the inbox and devices |
