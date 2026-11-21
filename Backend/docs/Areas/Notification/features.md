# Notification area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Inbox` | `ListNotifications` | query | newest first, cursor pages (E7), unread count |
| `Inbox` | `MarkNotificationRead`, `MarkAllNotificationsRead` | command | per recipient and app; another's notification is 404 |
| `Devices` | `RegisterDevice` | command | a token moves to whoever registered it last |
