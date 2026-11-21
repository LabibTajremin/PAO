# Notification area — data

Schema `notification`, created by the scripts in `database/changes/notification/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `notification.notifications` | `database/changes/notification/0001_init.sql` |
| `notification.device_tokens` | `database/changes/notification/0001_init.sql` |
| `notification.recipients` | `database/changes/notification/0001_init.sql` |
| `notification.processed_events` | `database/changes/notification/0001_init.sql` |

## Repositories

| Repository | Role |
|---|---|
| `NotificationRepository` | Inbox (insert once per recipient and dedupe key, keyset pages, unread count, read state) and device tokens (upsert, newest ten, drop, erase). |

Db models: `src/PAO.EF/Notification/` (`NotificationRecord`, `DeviceTokenRecord`). `notification.recipients` is not used: languages are read from the profiles.
