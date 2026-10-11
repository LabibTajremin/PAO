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

Migrations: `backend-nest/migrations/catalog/`.
