# Merchant area — data

Schema `provider` (kept so existing databases carry over), created by `DB Changes/provider/` ([database index](../../Database/README.md)).
EF models: `PAO.EF/Merchant/MerchantRecords.cs`.

| Table | Created by |
|---|---|
| `provider.providers` | `DB Changes/provider/0001_init.sql` |
| `provider.provider_services` | `DB Changes/provider/0001_init.sql` |
| `provider.cancellations` | `DB Changes/provider/0002_quality.sql` |
| `provider.outbox` | `DB Changes/provider/0001_init.sql` |
| `provider.processed_events` | `DB Changes/provider/0001_init.sql` |

| Repository | Role |
|---|---|
| `MerchantRepository` | profile and services (batch-loaded), saves with their event in one transaction, candidates, admin search |
| `RedisPresence` | `presence:svc:{serviceId}` GEO sets, `presence:hb:{id}` (90 s), `presence:online`; positions exist only while online (PRD §11); online checks are batched |
