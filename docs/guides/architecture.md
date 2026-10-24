# Architecture

PAO is a .NET 10 (C#) **modular monolith** (ADR-0001, ADR-0034) with three Flutter clients. The detailed
engineering reference is [`docs/build/02-architecture.md`](../build/02-architecture.md) and
`Backend/Docs/`; this page is the summary a new engineer reads first.

## Module map

| Module | Owns | Example contract methods |
|---|---|---|
| identity | accounts, OTP, sessions, JWT, roles | `GetAccount`, `HasRole` |
| customer | customer profile, saved addresses | `GetCustomer`, `GetAddress` |
| provider (area `Merchant`) | provider profile, services offered, presence | `GetProvider`, `FindNearby`, `IsAvailable` |
| verification | documents, checks, levels, expiry, Level 2 | `GetLevel`, `CanReceiveBookings` |
| catalog | categories, services, sub-services, versioned prices | `GetPriceSnapshot`, `GetService` |
| booking | booking lifecycle, start code, extra items | `GetBooking`, `CountActiveJobs` |
| rating | reviews and aggregates | `GetProviderRating` |
| notification | push, SMS, in-app inbox | `Send` |
| media | uploads, signed URLs | `CreateUploadURL`, `GetViewURL` |
| admin | admin users, settings, complaints | `GetSetting` |
| audit | append-only audit log | `Record` |
| billing | merchant ledger, commission, payment submissions (ADR-0035) | `ChargeCommission` |

## Boundary rules (PRD §9.3)

1. Each module is an ASP.NET area (`Backend/PAO.Core/Areas/<Area>`) and exposes only its
   shared service (`Services/Shared/I<Area>SharedService`), DTOs and events (`PAO.Lib`).
2. An area uses other areas only through their shared services and the platform
   (`PAO.Infrastructure`) — nothing else. Architecture tests enforce this in `./pao lint`.
3. Each module owns one Postgres schema; no cross-schema joins or foreign keys.
4. Bookings copy snapshots (price, service name, provider name) instead of reading live.
5. Side effects travel as domain events written through a per-module outbox.
6. No transaction spans two modules.
7. Shared services are implemented in-process today and can become network clients later.

Inside an area, controllers only send commands and queries (`IMediator`); handlers in
`Features/` use the area's `Services/` and `Repositories/`.

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
| Shared service | `Areas/<A>/Services/Shared/I<A>SharedService` (`IBookingSharedService`) | registered in-process by `Add<A>Area` | registered as an HTTP or gRPC client in the monolith |
| In-process implementation | `Areas/<A>/Services/Shared/<A>SharedService` | calls the area's handlers and services directly | moves with the area and backs the new service's internal API |
| Peers | `Areas/<A>/Services/<A>Peers` | resolves other areas' shared services on first use | the service gets clients for the shared services it still needs |
| Events | `PAO.Lib` event types, written by `OutboxWriter` to schema `<m>.outbox` in the same transaction as the change | `OutboxRelay` (worker) delivers to the in-process `EventBus` | the relay publishes to a broker; subscribers consume from it |
| Idempotent consumers | `<m>.processed_events` | handlers skip events already seen | unchanged — at-least-once delivery is already assumed |
| Schema | `Backend/DB Changes/<m>/`, one Postgres schema per module | one database | the schema moves to the service's own database |
| HTTP routes | `Areas/<A>/Controllers/` + `x-permission` in `Backend/Api/openapi.yaml` | served by the API process | routed to the service by the gateway or load balancer |
| Jobs | scheduled jobs registered by the area (`Backend/Docs/Operations/jobs.md`) | run in the shared worker under an advisory lock | run in the service's own worker |

Rules that keep this cheap are enforced today by architecture tests and review: no
cross-schema joins or foreign keys, no transaction across modules, snapshots instead of
live reads (bookings copy prices and names), and contract DTOs that are plain
serialisable data.

### Step by step

1. **Freeze the contract.** Check that every method of the shared service takes and
   returns plain data (records, no streams) and that each error reason it can fail with
   is listed in the area's error reasons (`PAO.Lib`). These become the internal API and its
   error codes.
2. **Create the service.** A new ASP.NET host project with the platform
   (`PAO.Infrastructure`, `PAO.Lib`, `PAO.EF`) and only `Areas/<A>/`, registered through
   its `Add<A>Area`. Keep the area code unchanged.
3. **Expose the shared service internally.** Add a controller in the service (for example
   `POST /internal/booking/get-booking`) that calls the in-process implementation and maps
   error reasons to an error body. Authenticate it with service credentials (mTLS or a
   signed service token), never with user JWTs.
4. **Swap the registration in the monolith.** Add a remote implementation of
   `I<A>SharedService` over HTTP that fails with the same error reasons and register it
   instead of the in-process one. Callers do not change. Delete the rest of the area from
   the monolith.
5. **Move the data.** Create the service's database, run the module's goose migrations
   there with the migrator, copy the schema with `pg_dump --schema=<m>` during a short
   write freeze (or logical replication for a zero-downtime move), then drop the schema
   from the monolith.
6. **Put a broker behind the outbox.** Replace the in-process `EventBus` delivery with a broker
   publisher (for example Redis Streams, NATS or SQS/SNS) in both processes, keep
   `OutboxRelay` writing from each outbox, and subscribe consumers through the broker.
   Event names (`booking.BookingAccepted`) become topics; ordering per aggregate is kept
   by partitioning on `aggregateId`.
7. **Move routes and jobs.** Route the module's paths (`/v1/customer/bookings*`, …) to
   the service at the load balancer; the spec and its `x-permission` checks run in the
   service's HTTP edge exactly as in the monolith. Its periodic jobs move to the
   service's worker.
8. **Prove it.** Run the area's unit and integration tests in the new service, the
   shared-service tests against the remote implementation, and the black-box journeys in
   `Backend/Test/PAO.E2ETests` against the split deployment. They need no change because the public
   API is the same.

Peers resolve other areas' shared services on first use, so they already tolerate a peer
that is not ready at start-up, which is what a remote peer looks like; keep timeouts and
retries in the remote implementation, not in callers.
