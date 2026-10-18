# Catalog area — overview

Categories, services, sub-services and price versions; the published catalog tree and its version.

Code: `PAO.Core/Areas/Catalog/`; contracts: `PAO.Lib/Areas/Catalog/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `ICatalogSharedService` | The only way other areas reach Catalog (`Services/Shared/`); implemented by `CatalogSharedService`, which turns `catalog.not_found` into the contract reasons. |
| `CatalogRules` | The catalog rules (names, icon, model, level 0 to 2, radius 500 to 50 000 m, units, prices from 0) and the published-only filter. |
| `CatalogTreeService` | The published tree from the Redis cache keyed by version; the admin tree from the database. |
| `CatalogChanges` | Runs a write in the command's transaction, bumps the version and publishes `CatalogChanged`. |

Mapping: `CatalogMappingProfile` (`PAO.Lib/Areas/Catalog/`).

## Shared contract

| Method | Contract |
|---|---|
| `GetService` | Returns a service with its rules (radius, level, women-only), or throws `catalog.service_not_found`. |
| `GetPriceSnapshot` | Returns the current price version of a sub-service so a booking can copy it (PRD §4), or throws `catalog.sub_service_not_found`. |
| `ListServices` | Returns every published service, for enrolment and admin filters. |
