# Audit area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)).

| Published event |
|---|
| — |

## Consumed events

`AuditSubscriptions` subscribes as handler `audit`. Each entry carries the event id
(`audit.entries.event_id` is unique), so a redelivered event adds nothing. A payload missing
its subject fails, and the relay retries it.

| Event | Action | Subject |
|---|---|---|
| `identity.AccountStatusChanged` | `account.status_changed` | `account` |
| `catalog.PriceChanged` | `catalog.price_changed` | `sub_service` |
| `admin.SettingChanged` | `settings.changed` | `setting` |
| `admin.ComplaintResolved` | `complaint.resolved` | `complaint` |
| `verification.DocumentApproved` | `verification.item_approved` | `provider` |
| `verification.DocumentRejected` | `verification.item_rejected` | `provider` |
| `verification.ProviderLevelChanged` | `verification.level_changed` | `provider` |
| `verification.Level2ResultRecorded` | `verification.level2_result` | `provider` |
| `verification.DocumentExpired` | `verification.item_expired` | `provider` |
