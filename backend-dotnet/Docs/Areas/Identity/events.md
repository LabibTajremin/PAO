# Identity area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| `identity.AccountCreated` |
| `identity.RoleGranted` |
| `identity.AccountStatusChanged` |
| `identity.AccountDeleted` |
