# customer

Customer profiles and saved addresses with map pins; the launch-area check.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Layout

- `domain/` — profile and address rules, the Bangladesh bounding box, the launch-area
  polygon test (`area.ts`).
- `app/` — `CustomerProfiles` (profile, admin search), `SavedAddresses` (up to 10, default
  switching), `ServiceArea` (C35); reasons in `app/errors.ts`.
- `port/` — the repository and the peers (photos, accounts, launch area).
- `adapter/postgres/` — PostGIS repository; address writes hold the customer's row lock;
  `subscribers.ts` erases deleted accounts and keeps the admin list copies.
- `adapter/peers/` — media, identity and admin contracts, resolved on first use.
- `adapter/http/` — profile, addresses and service-area controllers with the error map.
- `adapter/inproc/` — the contract for other modules.

## Contract (`contract/customer-service.ts`, `CustomerService`, token `CUSTOMER_SERVICE`)

- `getCustomer`
- `getAddress`
- `isInServiceArea`
- `searchCustomers` (admin console list and record, ADR-0026)

## Events published

- `CustomerProfileSaved`

## Events consumed

- `identity.AccountDeleted (erase profile and addresses)`
- `identity.AccountStatusChanged`, `booking.BookingRequested` (admin list copies)

## Tables (schema `customer`)

- `customers`
- `addresses`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/customer/profile`
- `/v1/customer/addresses*`
- `/v1/customer/service-area`
- `/v1/admin/customers*` (served by admin through `searchCustomers`)

Migrations: `backend-nest/migrations/customer/`.
