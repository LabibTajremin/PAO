# Notification area — overview

Templates, the inbox, device tokens and delivery by push and SMS; subscribes to booking and verification events.

Code: `PAO.Core/Areas/Notification/`; contracts: `PAO.Lib/Areas/Notification/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `INotificationSharedService` | The only way other areas reach Notification (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `Send` | Renders a template in the recipient's language and delivers it on the requested channels; idempotent per (recipient, template, dedupe key). |
