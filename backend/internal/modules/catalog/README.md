# catalog

Categories, services, sub-services and immutable, versioned prices (PRD §4).

## Contract (`contract/service.go`, `CatalogService`)

- `GetService`
- `GetPriceSnapshot`
- `ListServices`

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

Migrations: `backend/migrations/catalog/`.
