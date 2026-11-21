# Merchant area — data

Schema `provider` (kept so existing databases carry over), created by `database/changes/provider/` ([database index](../../Database/README.md)).
EF models: `src/PAO.EF/Merchant/MerchantRecords.cs`.

| Table | Created by |
|---|---|
| `provider.providers` | `database/changes/provider/0001_init.sql` |
| `provider.provider_services` | `database/changes/provider/0001_init.sql` |
| `provider.cancellations` | `database/changes/provider/0002_quality.sql` |
| `provider.outbox` | `database/changes/provider/0001_init.sql` |
| `provider.processed_events` | `database/changes/provider/0001_init.sql` |

| Repository | Role |
|---|---|
| `MerchantRepository` | profile and services (batch-loaded), saves with their event in one transaction, candidates, admin search |
| `RedisPresence` | `presence:svc:{serviceId}` GEO sets, `presence:hb:{id}` (90 s), `presence:online`; positions exist only while online (PRD §11); online checks are batched |
