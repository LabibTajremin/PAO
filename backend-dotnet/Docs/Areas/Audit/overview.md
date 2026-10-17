# Audit area — overview

The append-only audit log; subscribes to every event that changes a person's status or money.

Code: `PAO.Core/Areas/Audit/`; contracts: `PAO.Lib/Areas/Audit/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IAuditSharedService` | The only way other areas reach Audit (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `Record` | Appends an entry; entries can never be edited or deleted (PRD §6.4). |
| `ListForSubject` | Returns the newest entries about one subject, e.g. a merchant's status history. |
