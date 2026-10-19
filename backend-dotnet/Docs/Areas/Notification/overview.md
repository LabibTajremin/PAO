# Notification area — overview

Templates, the inbox, device tokens and delivery by push and SMS; subscribes to booking and verification events.

Code: `PAO.Core/Areas/Notification/`; contracts: `PAO.Lib/Areas/Notification/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `INotificationSharedService` | The only way other areas reach Notification (`Services/Shared/`); implemented by `NotificationSharedService`. Inbox and push are always used; SMS stays with Identity's one-time codes, as in NestJS. |
| `NotificationTemplates` | Every message in English and Bangla; any language but `en` reads as Bangla. |
| `NotificationSender` | Stores once per (recipient, dedupe key), then pushes to the newest ten devices; dead tokens are dropped, other push failures logged (FCM or the capture adapter, `PUSH_ADAPTER`). |
| `NotificationPeers` | Languages from the Customer and Merchant profiles (Bangla without one) and booking text, resolved on first use. |
| `NotificationEventNotes`, `BookingNotes`, `BillingNotes` | Who hears about each booking, verification, billing and complaint event, with dedupe keys `<event id>[:<template>]`; events for an unknown booking are logged and dropped. |
| `NotificationEventSubscriptions` | Subscribes the notes and erasure (`identity.AccountDeleted`) to the bus. |

Mapping: `NotificationMappingProfile`.

## Shared contract

| Method | Contract |
|---|---|
| `Send` | Renders a template in the recipient's language and delivers it on the requested channels; idempotent per (recipient, template, dedupe key). |
