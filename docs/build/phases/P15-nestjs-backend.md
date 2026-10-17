# P15 — NestJS backend

**Goal:** replace the Go backend with a NestJS backend that serves the same contract, passes
the same journeys and meets the same gates, then delete the Go code (ADR-0032).

**Read first:** ADR-0032; `02-architecture.md`; `01-conventions.md` §1–4 and §7;
`03-testing.md`; the Go module being ported (its README, contract, app and tests).

## Rules for this phase

- The Go backend stays untouched and runnable until task 7. It is the reference: when
  the Go code and this file disagree on behaviour, the Go code (and the PRD) wins.
- Port behaviour, not syntax: idiomatic NestJS and TypeScript, same names for use cases,
  errors, events, tables, Redis keys and env vars.
- Every Go test case has a TypeScript counterpart (unit or integration). Missing cases
  are a gap, not a simplification.

## Tasks

1. **Foundation** — `backend-nest/`: tooling (tsconfig strict, ESLint, Prettier, Jest
   projects, dependency-cruiser, coverage gate), platform layer (config, logging, clock,
   ids, db + migrator, redis keys/limiter/lock/idempotency/cache/denylist, auth crypto,
   RBAC cache, HTTP edge, event bus + outbox relay, scheduler, storage, health, metrics,
   i18n, test hooks), generated spec types and sqlc query functions, all eleven module
   contracts, composition roots, seed and perf-seed, Dockerfile, test kit.
2. **Identity, audit, media, catalog, notification** — ported with their tests.
3. **Customer, provider, verification** — ported with their tests.
4. **Booking, rating, admin** — ported with their tests; every spec operation served.
5. **Parity** — the Go black-box journeys and the app journeys pass against a stack built
   from `backend-nest/`; start-up smoke for the three entry points.
6. **Tooling switch** — `./pao` (lint, gen, test, cover, security, seed, perf), git hooks,
   CI workflows, `.env.example`, docs (`CLAUDE.md`, `00`–`03`, module READMEs) describe
   the NestJS backend; the e2e journeys are ported to TypeScript (`test/e2e/api`).
7. **Cut-over** — with everything above green, delete the Go backend, Go journeys and Go
   tooling; move `backend-nest/` to `backend/`; `./pao ci` green on a clean clone.

## Definition of done

`./pao ci` green with only the NestJS backend; journeys and perf thresholds pass; no Go
code or Go tooling left in the repository.
