# P02 — Backend platform

**Goal:** shared infrastructure in `backend/internal/platform/` that every module uses.
No business rules here.

**Read first:** PRD §9.3 (rules 5–7), §9.6, §11; `02-architecture.md` §2–§4, §7, §9.

## Tasks

1. **config** — typed struct loaded from env, validated at start-up; fails fast with a
   list of every missing variable. Secrets never logged.
2. **logx + metrics** — `slog` JSON logger with request ID, user ID and module fields;
   Prometheus metrics (requests, errors, latency histograms) on `/metrics` (internal port).
3. **db** — pgx pool, `WithTx(ctx, fn)` helper scoped to one module, migration runner
   (goose) used by `./pao seed` and tests.
4. **redisx** — client factory, key builder with `pao:{env}:` prefix, sliding-window
   rate limiter, distributed lock (`SET NX PX` + token-checked release), idempotency store.
5. **httpx** — chi router, server with timeouts and graceful shutdown, the single error
   format (PRD §9.6) and error-code mapping helpers, request validation against the
   OpenAPI spec, JSON helpers, cursor pagination encoder.
6. **Middleware** — request ID, recovery (logs, returns 500 without stack), security
   headers, CORS (admin origin only), body-size limit, per-IP and per-user rate limits,
   authentication (JWT verify + denylist check), `rbac.Require(permission)`,
   idempotency for routes marked in the spec.
7. **auth** — JWT signer/verifier (EdDSA keys from env, `kid` rotation support),
   password hashing (argon2id), TOTP helpers, secure random token generator.
8. **rbac** — permission checker reading role → permissions from Redis with Postgres
   fallback and `rbac:version` invalidation.
9. **eventbus + outbox** — in-process bus interface (`Publish`, `Subscribe`), outbox
   writer used inside module transactions, relay worker (at-least-once, ordered per
   aggregate, retries with backoff, dead-letter after 10 attempts), idempotent handler
   helper (processed-event table).
10. **jobs** — River client wrapper, job registration per module, worker start/stop.
11. **storage** — S3 port: presigned PUT (content-type and size limits), presigned GET
    (5 min), delete; MinIO in dev. **clock**, **idgen** (UUIDv7) — injectable.
12. **health** — `/healthz` (liveness), `/readyz` (DB, Redis, storage reachable).

## Tests

- Unit: every middleware (allowed, denied, edge cases), error mapping, pagination
  encode/decode, config validation, rate limiter maths with a fake clock.
- Integration (testcontainers Postgres + Redis + MinIO): lock contention, idempotency
  replay returns the same response, outbox relay delivers exactly once to an idempotent
  handler under retry, readiness fails when Redis is down.

## Definition of done

`./pao ci` green with 100% coverage of `platform/`; PR merged.
