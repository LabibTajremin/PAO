# Audit area — overview

The append-only audit log; subscribes to every event that changes a person's status or money.

Code: `PAO.Core/Areas/Audit/`; contracts, filter, page and view models and the
`AuditMappingProfile`: `PAO.Lib/Areas/Audit/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IAuditSharedService` | The only way other areas reach Audit (`Services/Shared/`). |
| `AuditSharedService` | Its implementation over `AuditLog`. |
| `AuditLog` | Appends (fresh id, time defaulting to now, refusing entries without action or subject: `audit.entry_invalid`) and lists; also `AuditReasons`. |
| `EventEntries` | Maps each audited event to its entry. |
| `AuditSubscriptions` | The worker's `IEventSubscriptions`: records each audited event with its event id, in its own scope. |

## Shared contract

| Method | Contract |
|---|---|
| `Record` | Appends an entry; entries can never be edited or deleted (PRD §6.4). The entry's id is ignored. |
| `ListForSubject` | Returns the newest entries about one subject, e.g. a merchant's status history. |
