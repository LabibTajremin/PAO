# catalog

Categories, services, sub-services and immutable, versioned prices (PRD §4).

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/catalog-service.ts`, `CatalogService`, token `CATALOG_SERVICE`)

- `getService`
- `getPriceSnapshot`
- `listServices`

## Events published

- `CatalogChanged`
- `PriceChanged`

## Events consumed

None.

## Tables (schema `catalog`)

- `categories`
- `services`
- `sub_services`
- `price_versions`
- `catalog_version`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/customer/catalog*`
- `/v1/customer/services/{id}`
- `/v1/provider/catalog`
- `/v1/admin/catalog*`

## Seeding

`SeedCatalog` provides `CATALOG_SEEDER` for `migrate seed`: it loads `seed/catalog.yaml`
idempotently, with ids derived from the seed keys (UUIDv5, the same as the Go backend), and
adds a price version only when a seeded price changed. The test kit's `seedCatalog` uses it.

## Caching

The published tree is cached in Redis under `cache:catalog:v{version}` for 10 minutes.
Every edit bumps `catalog.catalog_version` in the same transaction, so a new version is
visible at once; a Redis failure only costs a database read.

Migrations: `backend/migrations/catalog/`.
