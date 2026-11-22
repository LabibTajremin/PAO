# Admin area — data

Schema `admin`, created by the scripts in `database/changes/admin/` ([database index](../../Database/README.md)).
EF models: `src/PAO.EF/Admin/AdminRecords.cs`.

| Table | Created by |
|---|---|
| `admin.settings` | `database/changes/admin/0001_init.sql` |
| `admin.complaints` | `database/changes/admin/0001_init.sql` |
| `admin.complaint_comments` | `database/changes/admin/0001_init.sql` |
| `admin.stats_bookings_daily` | `database/changes/admin/0001_init.sql` |
| `admin.stats_providers` | `database/changes/admin/0001_init.sql` |
| `admin.outbox` | `database/changes/admin/0001_init.sql` |
| `admin.processed_events` | `database/changes/admin/0001_init.sql` |

| Repository | Role |
|---|---|
| `SettingsRepository` | list, get, update with `admin.SettingChanged` |
| `ArtworkRepository` | artwork slots: list, find, save with `admin.ArtworkChanged`, seed (keeps slots an admin replaced) |
| `ComplaintRepository` | complaints with ticket numbers and notes, the queue, locked updates with their events, counts |
| `DashboardRepository` | the dashboard counts and the read-model writes the subscribers make |

Redis: `cache:settings` (10 minutes), `cache:dashboard` (1 minute).
