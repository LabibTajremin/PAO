# Catalog area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Browse` | `GetPublishedCatalog` | query | the cached published tree (C-03) |
| `Browse` | `SearchCatalog` | query | trigram search in both languages; hits under unpublished parents dropped (C08) |
| `Browse` | `GetPublishedService` | query | a published service with its published sub-services (C09) |
| `ManageCatalog` | `GetAdminCatalog` | query | everything, published or not (A03) |
| `ManageCatalog` | `SaveCategory` | command | create or update; the validator checks names and icon |
| `ManageCatalog` | `SaveService` | command | create or update in an existing category; the validator applies the service rules (D7) |
| `ManageCatalog` | `CreateSubService`, `UpdateSubService` | command | create with a first price (`initialPrice` required, reported as field `amount`); an update never changes the price |
| `Prices` | `ChangePrice` | command | inserts an immutable price version and publishes `PriceChanged` |
| `Prices` | `ListPriceHistory` | query | newest first |
| `Seed` | `SeedCatalog` | command | `migrate seed`; idempotent |

Every command bumps the catalog version and publishes `CatalogChanged` in its transaction.
