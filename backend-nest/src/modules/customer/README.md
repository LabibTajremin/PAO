# customer

Customer profiles and saved addresses with map pins; the launch-area check.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

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
- `/v1/admin/customers*`

Migrations: `backend-nest/migrations/customer/`.
