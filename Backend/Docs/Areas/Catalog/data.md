# Catalog area — data

Schema `catalog`, created by the scripts in `DB Changes/catalog/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `catalog.categories` | `DB Changes/catalog/0001_init.sql` |
| `catalog.services` | `DB Changes/catalog/0001_init.sql` |
| `catalog.sub_services` | `DB Changes/catalog/0001_init.sql` |
| `catalog.price_versions` | `DB Changes/catalog/0001_init.sql` |
| `catalog.catalog_version` | `DB Changes/catalog/0001_init.sql` |
| `catalog.outbox` | `DB Changes/catalog/0001_init.sql` |
| `catalog.processed_events` | `DB Changes/catalog/0001_init.sql` |

## Repositories

| Repository | Role |
|---|---|
| `CatalogRepository` | Reads: the whole tree in three queries assembled in memory (no N+1), a service with its sub-services, a sub-service with its current price, price history, trigram search, the catalog version. |
| `CatalogWriteRepository` | Writes on the command's transaction: upserts of categories, services and sub-services (idempotent reseeding), immutable price versions, the version bump and outbox events. |

Db models: `PAO.EF/Catalog/` (`CategoryRecord`, `ServiceRecord`, `SubServiceRecord`, `PriceVersionRecord`, `CatalogVersionRecord`).

## Cache

The published tree is cached in Redis under `cache:catalog:v{version}` for 10 minutes. Every
edit bumps `catalog.catalog_version` in the same transaction, so a new version is visible at
once; a Redis failure only costs a database read.

## Seeding

`migrate seed` loads `Seed/catalog.yaml` (see [operations](../../Operations/README.md)) through
the `SeedCatalog` command: ids derive from the seed keys (UUIDv5, `SeedIds`), every item is
published in file order, and a price version is added only when a seeded price changed.
