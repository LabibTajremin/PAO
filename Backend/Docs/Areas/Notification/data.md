# Notification area — data

Schema `notification`, created by the scripts in `DB Changes/notification/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `notification.notifications` | `DB Changes/notification/0001_init.sql` |
| `notification.device_tokens` | `DB Changes/notification/0001_init.sql` |
| `notification.recipients` | `DB Changes/notification/0001_init.sql` |
| `notification.processed_events` | `DB Changes/notification/0001_init.sql` |

## Repositories

| Repository | Role |
|---|---|
| `NotificationRepository` | Inbox (insert once per recipient and dedupe key, keyset pages, unread count, read state) and device tokens (upsert, newest ten, drop, erase). |

Db models: `PAO.EF/Notification/` (`NotificationRecord`, `DeviceTokenRecord`). `notification.recipients` is not used: languages are read from the profiles.
