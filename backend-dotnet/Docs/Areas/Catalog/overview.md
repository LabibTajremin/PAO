# Catalog area — overview

Categories, services, sub-services and price versions; the published catalog tree and its version.

Code: `PAO.Core/Areas/Catalog/`; contracts: `PAO.Lib/Areas/Catalog/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `ICatalogSharedService` | The only way other areas reach Catalog (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetService` | Returns a service with its rules (radius, level, women-only), or throws `catalog.service_not_found`. |
| `GetPriceSnapshot` | Returns the current price version of a sub-service so a booking can copy it (PRD §4), or throws `catalog.sub_service_not_found`. |
| `ListServices` | Returns every published service, for enrolment and admin filters. |
