# Admin area — overview

Admin users, platform settings, complaints and the dashboard statistics.

Code: `PAO.Core/Areas/Admin/`; contracts: `PAO.Lib/Areas/Admin/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IAdminSharedService` | The only way other areas reach Admin (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetSettings` | Returns the typed platform settings (A-10), defaults filled in. |
| `CountVerifiedComplaints` | Returns verified complaints against a person; they feed the merchant quality review (PRD §6.4). |
