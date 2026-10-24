# P17 — .NET backend, cash on delivery and merchant dues

**Goal:** replace the NestJS backend with a .NET backend laid out and patterned as ADR-0034
directs, add cash on delivery, merchant dues and the two new categories (ADR-0035), then
delete the NestJS code.

**Read first:** ADR-0034, ADR-0035, `02-architecture.md`, `01-conventions.md`,
`03-testing.md`, `Backend/PAO.AI/` (once it exists), and the NestJS area being ported (its
README, contract, app and specs).

## Rules for this phase

- The NestJS backend stays untouched and runnable until task 8. It is the reference: when
  NestJS code and this file disagree on existing behaviour, NestJS (and the PRD) wins.
- Port behaviour, not syntax: idiomatic C#, same use-case names, errors, events, tables,
  Redis keys and env vars.
- Every NestJS spec has a C# counterpart (unit or integration). Missing cases are a gap.
- Owner rules from the handwritten notes are binding (ADR-0034 lists them): repository
  pattern, CQRS handlers in feature folders with Commands and Queries, separate request,
  view and db models, a hand-written mapper, FluentValidation, an authorisation attribute
  on every controller, no N+1 queries and no database calls in loops, config files per
  concern, logs by date folder, `Program.cs` that registers services through one method per concern and per area, and documentation in `Backend/Docs` covering 100% of areas, features, controllers, jobs, config and scripts, with XML docs on every public member.

## Tasks

1. **Foundation** — `backend-dotnet/`:
   - solution and projects as ADR-0034;
   - config files and typed options;
   - Serilog with date folders;
   - EF Core context, factory and conventions;
   - migrator for `DB Changes`;
   - mediator, mapper and validation pipeline;
   - auth (EdDSA JWT, refresh in Redis, TOTP, argon2id, AES-GCM);
   - role attributes and the permission filter;
   - OpenAPI operation matching and request validation;
   - error envelope, idempotency, rate limits;
   - Redis keys, locks and limiter;
   - outbox and event bus;
   - scheduler, storage, SMS, push, metrics, health;
   - test kit, architecture tests, size checks, coverage gate;
   - Dockerfile.
2. **Identity, Audit, Media, Catalog, Notification** — ported with their tests.
3. **Customer, Merchant, Verification** — ported with their tests.
4. **Booking, Rating, Admin** — ported with their tests; every spec operation is served.
5. **Billing (ADR-0035)** — spec additions, ledger, commission on completion, due limit on
   accept, payment submissions and admin review, notifications and audit; the Catering
   and Monthly Bazar catalog seed; tests.
6. **Apps (ADR-0035)** — partner due banner, ledger and pay screen; admin payment queue
   and settings; customer "Cash on delivery"; tests and journeys.
7. **Parity** — the black-box journeys and app journeys pass against the .NET stack; a
   start-up smoke test covers the three hosts; perf thresholds hold.
8. **Cut-over** — port the journeys to C# (`Backend/Test/PAO.E2ETests`) and the k6
   scripts to `Backend/Test/Load`. Then:
   - delete the NestJS backend and its tooling;
   - move `backend-dotnet/` to `Backend/` and `frontend/` to `Frontend/`, then apply the
     full layout in ADR-0034 ("Repository layout after cut-over"): `api/` → `Backend/Api`,
     `test/` split by owner, `docker/`, `ops/` and the security configs → `infra/`,
     `scripts/` → `tools/`, root docs → `docs/`;
   - switch `./pao`, hooks, CI workflows, `.env.example`, docs and the PRD;
   - get `./pao ci` green on a clean clone.

## Definition of done

`./pao ci` is green with only the .NET backend, with the journeys and perf thresholds
passing. The new billing behaviour is covered end to end. No NestJS code or tooling is
left in the repository.
