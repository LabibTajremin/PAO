# Audit area — data

Schema `audit`, created by the scripts in `DB Changes/audit/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `audit.entries` | `DB Changes/audit/0001_init.sql` |
| `audit.processed_events` | `DB Changes/audit/0001_init.sql` |

EF model: `PAO.EF/Audit/AuditModels.cs` (`Entry`).

| Repository | Store |
|---|---|
| `AuditRepository` | `IAuditRepository` and its EF implementation: append with `ON CONFLICT (event_id) DO NOTHING`, filtered pages ordered by (at, id) descending. No update or delete; the table's triggers reject them. |
