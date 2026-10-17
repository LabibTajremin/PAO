# Architecture

PAO is a NestJS (TypeScript) **modular monolith** (ADR-0001, ADR-0032) with three Flutter clients. The detailed
engineering reference is [`docs/build/02-architecture.md`](build/02-architecture.md); this
page is the summary a new engineer reads first.

## Module map

| Module | Owns | Example contract methods |
|---|---|---|
| identity | accounts, OTP, sessions, JWT, roles | `GetAccount`, `HasRole` |
| customer | customer profile, saved addresses | `GetCustomer`, `GetAddress` |
| provider | provider profile, services offered, presence | `GetProvider`, `FindNearby`, `IsAvailable` |
| verification | documents, checks, levels, expiry, Level 2 | `GetLevel`, `CanReceiveBookings` |
| catalog | categories, services, sub-services, versioned prices | `GetPriceSnapshot`, `GetService` |
| booking | booking lifecycle, start code, extra items | `GetBooking`, `CountActiveJobs` |
| rating | reviews and aggregates | `GetProviderRating` |
| notification | push, SMS, in-app inbox | `Send` |
| media | uploads, signed URLs | `CreateUploadURL`, `GetViewURL` |
| admin | admin users, settings, complaints | `GetSetting` |
| audit | append-only audit log | `Record` |

## Boundary rules (PRD §9.3)

1. Each module exposes only `contract/` (service interface, DTOs, events).
2. A module imports other modules' `contract/` folders and `platform/` — nothing else.
   dependency-cruiser enforces this in `./pao lint` (`backend/.dependency-cruiser.cjs`).
3. Each module owns one Postgres schema; no cross-schema joins or foreign keys.
4. Bookings copy snapshots (price, service name, provider name) instead of reading live.
5. Side effects travel as domain events written through a per-module outbox.
6. No transaction spans two modules.
7. Contracts are implemented in-process today and can become network clients later.

Inside a module, dependencies point inwards: `adapter → app → domain`; use cases depend on
`port/` interfaces.

## Runtime

One stateless API process and one worker process (outbox relay + periodic jobs on an
in-process scheduler) from the same image; PostgreSQL 16 + PostGIS; Redis 7 for sessions, rate limits, locks and presence;
S3-compatible private storage with signed URLs; FCM, SMS and maps behind ports.

## Extracting a module into a service

PRD §10 asks that any module can leave the monolith without rewriting its callers. The
seams that make this possible already exist; extraction replaces in-process adapters
with network ones behind them. Booking is used as the example below; every module has
the same shape.

### The seams

| Seam | Where | Today | After extraction |
|---|---|---|---|
| Contract token | `modules/<m>/contract/<m>-service.ts` (`BOOKING_SERVICE` + `BookingService`) | bound to the in-process adapter in `<m>.module.ts` | bound to an HTTP or gRPC client in the monolith |
| In-process adapter | `modules/<m>/adapter/inproc/` (`BookingContract`) | calls the module's use cases directly | moves with the module and backs the new service's internal API |
| Peer ports | `modules/<m>/port/peers.ts` + `adapter/peers/` | `LazyContract` reads other modules' tokens | the service gets clients for the contracts it still needs |
| Events | `contract/events.ts`, written to schema `<m>.outbox` in the same transaction as the change | `OutboxRelay` delivers to the in-process `EventBus` | the relay publishes to a broker; subscribers consume from it |
| Idempotent consumers | `<m>.processed_events` | handlers skip events already seen | unchanged — at-least-once delivery is already assumed |
| Schema | `backend/migrations/<m>/`, one Postgres schema per module | one database | the schema moves to the service's own database |
| HTTP routes | `modules/<m>/adapter/http/` + `x-permission` in `api/openapi.yaml` | served by the API process | routed to the service by the gateway or load balancer |
| Jobs | worker hooks in `adapter/inproc/` (`jobs.every(...)`) | run in the shared worker under an advisory lock | run in the service's own worker |

Rules that keep this cheap are enforced today by dependency-cruiser and review: no
cross-schema joins or foreign keys, no transaction across modules, snapshots instead of
live reads (bookings copy prices and names), and contract DTOs that are plain
serialisable data.

### Step by step

1. **Freeze the contract.** Check that every method on the contract interface takes and
   returns plain data (no classes, no streams) and that each `DomainError` reason it can
   throw is listed in `contract/errors.ts`. These become the internal API and its error
   codes.
2. **Create the service.** Copy `backend/` to a new NestJS app containing the platform
   folder and only `modules/<m>/`; its `app.module.ts` imports that one module. Keep
   the module code unchanged.
3. **Expose the contract internally.** Add a controller in the service (for example
   `POST /internal/booking/getBooking`) that calls the in-process adapter and maps
   `DomainError` reasons to an error body. Authenticate it with service credentials
   (mTLS or a signed service token), never with user JWTs.
4. **Swap the binding in the monolith.** Add `modules/<m>/adapter/remote/` with a class
   implementing the contract interface over HTTP that rethrows the same `DomainError`
   reasons, and bind the token to it (`{ provide: BOOKING_SERVICE, useClass:
   RemoteBookingContract }`). Callers do not change. Delete the rest of the module from
   the monolith.
5. **Move the data.** Create the service's database, run the module's goose migrations
   there with the migrator, copy the schema with `pg_dump --schema=<m>` during a short
   write freeze (or logical replication for a zero-downtime move), then drop the schema
   from the monolith.
6. **Put a broker behind the outbox.** Implement the bus's `Dispatcher` with a broker
   publisher (for example Redis Streams, NATS or SQS/SNS) in both processes, keep
   `OutboxRelay` writing from each outbox, and subscribe consumers through the broker.
   Event names (`booking.BookingAccepted`) become topics; ordering per aggregate is kept
   by partitioning on `aggregateId`.
7. **Move routes and jobs.** Route the module's paths (`/v1/customer/bookings*`, …) to
   the service at the load balancer; the spec and its `x-permission` checks run in the
   service's HTTP edge exactly as in the monolith. Its periodic jobs move to the
   service's worker.
8. **Prove it.** Run the module's unit and integration specs in the new service, the
   contract spec against the remote adapter, and the black-box journeys in
   `test/e2e/api` against the split deployment. They need no change because the public
   API is the same.

Contracts implemented with `LazyContract` (resolved through `ModuleRef` on first use)
already tolerate their peer being missing at start-up, which is what a remote peer
looks like; keep timeouts and retries in the remote adapter, not in callers.
