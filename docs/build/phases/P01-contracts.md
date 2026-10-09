# P01 — Contracts

**Goal:** every interface is written and reviewed before implementation: the REST API, each
module's service-to-service contract, domain events, database schemas and the RBAC seed.
Later phases implement these; changing them later requires updating this phase's
artefacts in the same PR.

**Read first:** PRD §4, §5, §6, §7, §8, §9.2–9.3, §9.6; `02-architecture.md` §4–§8;
`05-screens.md`.

## Tasks

1. **OpenAPI.** `api/openapi.yaml` (OpenAPI 3.1), split with `$ref` into
   `api/paths/*.yaml` and `api/schemas/*.yaml` so no file exceeds ~300 lines. Must include:
   - shared: `ErrorResponse`, `ErrorCode` enum, cursor pagination, `Money` (paisa),
     `Idempotency-Key` header, bearer auth, 401/403/404/409/422/429 responses;
   - `/v1/auth/*`: OTP request/verify, refresh, logout, admin login + TOTP verify,
     `GET /v1/me`, `GET /v1/me/permissions`, `DELETE /v1/me` (account deletion);
   - `/v1/customer/*`: profile, addresses, catalog browse/search, nearby providers,
     provider profile + reviews, bookings (create, list, get, cancel, extras decision,
     start code, receipt), reviews, reports, notifications, device token;
   - `/v1/provider/*`: profile, enrolment steps, documents (upload URL, submit), verification
     status, online/offline + heartbeat location, requests (accept/reject), job actions
     (on-the-way, arrived, start with code, extras, complete), jobs list, earnings
     summaries, reviews, rate customer, reports, notifications, device token;
   - `/v1/admin/*`: everything in PRD §7.3 MVP rows (A-01 to A-10).
   Every operation has `operationId`, a permission extension `x-permission`, request and
   response examples, and all error responses it can return.
2. **Generate.** `oapi-codegen` config producing Go types + strict server interfaces into
   `backend/internal/platform/httpx/api` (generated, excluded from coverage);
   `openapi-generator` (dart-dio) into `frontend/packages/pao_api`. Wire both into
   `./pao gen`.
3. **Module contracts.** For each of the 11 modules: `contract/service.go`,
   `contract/dto.go`, `contract/events.go` with doc comments, plus module `README.md`.
   Methods from PRD §9.2, extended as needed (e.g. `booking.CountActiveJobs`,
   `verification.CanReceiveBookings`, `catalog.GetPriceSnapshot`).
4. **Schemas.** `backend/migrations/<module>/0001_init.sql` (goose up/down) for every
   module: one Postgres schema each, no cross-schema foreign keys (PRD §9.3), PostGIS
   `geography(Point,4326)` + GiST indexes, `outbox` table per module,
   append-only trigger on `audit.entries`, `identity.roles`, `role_permissions`,
   `role_screens` with seed rows from `02-architecture.md` §6 and `05-screens.md`.
5. **Booking state machine spec.** `docs/booking-states.md`: states and transitions from
   PRD §5 (Requested, Accepted, OnTheWay, Arrived, InProgress, Completed, Rejected,
   TimedOut, Cancelled), who may trigger each, guards, and events emitted. This table is
   the test matrix for P07.
6. **Seed data spec.** `backend/seed/catalog.yaml`: the 5 MVP services with categories,
   sub-services, BN/EN names and prices; demo admin users per role (passwords from env).

## Tests

- `redocly lint api/openapi.yaml` clean; generated code compiles.
- Integration test: every migration applies up, then down, then up again on PostGIS.
- Integration test: RBAC seed — every `x-permission` in the spec exists in the seed, and
  every screen ID in `05-screens.md` is assigned to at least one role.

## Definition of done

Contracts compile, migrations round-trip, `./pao ci` green, PR merged.
