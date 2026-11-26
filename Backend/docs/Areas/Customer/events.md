# Customer area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| `customer.CustomerProfileSaved` |

Consumed by `CustomerSubscriptions`, each once per event through `processed_events`:

| Event | Handler name | Effect |
|---|---|---|
| `identity.AccountDeleted` | `erase_account` | erases the profile and, by cascade, the addresses |
| `identity.AccountStatusChanged` | the event name | copies the status for customers |
| `booking.BookingRequested` | the event name | counts the booking for the admin list |
