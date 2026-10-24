# Verification area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| `verification.ProviderLevelChanged` |
| `verification.DocumentApproved` |
| `verification.DocumentRejected` |
| `verification.DocumentExpired` |
| `verification.DocumentExpiring` |
| `verification.Level2SessionScheduled` |
| `verification.Level2ResultRecorded` |
