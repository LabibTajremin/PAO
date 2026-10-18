# Media area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| — |

| Consumed event | Effect |
|---|---|
| `identity.AccountDeleted` | deletes the account's own files; verification documents wait for the retention purge |
