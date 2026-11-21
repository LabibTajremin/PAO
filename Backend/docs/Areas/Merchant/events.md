# Merchant area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event | When |
|---|---|
| `provider.EnrolmentStepSaved` | a profile step is saved |
| `provider.ProviderFlaggedForReview` | the first time a quality threshold is crossed |
| `provider.ProviderWentOffline` | going offline, forced, reaped or after a status, level or deletion event |

Consumed by `MerchantSubscriptions` (handler name = event name), each once per event:
`verification.ProviderLevelChanged`, `identity.AccountStatusChanged`, `identity.AccountDeleted`,
`rating.ReviewSubmitted`, `booking.BookingCompleted`, `booking.BookingCancelled`, `admin.ComplaintResolved`.
