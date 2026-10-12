# ADR-0032: Rebuild the backend on NestJS

- Status: Accepted
- Date: 2026-10-11
- Source: owner decision (deployment cost); docs/build/phases/P15-nestjs-backend.md
- Supersedes: the Go library choices in ADR-0001, ADR-0006 and ADR-0008, and the Go
  column of `02-architecture.md` §3

## Context

The owner chose to run the backend on Node.js to lower deployment cost: one runtime
for the API, the worker and tooling, smaller hosting tiers and a larger hiring pool.
The Go backend is complete (P02–P09) and covered by unit, integration and end-to-end
tests. The replacement must keep the same HTTP contract (`api/openapi.yaml`), so the
Flutter apps keep working unchanged, and the same engineering bar: modular monolith,
hexagonal modules, deny-by-default RBAC from the spec, 100% coverage, strict linting.

## Decision

- **Framework.** NestJS 11 on Express, TypeScript in `strict` mode, Node.js 22 LTS.
  One image runs three entry points: `api`, `worker` and `migrate`.
- **Layout.** The modular monolith keeps its shape. Each module in
  `src/modules/<module>/` has `contract/` (public types and injection tokens),
  `domain/`, `app/`, `port/`, `adapter/{postgres,http,inproc,...}` and
  `<module>.module.ts`. A module may import only another module's `contract/` and
  `src/platform/**`; `domain/` imports only its own `domain/`. dependency-cruiser
  enforces this, as go-arch-lint did.
- **Wiring.** Every module is a Nest module that exports only its contract tokens and
  is marked `@Global()`, so modules depend on tokens, never on each other's classes.
  The composition roots (`app.module.ts`, `worker.module.ts`) import every module.
  A dependency cycle (identity reads provider levels from verification) is broken
  with a lazy contract resolved through `ModuleRef` on first use.
- **HTTP edge.** The spec stays the source of truth. Middleware matches each request
  to an OpenAPI operation (404/405 otherwise); guards then run authentication, the
  operation's `x-permission` (deny by default), and rate limits; interceptors run
  request validation (Ajv, JSON Schema 2020-12, against the bundled spec) and
  idempotency. Request and response types are generated from the spec with
  `openapi-typescript`. One exception filter writes the PRD §9.6 error envelope;
  each module's `adapter/http` maps its domain errors to API errors.
- **SQL.** The existing per-module `queries.sql` files and goose-format migrations are
  kept. `sqlc` generates typed query functions with the official
  `sqlc-gen-typescript` plugin (driver `pg`); generated files end in `.gen.ts` or live
  in `sqlc/` folders and are excluded from coverage and lint. A small migrator applies
  the same goose files and records them in the same version tables.
- **Jobs.** Only periodic jobs exist (booking timeout sweep, presence reaper, expiry,
  reminders, purges), so River is replaced by an in-process scheduler in the worker,
  guarded by a Postgres advisory lock so one worker runs each job at a time. The
  outbox relay keeps its at-least-once delivery.
- **Libraries.** `pg`, `ioredis`, `jose` (EdDSA JWT), `@node-rs/argon2` (argon2id),
  `otplib` (TOTP), `node:crypto` (AES-256-GCM), `@aws-sdk/client-s3` with
  `@aws-sdk/s3-request-presigner`, `google-auth-library` for FCM, `prom-client`,
  `pino`, `zod` (configuration), `ajv` + `ajv-formats`, `uuid` (v7).
- **Quality gates.** ESLint (typescript-eslint `strictTypeChecked`) with the size rules
  from `01-conventions.md` (250-line files, 40-line functions, complexity 10, depth 3,
  4 parameters), Prettier, dependency-cruiser, `tsc --noEmit`, `npm audit` for
  production dependencies, gitleaks. Jest (with `@swc/jest`) runs unit specs
  (`*.spec.ts`) and integration specs (`*.int-spec.ts`, real Postgres and Redis as in
  ADR-0008); their merged coverage must be 100% of statements, lines and functions of
  hand-written code — the same statement gate Go had. Excluded, as before: generated
  code and the three composition roots (`main.ts`, `worker.ts`, `migrate.ts`), which
  the e2e start-up smoke test covers.
- **Migration path.** The NestJS backend is built in `backend-nest/` beside the Go
  backend. It is done when its own unit and integration suites pass at 100% and the
  existing black-box journeys (`test/e2e/api`) and app journeys pass against it.
  Then the journeys are ported to TypeScript, the Go backend and Go journeys are
  deleted, and `backend-nest/` becomes `backend/`.

## Consequences

- The API contract, database schemas, Redis keys, environment variables, error codes
  and events are unchanged, so the apps, the e2e suite and stored data carry over.
- The Node image is larger than the distroless Go one, but runs on the same small
  instances and drops the Go toolchain from CI.
- `sqlc-gen-typescript` is young; if it blocks a query, that query may be written by
  hand in the module's `adapter/postgres` with parameters only (never string-built
  SQL) and covered by integration tests.
- Revisit if per-request CPU becomes the cost driver (argon2 and JSON-heavy paths are
  the hot spots) — Fastify and worker threads are the first levers.

## Cut-over

Done in P15: the journeys run in TypeScript (`test/e2e/api`), the Go backend, the Go
journeys and the Go tooling are deleted, and the NestJS backend lives in `backend/`.
Every `pao` gate, git hook and CI workflow now runs on it.
