# Admin area — data

Schema `admin`, created by the scripts in `DB Changes/admin/` ([database index](../../Database/README.md)).
EF models: `PAO.EF/Admin/AdminRecords.cs`.

| Table | Created by |
|---|---|
| `admin.settings` | `DB Changes/admin/0001_init.sql` |
| `admin.complaints` | `DB Changes/admin/0001_init.sql` |
| `admin.complaint_comments` | `DB Changes/admin/0001_init.sql` |
| `admin.stats_bookings_daily` | `DB Changes/admin/0001_init.sql` |
| `admin.stats_providers` | `DB Changes/admin/0001_init.sql` |
| `admin.outbox` | `DB Changes/admin/0001_init.sql` |
| `admin.processed_events` | `DB Changes/admin/0001_init.sql` |

| Repository | Role |
|---|---|
| `SettingsRepository` | list, get, update with `admin.SettingChanged` |
| `ComplaintRepository` | complaints with ticket numbers and notes, the queue, locked updates with their events, counts |
| `DashboardRepository` | the dashboard counts and the read-model writes the subscribers make |

Redis: `cache:settings` (10 minutes), `cache:dashboard` (1 minute).
