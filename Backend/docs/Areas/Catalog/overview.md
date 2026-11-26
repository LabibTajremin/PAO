# Catalog area — overview

Categories, services, sub-services and price versions; the published catalog tree and its version.

Code: `src/PAO.Core/Areas/Catalog/`; contracts: `src/PAO.Lib/Areas/Catalog/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `ICatalogSharedService` | The only way other areas reach Catalog (`Services/Shared/`); implemented by `CatalogSharedService`, which turns `catalog.not_found` into the contract reasons. |
| `CatalogRules` | The catalog rules (names, icon, model, level 0 to 2, radius 500 to 50 000 m, units, prices from 0) and the published-only filter. |
| `CatalogTreeService` | The published tree from the Redis cache keyed by version; the admin tree from the database. |
| `CatalogChanges` | Runs a write in the command's transaction, bumps the version and publishes `CatalogChanged`. |
| `IconAddress` | Where stored catalog icons live in the public bucket (`catalog-icons/`) and their URLs; a category or service only takes an icon URL that points there (ADR-0039). |
| `IconFiles` | Checks an icon file, stores the cleaned file in the public bucket under a new name and publishes `IconAdded`. |
| `SvgSanitizer` | Keeps only the drawing elements and attributes of an SVG; no DTDs, scripts, handlers or external references. |
| `RasterIcon` | Reads PNG and WebP headers for size and alpha and enforces square, 96 px or more, transparent. |
| `IconFetcher` | Downloads an icon link once: https, no redirects, 5 seconds, within the size limit. |
| `PublicAddresses` | Connects icon downloads only to public addresses, resolving the host itself so a link cannot reach our network. |

Mapping: `CatalogMappingProfile` (`src/PAO.Lib/Areas/Catalog/`).

## Shared contract

| Method | Contract |
|---|---|
| `GetService` | Returns a service with its rules (radius, level, women-only), or throws `catalog.service_not_found`. |
| `GetPriceSnapshot` | Returns the current price version of a sub-service so a booking can copy it (PRD §4), or throws `catalog.sub_service_not_found`. |
| `GetPriceSnapshots` | Returns the current prices of many sub-services in one round of queries; unknown ids are absent. Booking prices a request's items with it. |
| `ListServices` | Returns every published service, for enrolment and admin filters. |
