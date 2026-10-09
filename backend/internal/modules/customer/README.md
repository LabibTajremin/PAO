# customer

Customer profiles and saved addresses with map pins; the launch-area check.

## Contract (`contract/service.go`, `CustomerService`)

- `GetCustomer`
- `GetAddress`
- `IsInServiceArea`
- `SearchCustomers` (admin console list and record, ADR-0026)

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

Migrations: `backend/migrations/customer/`.
